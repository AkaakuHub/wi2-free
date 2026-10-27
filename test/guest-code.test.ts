import { describe, expect, it } from "vitest";

import { extractGuestCode, isAllowedWi2Destination } from "../src/guest-code";
import { createGasRequestBody, parseGasResponse, parseGasResponseText } from "../src/gas-request";

describe("isAllowedWi2Destination", () => {
  it("accepts Wi2 guest-code addresses", () => {
    expect(isAllowedWi2Destination("guestsrv-J@forguest.wi2.ne.jp")).toBe(true);
    expect(isAllowedWi2Destination("shop_123@forguest.wi2.ne.jp")).toBe(true);
  });

  it("rejects other domains", () => {
    expect(isAllowedWi2Destination("user@example.com")).toBe(false);
    expect(isAllowedWi2Destination("x@forguest.wi2.ne.jp.example.com")).toBe(false);
  });
});

describe("extractGuestCode", () => {
  it("extracts an eight-character code from plain text", () => {
    expect(extractGuestCode("ゲストコード　： AAAy9jxj")).toBe("AAAy9jxj");
  });

  it("extracts a code from HTML", () => {
    expect(extractGuestCode("<p>ゲストコード：<strong>AAAa1b2c</strong></p>")).toBe("AAAa1b2c");
  });

  it("returns null when no code exists", () => {
    expect(extractGuestCode("No code here")).toBeNull();
  });
});

describe("createGasRequestBody", () => {
  it("creates a deterministic HMAC request", async () => {
    await expect(
      createGasRequestBody("guestsrv-J@forguest.wi2.ne.jp", "shared-secret", 1_700_000_000_000),
    ).resolves.toEqual({
      signature: "32f5eeb0d3ca73be8f1f2c8f67d1c6031ebcd9fb061f60b489e24e882728df00",
      timestamp: 1_700_000_000_000,
      to: "guestsrv-J@forguest.wi2.ne.jp",
    });
  });
});

describe("parseGasResponse", () => {
  it("accepts a guest code", () => {
    expect(parseGasResponse({ code: "AAAy9jxj" })).toEqual({ code: "AAAy9jxj" });
  });

  it("accepts an expected error", () => {
    expect(parseGasResponse({ error: "timeout" })).toEqual({ error: "timeout" });
  });

  it("rejects malformed responses", () => {
    expect(parseGasResponse({ code: "not-a-code" })).toBeNull();
  });

  it("parses a JSON response with surrounding whitespace", () => {
    expect(parseGasResponseText("\n {\"code\":\"AAAy9jxj\"} \n")).toEqual({
      code: "AAAy9jxj",
    });
  });
});
