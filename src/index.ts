import type { Env } from "./env";
import { createGasRequestBody, parseGasResponseText } from "./gas-request";
import { isAllowedWi2Destination } from "./guest-code";
import { codeResponse, jsonError } from "./http";

export default {
  async fetch(request, env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/health" && request.method === "GET") {
      return Response.json(
        { ok: true, service: "wi2-free" },
        { headers: { "cache-control": "no-store" } },
      );
    }

    if (url.pathname === "/code") {
      return handleCodeRequest(request, env);
    }

    return jsonError("not_found", 404);
  },
} satisfies ExportedHandler<Env>;

async function handleCodeRequest(request: Request, env: Env): Promise<Response> {
  if (request.method !== "POST") {
    return jsonError("method_not_allowed", 405, { Allow: "POST" });
  }

  if (!env.API_TOKEN || request.headers.get("authorization") !== `Bearer ${env.API_TOKEN}`) {
    return jsonError("unauthorized", 401);
  }

  const bodyText = await request.text();
  let destination = env.DEFAULT_WI2_TO;

  if (bodyText.trim()) {
    try {
      const body = JSON.parse(bodyText) as { to?: unknown };
      if (body.to !== undefined) {
        if (typeof body.to !== "string") {
          return jsonError("invalid_destination", 400);
        }
        destination = body.to.trim();
      }
    } catch {
      return jsonError("invalid_json", 400);
    }
  }

  if (!isAllowedWi2Destination(destination)) {
    return jsonError("invalid_destination", 400);
  }

  const body = await createGasRequestBody(destination, env.GAS_SHARED_SECRET, Date.now());
  let response: Response;
  try {
    response = await requestGas(env.GAS_WEB_APP_URL, body);
  } catch (error) {
    console.error("GAS request failed", error);
    return jsonError("email_send_failed", 502);
  }

  if (!response.ok) {
    console.error("GAS request returned an error", response.status);
    return jsonError("email_send_failed", 502);
  }

  const responseText = await response.text();
  const result = parseGasResponseText(responseText);
  if (result && "code" in result) {
    return codeResponse(result.code);
  }

  const isTimeout = result !== null && "error" in result && result.error === "timeout";
  const isUnauthorized = result !== null && "error" in result && result.error === "unauthorized";
  if (isTimeout) {
    return jsonError("timeout", 504);
  }
  if (isUnauthorized) {
    return jsonError("gas_unauthorized", 502);
  }
  return jsonError("email_send_failed", 502);
}

async function requestGas(url: string, body: Awaited<ReturnType<typeof createGasRequestBody>>): Promise<Response> {
  const initialResponse = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
    redirect: "manual",
  });
  const location = initialResponse.headers.get("location");

  if (!location || initialResponse.status < 300 || initialResponse.status >= 400) {
    return initialResponse;
  }

  return fetch(new URL(location, url));
}
