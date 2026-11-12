// Regenerates packages/shared/src/db.types.ts from the local Supabase database.
// Requires a running local stack (`pnpm db:start`); CI runs this and fails if the file changes.
import { spawnSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { format, resolveConfig } from 'prettier';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const target = join(root, 'packages/shared/src/db.types.ts');

const require = createRequire(import.meta.url);
const cliPackage = require.resolve('supabase/package.json');
const cliBin = join(dirname(cliPackage), require(cliPackage).bin.supabase);

const result = spawnSync(
  process.execPath,
  [cliBin, 'gen', 'types', '--lang', 'typescript', '--schema', 'public'],
  { cwd: root, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 },
);
if (result.status !== 0) {
  process.stderr.write(result.stderr || result.stdout);
  console.error('Type generation failed. Is the local Supabase stack running (`pnpm db:start`)?');
  process.exit(result.status ?? 1);
}

const header = '// GENERATED FILE: do not edit by hand. Run `pnpm gen:types` to regenerate.\n';
const source = await format(header + result.stdout, {
  ...(await resolveConfig(target)),
  filepath: target,
});
writeFileSync(target, source);
console.log(`Wrote ${target}`);
