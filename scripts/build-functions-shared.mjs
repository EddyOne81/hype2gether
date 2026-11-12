// Mirrors the shared packages into supabase/functions/_shared/ so Edge Functions can import
// them.
//
// Why a copy exists at all: the Edge Runtime only ever sees the `supabase/` directory, both
// in `supabase functions serve` and when a function is deployed. A function cannot reach
// `packages/` by relative path, by import map or by symlink. Supabase's own convention for
// code shared between functions is `supabase/functions/_shared/`, so that is where the
// packages are mirrored to.
//
// The copy is generated, never edited, and CI fails if it is stale — the same contract as
// packages/shared/src/db.types.ts. packages/scoring stays the only home of the rules.
//
// The one transformation applied is adding explicit `.ts` extensions to relative specifiers:
// Metro and Vitest resolve `./activity`, Deno does not.
import { mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const target = join(root, 'supabase/functions/_shared');

/** Packages to mirror, in the order they are listed in the import map. */
const packages = [
  { name: 'scoring', from: 'packages/scoring/src' },
  { name: 'shared', from: 'packages/shared/src' },
];

const header = (source) =>
  `// GENERATED FILE: do not edit by hand.\n` +
  `// Mirrored from ${source} by \`pnpm build:functions\`. Edit the package, not this copy.\n`;

const ALREADY_HAS_EXTENSION = /\.(ts|tsx|js|mjs|json)$/;

function isDirectory(path) {
  try {
    return statSync(path).isDirectory();
  } catch {
    return false;
  }
}

/**
 * Deno resolves ES module specifiers literally, so relative imports need their extension.
 * The target is looked up on disk rather than guessed, because `./contracts` may be a file
 * or a directory with an index, and the two resolve differently.
 */
function addExplicitExtensions(source, fromDirectory) {
  const withExtension = (match, keyword, quote, specifier) => {
    if (ALREADY_HAS_EXTENSION.test(specifier)) return match;
    const resolved = isDirectory(join(fromDirectory, specifier))
      ? `${specifier}/index.ts`
      : `${specifier}.ts`;
    return `${keyword}${quote}${resolved}${quote}`;
  };
  return source
    .replace(/(\bfrom\s+)(['"])(\.{1,2}\/[^'"]*)\2/g, withExtension)
    .replace(/(\bimport\s+)(['"])(\.{1,2}\/[^'"]*)\2/g, withExtension);
}

function sourceFiles(directory) {
  const found = [];
  for (const entry of readdirSync(directory)) {
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) {
      found.push(...sourceFiles(path));
    } else if (entry.endsWith('.ts') && !entry.endsWith('.test.ts')) {
      found.push(path);
    }
  }
  return found;
}

rmSync(target, { recursive: true, force: true });

let written = 0;
for (const { name, from } of packages) {
  const source = join(root, from);
  for (const file of sourceFiles(source)) {
    const destination = join(target, name, relative(source, file));
    mkdirSync(dirname(destination), { recursive: true });
    const original = readFileSync(file, 'utf8');
    const posixSource = relative(root, file).split('\\').join('/');
    writeFileSync(
      destination,
      `${header(posixSource)}\n${addExplicitExtensions(original, dirname(file))}`,
    );
    written += 1;
  }
}

console.log(`Mirrored ${written} files into ${relative(root, target).split('\\').join('/')}`);
