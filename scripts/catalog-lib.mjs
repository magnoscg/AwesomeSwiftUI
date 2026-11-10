// Reads Components/, checks every component against the rules in AGENTS.md and
// renders the files generated from the metadata. Nothing here writes to disk,
// so the same code serves `generate`, `check` and the tests.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const REPOSITORY = 'magnoscg/AwesomeSwiftUI';
const RAW_BASE = `https://raw.githubusercontent.com/${REPOSITORY}/HEAD`;
const BLOB_BASE = `https://github.com/${REPOSITORY}/blob/HEAD`;

// iOS 19 to 25 never existed: Apple went from 18 to 26.
const SUPPORTED_MAJORS = [18, 26, 27];
const BASELINE = '18.0';
const DIFFICULTIES = ['beginner', 'intermediate', 'advanced'];
const ORIGINS = ['original', 'inspired', 'adapted'];
const FIELDS = [
  'id',
  'name',
  'title',
  'category',
  'summary',
  'keywords',
  'difficulty',
  'minIOS',
  'apis',
  'origin',
  'previewSteps',
  'previewManual',
];
const RECORDING_FIELDS = ['previewSteps', 'previewManual'];
const DEFAULT_PREVIEW_SECONDS = 4;

export const CATEGORY_PAGES = 'catalog';
const SITE_BASE = '/AwesomeSwiftUI';
const DOCS_PUBLIC = 'docs/public';
export const DOCS_CATALOG = 'docs/src/content/docs/catalog';
// Longer than any run of backticks a Swift file is likely to hold.
const SOURCE_FENCE = '`````';
const MAX_PREVIEW_BYTES = 2 * 1024 * 1024;
const REGISTRY_PATH ='Showcase/Showcase/Generated/ComponentRegistry.swift';
const README_START = '<!-- catalog:start -->';
const README_END = '<!-- catalog:end -->';

// Each entry would break a rule of the catalog if it appeared in a component.
const BANNED_CODE = [
  [/\bObservableObject\b/, 'uses ObservableObject; use @Observable'],
  [/@StateObject\b/, 'uses @StateObject; use @State with an @Observable type'],
  [/@ObservedObject\b/, 'uses @ObservedObject; use an @Observable type'],
  [/@Published\b/, 'uses @Published; use @Observable'],
  [/^\s*import\s+XCTest\b/m, 'imports XCTest; use Swift Testing'],
  [/^\s*public\s/m, 'declares something public; components are internal'],
];

// `requirePreview: false` lets `generate` register a new component, so it can be
// opened in the Showcase and recorded. `check` always requires the preview.
export function loadCatalog(root, { requirePreview = true } = {}) {
  const errors = [];
  const components = [];
  const directory = join(root, 'Components');
  if (!existsSync(directory)) return { components, errors };

  const seenFiles = new Map();
  for (const category of subdirectories(directory)) {
    for (const name of subdirectories(join(directory, category))) {
      const relative = `Components/${category}/${name}`;
      const files = visibleFiles(join(root, relative));
      for (const file of files) {
        if (seenFiles.has(file)) {
          errors.push(`${relative}: file name ${file} is also used in ${seenFiles.get(file)}`);
        }
        seenFiles.set(file, relative);
      }
      const component = loadComponent(root, relative, category, name, files, errors, requirePreview);
      if (component) components.push(component);
    }
  }

  reportDuplicateIds(components, errors);
  components.sort(byCategoryThenName);
  return { components, errors };
}

function loadComponent(root, relative, category, name, files, errors, requirePreview) {
  const metaFile = `${name}.meta.json`;
  const sourceFile = `${name}.swift`;
  const shaderFile = `${name}.metal`;
  if (!files.includes(metaFile)) {
    errors.push(`${relative}: missing ${metaFile}`);
    return null;
  }
  if (!files.includes(sourceFile)) {
    errors.push(`${relative}: missing ${sourceFile}`);
    return null;
  }

  let meta;
  try {
    meta = JSON.parse(readFileSync(join(root, relative, metaFile), 'utf8'));
  } catch (error) {
    errors.push(`${relative}: ${metaFile} is not valid JSON: ${error.message}`);
    return null;
  }

  const source = readFileSync(join(root, relative, sourceFile), 'utf8');
  const shaderSource = files.includes(shaderFile) ? readFileSync(join(root, relative, shaderFile), 'utf8') : null;
  const before = errors.length;
  validateMeta(meta, relative, category, name, errors);
  if (errors.length === before) {
    validateSource(meta, source, relative, name, errors);
    if (shaderSource !== null) validateShader(meta, source, shaderSource, relative, name, errors);
  }
  for (const file of files) {
    if (file.endsWith('.metal') && file !== shaderFile) {
      errors.push(`${relative}: ${file} must be named ${shaderFile}, the one shader a component may have`);
    }
  }
  validatePreview(root, relative, name, files, errors, requirePreview);
  if (errors.length !== before) return null;

  const component = { ...meta, path: `${relative}/${sourceFile}`, preview: `${relative}/${name}.webp`, source };
  if (shaderSource === null) return component;
  return { ...component, shader: `${relative}/${shaderFile}`, shaderSource };
}

function validatePreview(root, relative, name, files, errors, requirePreview) {
  const previewFile = `${name}.webp`;
  if (!files.includes(previewFile)) {
    if (requirePreview) errors.push(`${relative}: missing ${previewFile}`);
    return;
  }
  const bytes = readFileSync(join(root, relative, previewFile));
  if (!isAnimatedWebP(bytes)) errors.push(`${relative}: ${previewFile} is not an animated WebP`);
  if (bytes.length > MAX_PREVIEW_BYTES) {
    errors.push(`${relative}: ${previewFile} is larger than ${MAX_PREVIEW_BYTES / 1024 / 1024} MB`);
  }
}

// The ANIM chunk sits near the start of the file and only exists in animations.
function isAnimatedWebP(bytes) {
  return (
    bytes.toString('latin1', 0, 4) === 'RIFF' &&
    bytes.toString('latin1', 8, 12) === 'WEBP' &&
    bytes.subarray(0, 4096).includes('ANIM', 0, 'latin1')
  );
}

function validateMeta(meta, relative, category, name, errors) {
  const fail = (message) => errors.push(`${relative}: ${message}`);

  if (meta === null || typeof meta !== 'object' || Array.isArray(meta)) {
    fail('metadata must be a JSON object');
    return;
  }
  for (const field of Object.keys(meta)) {
    if (!FIELDS.includes(field)) fail(`unknown field "${field}"`);
  }
  for (const field of ['id', 'name', 'title', 'category', 'summary']) {
    if (!isText(meta[field])) fail(`"${field}" must be a non-empty string`);
  }

  if (isText(meta.id) && !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(meta.id)) {
    fail(`"id" must be kebab-case, got "${meta.id}"`);
  }
  if (isText(meta.name) && meta.name !== name) {
    fail(`"name" must match the folder ${name}, got "${meta.name}"`);
  }
  if (!/^[A-Z][A-Za-z0-9]*$/.test(category)) {
    fail(`the category folder must be one word of letters and numbers, got "${category}"`);
  }
  if (isText(meta.category) && meta.category !== category) {
    fail(`"category" must match the folder ${category}, got "${meta.category}"`);
  }
  if (!DIFFICULTIES.includes(meta.difficulty)) {
    fail(`"difficulty" must be one of ${DIFFICULTIES.join(', ')}`);
  }
  if (!isSupportedVersion(meta.minIOS)) {
    fail(`"minIOS" must look like 18.0 on iOS ${SUPPORTED_MAJORS.join(', ')}`);
  }
  if (!isTextList(meta.apis)) fail('"apis" must be a non-empty list of strings');
  if (!isTextList(meta.keywords?.en)) fail('"keywords.en" must be a non-empty list of strings');
  if (!isTextList(meta.keywords?.es)) fail('"keywords.es" must be a non-empty list of strings');
  if (meta.previewSteps !== undefined && !isTextList(meta.previewSteps)) {
    fail('"previewSteps" must be a non-empty list of strings');
  }
  if (meta.previewManual !== undefined && meta.previewManual !== true) fail('"previewManual" can only be true');
  validateOrigin(meta.origin, fail);
}

function validateOrigin(origin, fail) {
  if (!ORIGINS.includes(origin?.kind)) {
    fail(`"origin.kind" must be one of ${ORIGINS.join(', ')}`);
    return;
  }
  if (origin.kind === 'inspired' && !isText(origin.credit)) {
    fail('"origin.credit" must name what inspired the component');
  }
  if (origin.kind === 'adapted') {
    if (!isText(origin.url)) fail('"origin.url" must link the adapted source');
    if (!isText(origin.license)) fail('"origin.license" must name the license of the source');
  }
}

function validateSource(meta, source, relative, name, errors) {
  const fail = (message) => errors.push(`${relative}: ${message}`);

  validateHeader(meta, source, 'the first line', fail);

  if (!new RegExp(`\\bstruct\\s+${name}Demo\\b`).test(source)) fail(`missing struct ${name}Demo`);
  if (!source.includes('#Preview')) fail('missing #Preview');

  if (meta.minIOS !== BASELINE && !availabilityPattern(meta.minIOS).test(source)) {
    fail(`"minIOS" is ${meta.minIOS} but the source has no matching @available`);
  }

  const code = withoutLineComments(source);
  for (const [pattern, message] of BANNED_CODE) {
    if (pattern.test(code)) fail(message);
  }
}

function validateHeader(meta, text, line, fail) {
  const firstLine = text.split('\n', 1)[0];
  if (meta.origin.kind === 'adapted') {
    if (!firstLine.startsWith('// SPDX-License-Identifier:')) fail(`${line} must be an SPDX license header`);
  } else if (firstLine !== '// SPDX-License-Identifier: MIT') {
    fail(`${line} must be "// SPDX-License-Identifier: MIT"`);
  }
}

// Xcode compiles every .metal file of a target into one library, in the
// Showcase and in the app a component is copied to, so two functions with the
// same name collide. The name of the component in front keeps them apart.
function validateShader(meta, source, shaderSource, relative, name, errors) {
  const fail = (message) => errors.push(`${relative}: ${message}`);
  const shaderFile = `${name}.metal`;

  validateHeader(meta, shaderSource, `the first line of ${shaderFile}`, fail);
  if (!source.includes(shaderFile)) fail(`${name}.swift must say that ${shaderFile} is copied with it`);

  const functions = shaderFunctions(shaderSource);
  if (functions.length === 0) fail(`${shaderFile} defines no function`);
  for (const shaderFunction of functions) {
    if (!shaderFunction.startsWith(name)) fail(`function ${shaderFunction} in ${shaderFile} must start with ${name}`);
  }
}

// Returns the names of the functions a shader defines. Metal is C++, so a
// definition is a name, its parameters and a body, outside every other body.
function shaderFunctions(shaderSource) {
  const code = shaderSource
    .replace(/\/\*[\s\S]*?\*\//g, ' ')
    .replace(/\/\/.*$/gm, '')
    .replace(/\\\n/g, ' ')
    .replace(/^[ \t]*#.*$/gm, '');

  let topLevel = '';
  let depth = 0;
  for (const character of code) {
    if (character === '}') depth -= 1;
    if (depth === 0) topLevel += character;
    if (character === '{') depth += 1;
  }
  const definition = /([A-Za-z_]\w*)\s*\((?:[^()]|\([^()]*\))*\)\s*\{/g;
  return [...topLevel.matchAll(definition)].map((match) => match[1]);
}

function availabilityPattern(version) {
  const [major, minor] = version.split('.');
  const suffix = minor === '0' ? `(\\.0)?` : `\\.${minor}`;
  return new RegExp(`@available\\(iOS ${major}${suffix}\\s*,`);
}

function reportDuplicateIds(components, errors) {
  const seen = new Map();
  for (const component of components) {
    if (seen.has(component.id)) {
      errors.push(`${component.path}: id "${component.id}" is also used by ${seen.get(component.id)}`);
    }
    seen.set(component.id, component.path);
  }
}

// Returns every generated file, keyed by its path from the repository root.
export function renderOutputs(root, components) {
  return new Map([
    ['catalog.json', renderCatalogJSON(components)],
    ['llms.txt', renderLLMs(components)],
    ['llms-full.txt', renderLLMsFull(components)],
    ['README.md', renderReadme(readFileSync(join(root, 'README.md'), 'utf8'), components)],
    [REGISTRY_PATH, renderRegistry(components)],
    ...renderCategoryPages(components),
  ]);
}

function categoriesOf(components) {
  return [...new Set(components.map((component) => component.category))];
}

// One page per category, so that GitHub only loads the previews a reader asks for.
function renderCategoryPages(components) {
  return categoriesOf(components).map((category) => {
    const rows = components
      .filter((component) => component.category === category)
      .map((component) => {
        const shader = component.shader ? ` and its [shader](../${component.shader})` : '';
        return `| <img src="../${component.preview}" width="120" alt="${escapeAttribute(component.title)} preview"> | [${component.title}](../${component.path})${shader} | ${escapeCell(component.summary)} | ${component.minIOS}+ | ${component.difficulty} |`;
      });
    const page = [
      `# ${category}`,
      '',
      '[All categories](../README.md#catalog)',
      '',
      '| Preview | Component | What it does | iOS | Level |',
      '|---|---|---|---|---|',
      ...rows,
      '',
    ].join('\n');
    return [`${CATEGORY_PAGES}/${category}.md`, page];
  });
}

function renderRegistry(components) {
  const header = [
    '// Generated by scripts/catalog.mjs from the component metadata. Do not edit.',
    '',
    'import SwiftUI',
    '',
    '@MainActor',
    'enum ComponentRegistry {',
  ];
  if (components.length === 0) {
    return [...header, '    static let entries: [ShowcaseEntry] = []', '}', ''].join('\n');
  }
  return [
    ...header,
    '    static let entries: [ShowcaseEntry] = [',
    ...components.flatMap(renderRegistryEntry),
    '    ]',
    '}',
    '',
  ].join('\n');
}

function renderRegistryEntry(component) {
  const keywords = [...component.keywords.en, ...component.keywords.es].map(swiftString).join(', ');
  return [
    '        ShowcaseEntry(',
    `            id: ${swiftString(component.id)},`,
    `            title: ${swiftString(component.title)},`,
    `            category: ${swiftString(component.category)},`,
    `            summary: ${swiftString(component.summary)},`,
    `            keywords: [${keywords}],`,
    `            minIOS: ${swiftString(component.minIOS)},`,
    ...renderRegistryDemo(component),
    '        ),',
  ];
}

function renderRegistryDemo(component) {
  const demo = `AnyView(${component.name}Demo())`;
  if (component.minIOS === BASELINE) return [`            demo: { ${demo} }`];
  return [
    '            demo: {',
    `                guard #available(iOS ${component.minIOS}, *) else { return nil }`,
    `                return ${demo}`,
    '            }',
  ];
}

// A JSON string is a valid Swift literal for the text metadata can hold.
function swiftString(text) {
  return JSON.stringify(text);
}

// Says how to record a component: nothing when it is recorded by hand, the given
// interaction steps, or a few idle seconds for a demo that animates by itself.
export function previewPlan(component) {
  if (component.previewManual) return { record: false };
  if (component.previewSteps) return { record: true, steps: component.previewSteps };
  return { record: true, steps: [`sleep ${DEFAULT_PREVIEW_SECONDS}`] };
}

// Picks the booted iOS simulator with the newest runtime from `simctl list -j`.
export function newestSimulator(devicesByRuntime) {
  const simulators = Object.entries(devicesByRuntime).flatMap(([runtime, devices]) => {
    const match = runtime.match(/iOS-(\d+)-(\d+)/);
    if (!match) return [];
    return devices.map((device) => ({ udid: device.udid, version: [Number(match[1]), Number(match[2])] }));
  });
  simulators.sort((a, b) => compareVersions(b.version, a.version));
  return simulators[0] ?? null;
}

export function simulatorSupports(version, minIOS) {
  return compareVersions(version, minIOS.split('.').map(Number)) >= 0;
}

function compareVersions([majorA, minorA], [majorB, minorB]) {
  return majorA - majorB || minorA - minorB;
}

// Returns the components that need a newer iOS than the given major version.
export function componentsNewerThan(components, major) {
  return components.filter((component) => Number(component.minIOS.split('.')[0]) > major);
}

// Returns the catalog pages of the site, keyed by their path from the repository
// root. They are built on demand and never committed.
export function renderDocsPages(components) {
  const pages = new Map([[`${DOCS_CATALOG}/index.mdx`, renderDocsIndex(components)]]);
  for (const component of components) {
    pages.set(`${DOCS_CATALOG}/${component.category}/${component.id}.md`, renderDocsPage(component));
  }
  return pages;
}

function renderDocsIndex(components) {
  const frontmatter = [
    '---',
    'title: Catalog',
    'description: Every component in AwesomeSwiftUI, with an animated preview.',
    'sidebar:',
    '  label: All components',
    '  order: 0',
    '---',
    '',
  ];
  if (components.length === 0) return [...frontmatter, 'No components yet.', ''].join('\n');

  const cards = components.flatMap((component) => [
    `  <Card title={${JSON.stringify(component.title)}}>`,
    `    <img src={${JSON.stringify(docsPreview(component))}} alt={${JSON.stringify(`${component.title} preview`)}} width="160" loading="lazy" />`,
    `    <p>{${JSON.stringify(component.summary)}}</p>`,
    `    <p><a href={${JSON.stringify(docsPage(component))}}>iOS {${JSON.stringify(component.minIOS)}}+ · {${JSON.stringify(component.category)}}</a></p>`,
    '  </Card>',
  ]);
  return [
    ...frontmatter,
    "import { Card, CardGrid } from '@astrojs/starlight/components';",
    '',
    '<CardGrid>',
    ...cards,
    '</CardGrid>',
    '',
  ].join('\n');
}

function renderDocsPage(component) {
  const keywords = [...component.keywords.en, ...component.keywords.es].map(escapeHTML).join(', ');
  const apis = component.apis.map((api) => `\`${api}\``).join(', ');
  return [
    '---',
    `title: ${JSON.stringify(component.title)}`,
    `description: ${JSON.stringify(component.summary)}`,
    '---',
    '',
    escapeHTML(component.summary),
    '',
    `<img src="${docsPreview(component)}" alt="${escapeAttribute(component.title)} preview" width="320" loading="lazy">`,
    '',
    '| | |',
    '|---|---|',
    `| Category | ${component.category} |`,
    `| Minimum iOS | ${component.minIOS} |`,
    `| Level | ${component.difficulty} |`,
    `| APIs | ${apis} |`,
    `| Origin | ${renderDocsOrigin(component.origin)} |`,
    `| Keywords | ${escapeCell(keywords)} |`,
    '',
    '## Use it',
    '',
    ...renderDocsSource(component),
  ].join('\n');
}

function renderDocsSource(component) {
  const swift = [`${SOURCE_FENCE}swift title="${component.name}.swift"`, component.source.trimEnd(), SOURCE_FENCE, ''];
  if (!component.shader) {
    return [`Copy this code into your project, or [download the file](${RAW_BASE}/${component.path}).`, '', ...swift];
  }
  return [
    `Copy both files into your project: the Swift file and the Metal shader it draws with. Or download [${component.name}.swift](${RAW_BASE}/${component.path}) and [${component.name}.metal](${RAW_BASE}/${component.shader}).`,
    '',
    ...swift,
    // The site has no grammar for Metal, which is C++.
    `${SOURCE_FENCE}cpp title="${component.name}.metal"`,
    component.shaderSource.trimEnd(),
    SOURCE_FENCE,
    '',
  ];
}

function renderDocsOrigin(origin) {
  if (origin.kind === 'original') return 'Original';
  if (origin.kind === 'adapted') return `Adapted from [the source](${origin.url}), ${escapeHTML(origin.license)}`;
  const credit = escapeHTML(origin.credit);
  return origin.url ? `Inspired by [${credit}](${origin.url})` : `Inspired by ${credit}`;
}

// Served from the repository, not the site: the previews make the site too big
// for GitHub Pages to deploy within its time limit.
function docsPreview(component) {
  return `${RAW_BASE}/${component.preview}`;
}

function docsPage(component) {
  return `${SITE_BASE}/catalog/${component.category.toLowerCase()}/${component.id}/`;
}

// Returns the files the site serves as they are: from the repository root to
// their place in docs/public.
export function docsAssets() {
  return new Map(['catalog.json', 'llms.txt', 'llms-full.txt'].map((file) => [file, `${DOCS_PUBLIC}/${file}`]));
}

// Returns the generated files whose content on disk is missing or out of date.
export function findStale(root, outputs) {
  const stale = [];
  for (const [path, content] of outputs) {
    const file = join(root, path);
    if (!existsSync(file) || readFileSync(file, 'utf8') !== content) stale.push(path);
  }
  const pages = join(root, CATEGORY_PAGES);
  if (existsSync(pages)) {
    for (const file of readdirSync(pages).sort(compareText)) {
      const path = `${CATEGORY_PAGES}/${file}`;
      if (!outputs.has(path)) stale.push(path);
    }
  }
  return stale;
}

function renderCatalogJSON(components) {
  const entries = components.map(({ source, shaderSource, ...component }) => {
    for (const field of RECORDING_FIELDS) delete component[field];
    const entry = { ...component, rawURL: `${RAW_BASE}/${component.path}` };
    return component.shader ? { ...entry, shaderRawURL: `${RAW_BASE}/${component.shader}` } : entry;
  });
  return `${JSON.stringify({ count: entries.length, components: entries }, null, 2)}\n`;
}

function renderLLMs(components) {
  const lines = [
    '# AwesomeSwiftUI',
    '',
    '> Copy-paste SwiftUI components, animations and transitions for iOS 18 through iOS 27. Swift 6, MIT. There is no package: download the file of a component and add it to the project. A component drawn by a Metal shader has a second file, which its entry links: add both. Each component states its minimum iOS.',
    '',
    `Search \`${RAW_BASE}/catalog.json\` by keyword, in English or Spanish, and fetch the \`rawURL\` of the match, and its \`shaderRawURL\` when it has one.`,
    '',
    '## Components',
    '',
  ];
  if (components.length === 0) lines.push('No components yet.', '');
  for (const component of components) {
    const keywords = [...component.keywords.en, ...component.keywords.es].join(', ');
    const shader = component.shader
      ? ` Copy its shader too: [${component.name}.metal](${RAW_BASE}/${component.shader}).`
      : '';
    lines.push(
      `- [${component.title}](${RAW_BASE}/${component.path}): ${component.summary} iOS ${component.minIOS}+. ${component.category}. Keywords: ${keywords}.${shader}`,
    );
  }
  if (components.length > 0) lines.push('');
  lines.push(
    '## Docs',
    '',
    `- [README](${BLOB_BASE}/README.md): what the catalog is and how it is organized`,
    `- [AGENTS.md](${BLOB_BASE}/AGENTS.md): repository map and the rules every component keeps`,
    `- [Full catalog with source](${RAW_BASE}/llms-full.txt): every component in one file`,
    '',
  );
  return lines.join('\n');
}

function renderLLMsFull(components) {
  const header =
    '# AwesomeSwiftUI: every component with its source\n\nCopy-paste SwiftUI components for iOS 18 through iOS 27. Swift 6, MIT. A component with a shader has two files: copy both.\n';
  const sections = components.map((component) => {
    const shader = component.shader
      ? `\nShader: ${component.shader}\n\n\`\`\`metal\n${component.shaderSource.trimEnd()}\n\`\`\`\n`
      : '';
    return `\n## ${component.title}\n\n${component.summary}\n\nCategory: ${component.category}. Minimum: iOS ${component.minIOS}. Path: ${component.path}\n\n\`\`\`swift\n${component.source.trimEnd()}\n\`\`\`\n${shader}`;
  });
  return header + sections.join('');
}

function renderReadme(readme, components) {
  const start = readme.indexOf(README_START);
  const end = readme.indexOf(README_END);
  if (start === -1 || end === -1 || end < start) {
    throw new Error(`README.md must contain ${README_START} and ${README_END}`);
  }
  const before = readme.slice(0, start + README_START.length);
  return `${before}\n\n${renderReadmeCatalog(components)}\n\n${readme.slice(end)}`;
}

function renderReadmeCatalog(components) {
  if (components.length === 0) return 'No components yet.';

  const rows = categoriesOf(components).map((category) => {
    const members = components.filter((component) => component.category === category);
    const links = members.map((component) => `[${component.title}](${component.path})`).join(' · ');
    const [featured] = members;
    return `| <img src="${featured.preview}" width="120" alt="${escapeAttribute(featured.title)} preview"> | [${category}](${CATEGORY_PAGES}/${category}.md) | ${members.length} | ${links} |`;
  });
  return [
    `**${components.length} components.** Open a category to see every preview.`,
    '',
    '| Preview | Category | Count | Components |',
    '|---|---|---|---|',
    ...rows,
  ].join('\n');
}

function byCategoryThenName(a, b) {
  return compareText(a.category, b.category) || compareText(a.name, b.name);
}

// A plain comparison, so the order does not depend on the machine's locale.
function compareText(a, b) {
  if (a === b) return 0;
  return a < b ? -1 : 1;
}

function subdirectories(directory) {
  return readdirSync(directory, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort(compareText);
}

function visibleFiles(directory) {
  return readdirSync(directory, { withFileTypes: true })
    .filter((entry) => entry.isFile() && !entry.name.startsWith('.'))
    .map((entry) => entry.name)
    .sort(compareText);
}

function withoutLineComments(source) {
  return source
    .split('\n')
    .filter((line) => !line.trimStart().startsWith('//'))
    .join('\n');
}

function escapeCell(text) {
  return text.replaceAll('|', '\\|');
}

function escapeHTML(text) {
  return text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

function escapeAttribute(text) {
  return text.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
}

function isText(value) {
  return typeof value === 'string' && value.trim() !== '';
}

function isTextList(value) {
  return Array.isArray(value) && value.length > 0 && value.every(isText);
}

function isSupportedVersion(value) {
  return (
    typeof value === 'string' &&
    /^\d+\.\d+$/.test(value) &&
    SUPPORTED_MAJORS.includes(Number(value.split('.')[0]))
  );
}
