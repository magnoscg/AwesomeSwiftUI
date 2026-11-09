#!/usr/bin/env node
// `generate` rewrites the files derived from the metadata. `check` changes
// nothing and fails if a component breaks a rule or a generated file is stale.
// `docs` writes the uncommitted files the documentation site is built from.
import { copyFileSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { DOCS_CATALOG, docsAssets, findStale, loadCatalog, renderDocsPages, renderOutputs } from './catalog-lib.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const command = process.argv[2];

if (!['generate', 'check', 'docs'].includes(command)) {
  console.error('Usage: node scripts/catalog.mjs <generate|check|docs>');
  process.exit(2);
}

const { components, errors } = loadCatalog(root);
if (errors.length > 0) {
  console.error(`The catalog has ${errors.length} problem(s):`);
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

function write(path, content) {
  mkdirSync(dirname(join(root, path)), { recursive: true });
  writeFileSync(join(root, path), content);
}

if (command === 'generate') {
  const outputs = renderOutputs(root, components);
  for (const [path, content] of outputs) write(path, content);
  console.log(`Generated ${outputs.size} files for ${components.length} component(s).`);
} else if (command === 'check') {
  const stale = findStale(root, renderOutputs(root, components));
  if (stale.length > 0) {
    console.error(`Out of date: ${stale.join(', ')}. Run \`make catalog\`.`);
    process.exit(1);
  }
  console.log(`The catalog is valid: ${components.length} component(s).`);
} else {
  // Starting clean keeps a removed component from surviving in the site.
  rmSync(join(root, DOCS_CATALOG), { recursive: true, force: true });
  rmSync(join(root, 'docs/public/previews'), { recursive: true, force: true });
  for (const [path, content] of renderDocsPages(components)) write(path, content);
  for (const [source, destination] of docsAssets(components)) {
    mkdirSync(dirname(join(root, destination)), { recursive: true });
    copyFileSync(join(root, source), join(root, destination));
  }
  console.log(`Prepared the site for ${components.length} component(s).`);
}
