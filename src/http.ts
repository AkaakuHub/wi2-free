const JSON_HEADERS = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
} as const;

export function codeResponse(code: string): Response {
  return new Response(code, {
    status: 200,
    headers: {
      "content-type": "text/plain; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

export function jsonError(error: string, status: number, extraHeaders?: HeadersInit): Response {
  return Response.json(
    { error },
    {
      status,
      headers: {
        ...JSON_HEADERS,
        ...Object.fromEntries(new Headers(extraHeaders).entries()),
      },
    },
  );
}

export async function readJson<T>(request: Request): Promise<T | null> {
  try {
    return (await request.json()) as T;
  } catch {
    return null;
  }
}

export function parseTimeout(value: string): number {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) {
    return 60_000;
  }
  return Math.min(Math.max(parsed, 5_000), 120_000);
}

export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
