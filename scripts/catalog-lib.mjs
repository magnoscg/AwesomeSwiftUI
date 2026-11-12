// Reads Components/, checks every component against the rules in AGENTS.md and
// renders the files generated from the metadata. Nothing here writes to disk,
// so the same code serves `generate`, `check` and the tests.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const REPOSITORY = 'magnoscg/swiftui-components';
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
const SITE_BASE = '/swiftui-components';
const DOCS_PUBLIC = 'docs/public';
export const DOCS_CATALOG = 'docs/src/content/docs/catalog';
const BASELINE_IOS = 18;
const SHORTEST_FENCE = 5;
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
  errors.push(...categoryCollisions(components));
  reportUntranslatedCounts(root, components, errors);
  components.sort(byCategoryThenName);
  return { components, errors };
}

// A text like "^[\(count) photo](inflect: true)" agrees with its count in the
// language the app runs in. The Showcase has a String Catalog with other
// languages, and where it runs in one of them the English text loses its
// plural ("3 photo") unless the catalog translates it. So every such text
// needs a translation in every language of that catalog.
const SHOWCASE_STRINGS = 'Showcase/Showcase/Localizable.xcstrings';
const COUNTED_TEXT = /"((?:[^"\\\n]|\\.)*\^\[(?:[^"\\\n]|\\.)*\]\(inflect: true\)(?:[^"\\\n]|\\.)*)"/g;

function reportUntranslatedCounts(root, components, errors) {
  const file = join(root, SHOWCASE_STRINGS);
  if (!existsSync(file)) return;

  const catalog = JSON.parse(readFileSync(file, 'utf8'));
  const strings = Object.entries(catalog.strings ?? {});
  const languages = new Set(strings.flatMap(([, entry]) => Object.keys(entry.localizations ?? {})));
  languages.delete(catalog.sourceLanguage);
  const translations = new Map(
    strings.map(([key, entry]) => [key.replace(/%(?:\d+\$)?(?:lld|ld|d|lf|f|@)/g, '%'), Object.keys(entry.localizations ?? {})]),
  );

  for (const component of components) {
    for (const [, text] of withoutLineComments(component.source).matchAll(COUNTED_TEXT)) {
      const translated = translations.get(text.replace(/\\\([^)]*\)/g, '%')) ?? [];
      const missing = [...languages].filter((language) => !translated.includes(language));
      if (missing.length > 0) {
        errors.push(
          `${component.path}: "${text}" agrees with its count, so it needs a translation for ${missing.join(', ')} in ${SHOWCASE_STRINGS}`,
        );
      }
    }
  }
}

function loadComponent(root, relative, category, name, files, errors, requirePreview) {
  // The name becomes a type, a file and text in the pages of the site, which
  // are MDX: anything but letters and numbers could be run when it is built.
  if (!/^[A-Z][A-Za-z0-9]*$/.test(name)) {
    errors.push(`${relative}: the component folder must be one word of letters and numbers, got "${name}"`);
    return null;
  }
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
  if (meta.id === 'index') fail('"id" cannot be "index": the site gives that page to the category');
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
  if (origin.kind === 'inspired') {
    if (!isText(origin.credit)) fail('"origin.credit" must name what inspired the component');
    if (!isText(origin.url)) fail('"origin.url" must link what inspired the component');
  }
  if (origin.kind === 'adapted') {
    if (!isText(origin.url)) fail('"origin.url" must link the adapted source');
    if (!isText(origin.license)) fail('"origin.license" must name the license of the source');
  }
  // The site turns it into a link, so it has to be one a person can follow safely.
  if (isText(origin.url) && !/^https?:\/\/\S+$/.test(origin.url)) {
    fail(`"origin.url" must be a web address that starts with https:// or http://, got "${origin.url}"`);
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

  for (const number of repeatedNumbers(source)) {
    fail(`${number} is written ${REPEATED_NUMBER_LIMIT} or more times outside the demo: give it a name`);
  }
}

// A number written many times in a component is one value kept in several
// places. The demo is left out, because it is an example and not the code
// people keep, and so are the numbers that say nothing more with a name.
const DEMO_MARK = '// MARK: - Demo';
const REPEATED_NUMBER_LIMIT = 4;
const PLAIN_NUMBERS = new Set(['0', '1', '2', '0.5', '90', '100', '180', '360']);
const NAMED_NUMBER = /^\s*(?:(?:private|fileprivate|static|nonisolated)\s+)*(?:let|var)\s+\w+[^={]*=\s*-?[\d.]+\s*$/;

function repeatedNumbers(source) {
  const component = withoutLineComments(source.split(DEMO_MARK)[0]);
  const counts = new Map();

  for (const line of component.split('\n')) {
    const code = line.replace(/"(?:\\.|[^"\\])*"/g, '""');
    if (NAMED_NUMBER.test(code) || /[@#]available/.test(code)) continue;

    for (const [number] of code.matchAll(/(?<![\w.])\d+(?:\.\d+)?(?![\w.])/g)) {
      if (!PLAIN_NUMBERS.has(number)) counts.set(number, (counts.get(number) ?? 0) + 1);
    }
  }

  return [...counts].filter(([, count]) => count >= REPEATED_NUMBER_LIMIT).map(([number]) => number);
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

// The site serves a category at its name in lower case, so two folders that
// differ only in case would share a page. macOS cannot hold both; Linux can.
export function categoryCollisions(components) {
  const seen = new Map();
  const errors = [];
  for (const category of [...new Set(components.map((component) => component.category))].sort()) {
    const key = category.toLowerCase();
    if (seen.has(key)) {
      errors.push(`Components/${seen.get(key)} and Components/${category} differ only in case and would share a page on the site`);
    } else {
      seen.set(key, category);
    }
  }
  return errors;
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
  for (const category of categoriesOf(components)) {
    const members = components.filter((component) => component.category === category);
    pages.set(`${DOCS_CATALOG}/${category}/index.mdx`, renderDocsCategory(category, members));
  }
  for (const component of components) {
    pages.set(`${DOCS_CATALOG}/${component.category}/${component.id}.mdx`, renderDocsPage(component));
  }
  return pages;
}

function renderDocsIndex(components) {
  const frontmatter = [
    '---',
    'title: Catalog',
    'description: Every component in Awesome SwiftUI Components, with an animated preview.',
    'sidebar:',
    '  label: All components',
    '  order: 0',
    '---',
    '',
  ];
  if (components.length === 0) return [...frontmatter, 'No components yet.', ''].join('\n');

  return [
    ...frontmatter,
    "import CatalogGallery from '../../../components/CatalogGallery.astro';",
    '',
    '<CatalogGallery',
    ...galleryItems(components),
    '/>',
    '',
  ].join('\n');
}

// The page a category of the sidebar opens. It heads its group, so the pages
// of the site run from a category to its components and on to the next one.
// The site finds it by its attribute to draw it as the name of the group.
function renderDocsCategory(category, components) {
  const count = `${components.length} ${components.length === 1 ? 'component' : 'components'}`;
  return [
    '---',
    `title: ${JSON.stringify(category)}`,
    `description: ${JSON.stringify(`${count} in ${category}, each with an animated preview.`)}`,
    'sidebar:',
    '  order: 0',
    '  attrs:',
    '    data-category-page: true',
    '---',
    '',
    "import CatalogGallery from '../../../../components/CatalogGallery.astro';",
    '',
    '<CatalogGallery',
    `  category={${JSON.stringify(category)}}`,
    ...galleryItems(components),
    '/>',
    '',
  ].join('\n');
}

// One line per component keeps the page readable. JSON is valid in an MDX
// expression, so no text in it can be read as markup.
function galleryItems(components) {
  const items = components.map((component) =>
    JSON.stringify({
      title: component.title,
      summary: component.summary,
      preview: docsPreview(component),
      href: docsPage(component),
      category: component.category,
      minIOS: component.minIOS,
      difficulty: component.difficulty,
      keywords: [...component.keywords.en, ...component.keywords.es].join(' '),
      apis: component.apis,
      shader: Boolean(component.shader),
    }),
  );
  return ['  items={[', ...items.map((item) => `    ${item},`), '  ]}'];
}

// The page of a component. What it shows above the code, the preview, the
// details and the buttons, is drawn by a component of the site from
// catalog.json, so the page only names the component and carries its source.
function renderDocsPage(component) {
  const major = Number(component.minIOS.split('.')[0]);
  // The sidebar marks what does not run on the baseline.
  const badge = major > BASELINE_IOS ? ['sidebar:', '  badge:', `    text: iOS ${major}`] : [];
  return [
    '---',
    `title: ${JSON.stringify(component.title)}`,
    `description: ${JSON.stringify(component.summary)}`,
    ...badge,
    '---',
    '',
    "import ComponentHeader from '../../../../components/ComponentHeader.astro';",
    '',
    `<ComponentHeader id="${component.id}" />`,
    '',
    '## Use it',
    '',
    ...renderDocsSource(component),
  ].join('\n');
}

// A fence longer than any run of backticks in the source it holds. The pages
// are MDX, where a source that closed its own block would be run as code
// when the site is built.
function sourceFence(source) {
  const longest = Math.max(0, ...(source.match(/`+/g) ?? []).map((run) => run.length));
  return '`'.repeat(Math.max(SHORTEST_FENCE, longest + 1));
}

function renderDocsSource(component) {
  const swiftFence = sourceFence(component.source);
  const swift = [`${swiftFence}swift title="${component.name}.swift"`, component.source.trimEnd(), swiftFence, ''];
  if (!component.shader) {
    return [`Copy this code into your project, or [download the file](${RAW_BASE}/${component.path}).`, '', ...swift];
  }
  return [
    `Copy both files into your project: the Swift file and the Metal shader it draws with. Or download [${component.name}.swift](${RAW_BASE}/${component.path}) and [${component.name}.metal](${RAW_BASE}/${component.shader}).`,
    '',
    ...swift,
    // The site has no grammar for Metal, which is C++.
    `${sourceFence(component.shaderSource)}cpp title="${component.name}.metal"`,
    component.shaderSource.trimEnd(),
    sourceFence(component.shaderSource),
    '',
  ];
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
    '# Awesome SwiftUI Components',
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
    '# Awesome SwiftUI Components: every component with its source\n\nCopy-paste SwiftUI components for iOS 18 through iOS 27. Swift 6, MIT. A component with a shader has two files: copy both.\n';
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
