const WI2_DESTINATION_PATTERN = /^[A-Z0-9._%+-]+@forguest\.wi2\.ne\.jp$/i;
const GUEST_CODE_PATTERN =
  /(?:ゲストコード|guest\s*code)\s*(?:は|is|[:：])?\s*([A-Z0-9]{8})\b/i;

export function isAllowedWi2Destination(value: string): boolean {
  return WI2_DESTINATION_PATTERN.test(value.trim());
}

export function extractGuestCode(source: string): string | null {
  const normalized = decodeBasicHtmlEntities(source)
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ")
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  const labeledCode = normalized.match(GUEST_CODE_PATTERN);

  return labeledCode?.[1] ?? null;
}

function decodeBasicHtmlEntities(value: string): string {
  return value
    .replace(/&nbsp;|&#160;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;/gi, "'");
}
