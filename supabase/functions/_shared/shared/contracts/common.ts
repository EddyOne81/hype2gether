// GENERATED FILE: do not edit by hand.
// Mirrored from packages/shared/src/contracts/common.ts by `pnpm build:functions`. Edit the package, not this copy.

import { z } from 'zod';

/** Building blocks shared by Edge Function request/response schemas. */
export const idSchema = z.uuid();

/** A calendar day in the party's time zone, e.g. "2026-11-12". */
export const daySchema = z.iso.date();
