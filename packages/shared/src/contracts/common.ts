import { z } from 'zod';

/** Building blocks shared by Edge Function request/response schemas. */
export const idSchema = z.uuid();

/** A calendar day in the party's time zone, e.g. "2026-11-12". */
export const daySchema = z.iso.date();
