#!/usr/bin/env node
// `generate` rewrites the files derived from the metadata. `check` changes
// nothing and fails if a component breaks a rule or a generated file is stale.
// `docs` writes the uncommitted files the documentation site is built from.
// `prune <major>` is for CI runners with an older SDK: it deletes the components
// that need a newer iOS, so its result must never be committed.
import { copyFileSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  CATEGORY_PAGES,
  DOCS_CATALOG,
  componentsNewerThan,
  docsAssets,
  findStale,
  loadCatalog,
  renderDocsPages,
  renderOutputs,
} from './catalog-lib.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const command = process.argv[2];
const pruneMajor = Number(process.argv[3]);

if (!['generate', 'check', 'docs', 'prune'].includes(command) || (command === 'prune' && !Number.isInteger(pruneMajor))) {
  console.error('Usage: node scripts/catalog.mjs <generate|check|docs|prune <major>>');
  process.exit(2);
}

const { components, errors } = loadCatalog(root, { requirePreview: command !== 'generate' });
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
  // Starting clean keeps the page of a removed category from surviving.
  rmSync(join(root, CATEGORY_PAGES), { recursive: true, force: true });
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
} else if (command === 'prune') {
  const removed = componentsNewerThan(components, pruneMajor);
  for (const component of removed) {
    rmSync(join(root, dirname(component.path)), { recursive: true, force: true });
    rmSync(join(root, `Showcase/ShowcaseTests/${component.name}Tests.swift`), { force: true });
  }
  rmSync(join(root, CATEGORY_PAGES), { recursive: true, force: true });
  for (const [path, content] of renderOutputs(root, loadCatalog(root).components)) write(path, content);
  console.log(`Removed ${removed.length} component(s) that need more than iOS ${pruneMajor}.`);
} else {
  // Starting clean keeps a removed component from surviving in the site.
  rmSync(join(root, DOCS_CATALOG), { recursive: true, force: true });
  rmSync(join(root, 'docs/public/previews'), { recursive: true, force: true });
  for (const [path, content] of renderDocsPages(components)) write(path, content);
  for (const [source, destination] of docsAssets()) {
    mkdirSync(dirname(join(root, destination)), { recursive: true });
    copyFileSync(join(root, source), join(root, destination));
  }
  console.log(`Prepared the site for ${components.length} component(s).`);
}
