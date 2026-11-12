// Type-checks and lints the Edge Functions with Deno, the runtime that actually runs them.
//
// Nothing else covers this code: ESLint ignores `supabase/`, and `pnpm typecheck` walks the
// workspace packages, which `supabase/functions/` is not part of. Deno is also the only tool
// that resolves the import map, so it is what catches a mirror whose relative specifiers do
// not resolve — the failure mode that otherwise only shows up as a boot error in production.
import { spawnSync } from 'node:child_process';
import { readdirSync, existsSync } from 'node:fs';
import { dirname, join, posix, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const functionsDir = join(root, 'supabase/functions');
const config = 'supabase/functions/deno.json';

const entryPoints = readdirSync(functionsDir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory() && !entry.name.startsWith('_'))
  .map((entry) => join(functionsDir, entry.name, 'index.ts'))
  .filter((path) => existsSync(path))
  .map((path) => relative(root, path).split('\\').join(posix.sep));

if (entryPoints.length === 0) {
  console.log('No Edge Functions to check.');
  process.exit(0);
}

// A shell is needed so Windows resolves `deno.exe`, which also means a missing binary comes
// back as a shell error rather than ENOENT. Probe for it first so the message is readable.
const probe = spawnSync('deno', ['--version'], { shell: true, encoding: 'utf8' });
if (probe.status !== 0) {
  console.error(
    'Deno is not installed. It is only needed to check the Edge Functions, and CI always runs\n' +
      'this check, so committing without it is fine. To run it locally, install Deno from\n' +
      'https://docs.deno.com/runtime/getting_started/installation/',
  );
  process.exit(1);
}

function run(args) {
  return spawnSync('deno', args, { cwd: root, stdio: 'inherit', shell: true }).status ?? 1;
}

const checked = run(['check', '--config', config, ...entryPoints]);
const linted = run(['lint', '--config', config, 'supabase/functions']);

process.exit(checked || linted);
