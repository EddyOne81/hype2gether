// Reports the rule version this deployment scores under.
//
// Small on purpose, but not a throwaway: the app compares it with the version stored on a
// round before showing a preview, and it is the canary that proves an Edge Function can
// reach the shared packages at all (see docs/adr/0010).
import { RULE_VERSION } from '@hype2gether/scoring';
import { BRAND_NAME } from '@hype2gether/shared';

Deno.serve(() =>
  Response.json(
    { app: BRAND_NAME, ruleVersion: RULE_VERSION },
    { headers: { 'cache-control': 'no-store' } },
  ),
);
