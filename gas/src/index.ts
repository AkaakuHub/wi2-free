const REQUEST_MAX_AGE_MS = 120_000;
const REPLY_TIMEOUT_MS = 60_000;
const SEARCH_INTERVAL_MS = 2_000;
const WI2_DESTINATION_PATTERN = /^[A-Z0-9._%+-]+@forguest\.wi2\.ne\.jp$/i;
const GUEST_CODE_PATTERN =
  /(?:ゲストコード|guest\s*code)\s*(?:は|is|[:：])?\s*([A-Z0-9]{8})\b/i;

interface RequestBody {
  signature: string;
  timestamp: number;
  to: string;
}

function authorize(): void {
  MailApp.getRemainingDailyQuota();
  GmailApp.search("from:cs-info@wi2.co.jp newer_than:1d", 0, 1);
}

function doPost(event: GoogleAppsScript.Events.DoPost): GoogleAppsScript.Content.TextOutput {
  const request = parseRequest(event.postData.contents);
  if (!request || !isRequestAuthorized(request)) {
    return jsonResponse({ error: "unauthorized" });
  }

  const lock = LockService.getScriptLock();
  if (!lock.tryLock(5_000)) {
    return jsonResponse({ error: "busy" });
  }

  try {
    const sentAt = Date.now();

    MailApp.sendEmail({
      to: request.to,
      subject: "",
      body: "",
    });

    const code = waitForGuestCode(sentAt);
    return code ? jsonResponse({ code }) : jsonResponse({ error: "timeout" });
  } catch (error) {
    console.error(error);
    return jsonResponse({ error: "email_send_failed" });
  } finally {
    lock.releaseLock();
  }
}

function parseRequest(contents: string): RequestBody | null {
  let value: unknown;
  try {
    value = JSON.parse(contents) as unknown;
  } catch {
    return null;
  }

  if (
    !isRecord(value) ||
    typeof value.signature !== "string" ||
    typeof value.timestamp !== "number" ||
    typeof value.to !== "string" ||
    !Number.isSafeInteger(value.timestamp) ||
    !WI2_DESTINATION_PATTERN.test(value.to)
  ) {
    return null;
  }

  return { signature: value.signature, timestamp: value.timestamp, to: value.to };
}

function isRequestAuthorized(request: RequestBody): boolean {
  const secret = PropertiesService.getScriptProperties().getProperty("WI2_GAS_SHARED_SECRET");
  if (!secret || Math.abs(Date.now() - request.timestamp) > REQUEST_MAX_AGE_MS) {
    return false;
  }

  const expected = toHex(
    Utilities.computeHmacSha256Signature(`${request.timestamp}:${request.to}`, secret),
  );
  return signaturesMatch(expected, request.signature);
}

function waitForGuestCode(sentAt: number): string | null {
  const deadline = Date.now() + REPLY_TIMEOUT_MS;

  while (Date.now() < deadline) {
    const code = findGuestCode(sentAt);
    if (code) {
      return code;
    }
    Utilities.sleep(SEARCH_INTERVAL_MS);
  }

  return null;
}

function findGuestCode(sentAt: number): string | null {
  const threads = GmailApp.search("from:cs-info@wi2.co.jp newer_than:1d", 0, 10);
  for (const thread of threads) {
    for (const message of thread.getMessages()) {
      if (
        message.getDate().getTime() < sentAt - 5_000 ||
        !/@(?:[a-z0-9-]+\.)*wi2\.(?:co\.jp|ne\.jp)\b/i.test(message.getFrom())
      ) {
        continue;
      }

      const code = `${message.getSubject()}\n${message.getPlainBody()}`.match(GUEST_CODE_PATTERN);
      if (code) {
        return code[1];
      }
    }
  }

  return null;
}

function signaturesMatch(expected: string, actual: string): boolean {
  if (expected.length !== actual.length) {
    return false;
  }

  let difference = 0;
  for (let index = 0; index < expected.length; index += 1) {
    difference |= expected.charCodeAt(index) ^ actual.charCodeAt(index);
  }
  return difference === 0;
}

function toHex(bytes: number[]): string {
  return bytes.map((byte) => ((byte + 256) % 256).toString(16).padStart(2, "0")).join("");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function jsonResponse(value: Record<string, string>): GoogleAppsScript.Content.TextOutput {
  return ContentService.createTextOutput(JSON.stringify(value)).setMimeType(
    ContentService.MimeType.JSON,
  );
}
