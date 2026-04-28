import type { EEFeatures } from "./types";

let _ee: EEFeatures | null = null;
let _resolved = false;

// Package name constructed at runtime to prevent bundler static analysis.
// Turbopack/webpack cannot resolve dynamically constructed module names,
// so this avoids "Module not found" warnings when @botron/ee is absent.
const EE_PKG = ["@botron", "ee"].join("/");

/**
 * Load EE features from `@botron/ee`.
 * Server-only: EE contains Node.js modules (dns, crypto) that can't run in the browser.
 * On the client side, always returns empty object.
 */
export function getEE(): EEFeatures {
  if (!_resolved) {
    if (typeof window !== "undefined") {
      _ee = {};
    } else {
      try {
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        _ee = require(EE_PKG).default;
      } catch {
        _ee = {};
      }
    }
    _resolved = true;
  }
  return _ee ?? {};
}

/**
 * Returns true when EE is available.
 * Client-safe: uses NEXT_PUBLIC_BOTRON_EDITION env var on the browser,
 * actual package detection on the server.
 */
export function hasEE(): boolean {
  if (typeof window !== "undefined") {
    return process.env.NEXT_PUBLIC_BOTRON_EDITION === "ee";
  }
  return Object.keys(getEE()).length > 0;
}

/** Reset cached loader state (for testing). */
export function resetEELoader(): void {
  _ee = null;
  _resolved = false;
}
