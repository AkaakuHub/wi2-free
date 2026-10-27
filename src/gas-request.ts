export interface GasRequestBody {
  signature: string;
  timestamp: number;
  to: string;
}

export type GasResponse = { code: string } | { error: string } | null;

export async function createGasRequestBody(
  to: string,
  secret: string,
  timestamp: number,
): Promise<GasRequestBody> {
  const message = `${timestamp}:${to}`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));

  return {
    signature: toHex(signature),
    timestamp,
    to,
  };
}

export function parseGasResponse(value: unknown): GasResponse {
  if (!isRecord(value)) {
    return null;
  }

  if (typeof value.code === "string" && /^[A-Z0-9]{8}$/i.test(value.code)) {
    return { code: value.code };
  }

  if (typeof value.error === "string") {
    return { error: value.error };
  }

  return null;
}

export function parseGasResponseText(value: string): GasResponse {
  try {
    return parseGasResponse(JSON.parse(value.trim()) as unknown);
  } catch {
    return null;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function toHex(value: ArrayBuffer): string {
  return [...new Uint8Array(value)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}
