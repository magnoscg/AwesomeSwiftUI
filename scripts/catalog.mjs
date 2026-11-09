#!/usr/bin/env node
// `generate` rewrites the files derived from the metadata. `check` changes
// nothing and fails if a component breaks a rule or a generated file is stale.
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { findStale, loadCatalog, renderOutputs } from './catalog-lib.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const command = process.argv[2];

if (command !== 'generate' && command !== 'check') {
  console.error('Usage: node scripts/catalog.mjs <generate|check>');
  process.exit(2);
}

const { components, errors } = loadCatalog(root);
if (errors.length > 0) {
  console.error(`The catalog has ${errors.length} problem(s):`);
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

const outputs = renderOutputs(root, components);

if (command === 'generate') {
  for (const [path, content] of outputs) {
    mkdirSync(dirname(join(root, path)), { recursive: true });
    writeFileSync(join(root, path), content);
  }
  console.log(`Generated ${outputs.size} files for ${components.length} component(s).`);
} else {
  const stale = findStale(root, outputs);
  if (stale.length > 0) {
    console.error(`Out of date: ${stale.join(', ')}. Run \`make catalog\`.`);
    process.exit(1);
  }
  console.log(`The catalog is valid: ${components.length} component(s).`);
}
