import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { afterEach, describe, it } from 'node:test';
import {
  componentsNewerThan,
  docsAssets,
  findStale,
  loadCatalog,
  newestSimulator,
  previewPlan,
  renderDocsPages,
  renderOutputs,
  simulatorSupports,
} from './catalog-lib.mjs';

const README = 'Intro\n\n<!-- catalog:start -->\n\nold\n\n<!-- catalog:end -->\n\nOutro\n';
const roots = [];

function makeRoot(readme = README) {
  const root = mkdtempSync(join(tmpdir(), 'catalog-'));
  roots.push(root);
  writeFileSync(join(root, 'README.md'), readme);
  return root;
}

function meta(overrides = {}) {
  return {
    id: 'glow-button',
    name: 'GlowButton',
    title: 'Glow Button',
    category: 'Buttons',
    summary: 'A button that glows.',
    keywords: { en: ['button'], es: ['boton'] },
    difficulty: 'beginner',
    minIOS: '18.0',
    apis: ['ButtonStyle'],
    origin: { kind: 'original' },
    ...overrides,
  };
}

function swift(name = 'GlowButton', body = '') {
  return `// SPDX-License-Identifier: MIT\nimport SwiftUI\n${body}\nstruct ${name}Demo: View {}\n#Preview { ${name}Demo() }\n`;
}

// A Swift file that names its shader, as a component with one must.
function swiftWithShader(name = 'GlowButton') {
  return swift(name, `/// Copy ${name}.metal with this file.`);
}

const SHADER_FUNCTION = '[[ stitchable ]] half4 GlowButtonTint(float2 position, half4 color) {\n    return color;\n}';

function metal(functions = SHADER_FUNCTION) {
  return `// SPDX-License-Identifier: MIT\n#include <SwiftUI/SwiftUI_Metal.h>\n\n${functions}\n`;
}

function animatedWebP() {
  return Buffer.concat([Buffer.from('RIFF\0\0\0\0WEBPVP8X'), Buffer.alloc(14), Buffer.from('ANIM')]);
}

function addComponent(
  root,
  {
    category = 'Buttons',
    name = 'GlowButton',
    metadata = meta(),
    source = swift(name),
    preview = animatedWebP(),
    shader = null,
  } = {},
) {
  const directory = join(root, 'Components', category, name);
  mkdirSync(directory, { recursive: true });
  if (preview !== null) writeFileSync(join(directory, `${name}.webp`), preview);
  if (metadata !== null) {
    const text = typeof metadata === 'string' ? metadata : JSON.stringify(metadata);
    writeFileSync(join(directory, `${name}.meta.json`), text);
  }
  if (source !== null) writeFileSync(join(directory, `${name}.swift`), source);
  if (shader !== null) writeFileSync(join(directory, `${name}.metal`), shader);
  return directory;
}

function errorsFor(options) {
  const root = makeRoot();
  addComponent(root, options);
  return loadCatalog(root).errors;
}

function assertRejected(options, expected) {
  const errors = errorsFor(options);
  assert.ok(
    errors.some((error) => expected.test(error)),
    `expected ${expected} in ${JSON.stringify(errors)}`,
  );
}

afterEach(() => {
  while (roots.length > 0) rmSync(roots.pop(), { recursive: true, force: true });
});

describe('an empty catalog', () => {
  it('loads when there is no Components folder', () => {
    assert.deepEqual(loadCatalog(makeRoot()), { components: [], errors: [] });
  });

  it('says so in the generated files', () => {
    const root = makeRoot();
    const outputs = renderOutputs(root, []);

    assert.equal(JSON.parse(outputs.get('catalog.json')).count, 0);
    assert.match(outputs.get('llms.txt'), /No components yet\./);
    assert.match(outputs.get('README.md'), /catalog:start -->\n\nNo components yet\.\n\n<!-- catalog:end/);
  });
});

describe('a valid component', () => {
  it('reaches every generated file', () => {
    const root = makeRoot();
    addComponent(root);
    const { components, errors } = loadCatalog(root);
    const outputs = renderOutputs(root, components);

    assert.deepEqual(errors, []);
    const [entry] = JSON.parse(outputs.get('catalog.json')).components;
    assert.equal(entry.id, 'glow-button');
    assert.equal(entry.path, 'Components/Buttons/GlowButton/GlowButton.swift');
    assert.equal(entry.source, undefined);
    assert.equal(entry.shader, undefined);
    assert.equal(entry.shaderRawURL, undefined);
    assert.match(entry.rawURL, /\/HEAD\/Components\/Buttons\/GlowButton\/GlowButton\.swift$/);
    assert.match(outputs.get('llms.txt'), /Glow Button.*iOS 18\.0\+.*button, boton/);
    assert.match(outputs.get('llms-full.txt'), /```swift\n\/\/ SPDX-License-Identifier: MIT/);
    assert.match(outputs.get('README.md'), /\| \[Buttons\]\(catalog\/Buttons\.md\) \| 1 \| \[Glow Button\]\(Components\/Buttons\/GlowButton\/GlowButton\.swift\) \|/);
    assert.match(outputs.get('catalog/Buttons.md'), /\| \[Glow Button\]\(\.\.\/Components\/Buttons\/GlowButton\/GlowButton\.swift\)/);
  });

  it('keeps the README outside the markers', () => {
    const root = makeRoot();
    addComponent(root);

    const readme = renderOutputs(root, loadCatalog(root).components).get('README.md');

    assert.ok(readme.startsWith('Intro\n'));
    assert.ok(readme.endsWith('<!-- catalog:end -->\n\nOutro\n'));
    assert.doesNotMatch(readme, /old/);
  });

  it('escapes pipes in the category table', () => {
    const root = makeRoot();
    addComponent(root, { metadata: meta({ summary: 'One | two.' }) });

    const page = renderOutputs(root, loadCatalog(root).components).get('catalog/Buttons.md');

    assert.match(page, /One \\\| two\./);
  });

  it('shows its preview on the page of its category', () => {
    const root = makeRoot();
    addComponent(root);

    const page = renderOutputs(root, loadCatalog(root).components).get('catalog/Buttons.md');

    assert.match(page, /<img src="\.\.\/Components\/Buttons\/GlowButton\/GlowButton\.webp" width="120" alt="Glow Button preview">/);
  });

  it('features only the first component of each category in the README', () => {
    const root = makeRoot();
    addComponent(root, { name: 'Alpha', metadata: meta({ id: 'alpha', name: 'Alpha', title: 'Alpha' }), source: swift('Alpha') });
    addComponent(root, { name: 'Beta', metadata: meta({ id: 'beta', name: 'Beta', title: 'Beta' }), source: swift('Beta') });

    const outputs = renderOutputs(root, loadCatalog(root).components);

    assert.equal(outputs.get('README.md').match(/<img /g).length, 1);
    assert.equal(outputs.get('catalog/Buttons.md').match(/<img /g).length, 2);
    assert.match(outputs.get('README.md'), /\*\*2 components\.\*\*/);
  });

  it('escapes quotes in the alt text of its preview', () => {
    const root = makeRoot();
    addComponent(root, { metadata: meta({ title: 'The "Glow" Button' }) });

    const page = renderOutputs(root, loadCatalog(root).components).get('catalog/Buttons.md');

    assert.match(page, /alt="The &quot;Glow&quot; Button preview"/);
  });

  it('records the path of its preview', () => {
    const root = makeRoot();
    addComponent(root);

    const [entry] = JSON.parse(renderOutputs(root, loadCatalog(root).components).get('catalog.json')).components;

    assert.equal(entry.preview, 'Components/Buttons/GlowButton/GlowButton.webp');
  });

  it('accepts @available without a minor version', () => {
    const source = swift('GlowButton', '@available(iOS 26, *)\nstruct Glass {}');

    assert.deepEqual(errorsFor({ metadata: meta({ minIOS: '26.0' }), source }), []);
  });

  it('ignores banned words in comments', () => {
    const source = swift('GlowButton', '// Replaces an ObservableObject.');

    assert.deepEqual(errorsFor({ source }), []);
  });
});

describe('the order of the catalog', () => {
  it('sorts by category and then by name', () => {
    const root = makeRoot();
    const add = (category, name, id) =>
      addComponent(root, { category, name, metadata: meta({ id, name, category }), source: swift(name) });
    add('Text', 'Alpha', 'alpha');
    add('Buttons', 'Zeta', 'zeta');
    add('Buttons', 'Beta', 'beta');

    const names = loadCatalog(root).components.map((component) => component.name);

    assert.deepEqual(names, ['Beta', 'Zeta', 'Alpha']);
  });
});

describe('invalid components', () => {
  it('rejects a category name that would break its links', () => {
    assertRejected({ category: 'Cards#Demo', metadata: meta({ category: 'Cards#Demo' }) }, /must be one word/);
  });

  it('rejects a folder without metadata', () => {
    assertRejected({ metadata: null }, /missing GlowButton\.meta\.json/);
  });

  it('rejects a folder without source', () => {
    assertRejected({ source: null }, /missing GlowButton\.swift/);
  });

  it('rejects metadata that is not JSON', () => {
    assertRejected({ metadata: '{ nope' }, /not valid JSON/);
  });

  const invalidMetadata = [
    ['an unknown field', { extra: true }, /unknown field "extra"/],
    ['an empty title', { title: ' ' }, /"title" must be a non-empty string/],
    ['an id that is not kebab-case', { id: 'GlowButton' }, /"id" must be kebab-case/],
    ['a name that differs from the folder', { name: 'Other' }, /"name" must match the folder/],
    ['a category that differs from the folder', { category: 'Text' }, /"category" must match the folder/],
    ['an unknown difficulty', { difficulty: 'easy' }, /"difficulty" must be one of/],
    ['an iOS version that never existed', { minIOS: '19.0' }, /"minIOS" must look like/],
    ['a malformed iOS version', { minIOS: '18' }, /"minIOS" must look like/],
    ['no APIs', { apis: [] }, /"apis" must be a non-empty list/],
    ['no English keywords', { keywords: { en: [], es: ['x'] } }, /"keywords\.en"/],
    ['no Spanish keywords', { keywords: { en: ['x'] } }, /"keywords\.es"/],
    ['an unknown origin', { origin: { kind: 'internet' } }, /"origin\.kind" must be one of/],
    ['inspiration without credit', { origin: { kind: 'inspired', url: 'https://x.dev' } }, /"origin\.credit"/],
    ['inspiration without a link', { origin: { kind: 'inspired', credit: 'A talk' } }, /"origin\.url"/],
    ['adapted code without a source', { origin: { kind: 'adapted', license: 'MIT' } }, /"origin\.url"/],
    ['adapted code without a license', { origin: { kind: 'adapted', url: 'https://x.dev' } }, /"origin\.license"/],
  ];

  for (const [label, overrides, expected] of invalidMetadata) {
    it(`rejects ${label}`, () => {
      assertRejected({ metadata: meta(overrides) }, expected);
    });
  }

  it('leaves invalid components out of the catalog', () => {
    const root = makeRoot();
    addComponent(root, { metadata: meta({ difficulty: 'easy' }) });

    assert.deepEqual(loadCatalog(root).components, []);
  });

  it('rejects a duplicate id', () => {
    const root = makeRoot();
    addComponent(root, { name: 'One', metadata: meta({ name: 'One' }), source: swift('One') });
    addComponent(root, { name: 'Two', metadata: meta({ name: 'Two' }), source: swift('Two') });

    assert.match(loadCatalog(root).errors.join('\n'), /id "glow-button" is also used/);
  });

  it('rejects a file name used twice', () => {
    const root = makeRoot();
    const first = addComponent(root, { name: 'One', metadata: meta({ id: 'one', name: 'One' }), source: swift('One') });
    const second = addComponent(root, { name: 'Two', metadata: meta({ id: 'two', name: 'Two' }), source: swift('Two') });
    writeFileSync(join(first, 'Shared.swift'), '');
    writeFileSync(join(second, 'Shared.swift'), '');

    assert.match(loadCatalog(root).errors.join('\n'), /file name Shared\.swift is also used/);
  });
});

describe('invalid previews', () => {
  it('rejects a component without one', () => {
    assertRejected({ preview: null }, /missing GlowButton\.webp/);
  });

  it('allows a new component without one when asked to', () => {
    const root = makeRoot();
    addComponent(root, { preview: null });

    const { components, errors } = loadCatalog(root, { requirePreview: false });

    assert.deepEqual(errors, []);
    assert.equal(components.length, 1);
  });

  it('still rejects an invalid one when it is not required', () => {
    const root = makeRoot();
    addComponent(root, { preview: Buffer.from('GIF89a') });

    assert.match(loadCatalog(root, { requirePreview: false }).errors.join('\n'), /is not an animated WebP/);
  });

  it('rejects a file that is not WebP', () => {
    assertRejected({ preview: Buffer.from('GIF89a') }, /is not an animated WebP/);
  });

  it('rejects a still WebP', () => {
    assertRejected({ preview: Buffer.from('RIFF\0\0\0\0WEBPVP8 ') }, /is not an animated WebP/);
  });

  it('rejects a file over the size limit', () => {
    const preview = Buffer.concat([animatedWebP(), Buffer.alloc(2 * 1024 * 1024)]);

    assertRejected({ preview }, /is larger than 2 MB/);
  });

  it('leaves the component out of the catalog', () => {
    const root = makeRoot();
    addComponent(root, { preview: null });

    assert.deepEqual(loadCatalog(root).components, []);
  });
});

describe('invalid source', () => {
  it('rejects a missing MIT header', () => {
    assertRejected({ source: 'import SwiftUI\nstruct GlowButtonDemo {}\n#Preview {}\n' }, /first line must be/);
  });

  it('rejects another license on original work', () => {
    const source = swift().replace('MIT', 'Apache-2.0');

    assertRejected({ source }, /first line must be/);
  });

  it('allows the original license on adapted code', () => {
    const origin = { kind: 'adapted', url: 'https://x.dev', license: 'Apache-2.0' };
    const source = swift().replace('MIT', 'Apache-2.0');

    assert.deepEqual(errorsFor({ metadata: meta({ origin }), source }), []);
  });

  it('rejects a number written four times outside the demo', () => {
    const source = swift('GlowButton', 'let insets = [12, 12, 12, 12]');

    assertRejected({ source }, /12 is written 4 or more times outside the demo/);
  });

  it('allows a number that repeats only in the demo', () => {
    const source = swift().replace('struct GlowButtonDemo', '// MARK: - Demo\nlet insets = [12, 12, 12, 12]\nstruct GlowButtonDemo');

    assert.deepEqual(errorsFor({ source }), []);
  });

  it('allows a number that has a name', () => {
    const source = swift('GlowButton', 'private let inset = 12.0\nlet insets = [inset, inset, 12, 12, 12]');

    assert.deepEqual(errorsFor({ source }), []);
  });

  it('allows the numbers that say nothing more with a name', () => {
    const source = swift('GlowButton', 'let turns = [0, 0, 0, 0, 2, 2, 2, 2, 0.5, 0.5, 0.5, 0.5, 360, 360, 360, 360]');

    assert.deepEqual(errorsFor({ source }), []);
  });

  it('rejects a missing demo', () => {
    assertRejected({ source: '// SPDX-License-Identifier: MIT\n#Preview {}\n' }, /missing struct GlowButtonDemo/);
  });

  it('rejects a missing preview', () => {
    assertRejected({ source: '// SPDX-License-Identifier: MIT\nstruct GlowButtonDemo {}\n' }, /missing #Preview/);
  });

  it('rejects a newer minimum without @available', () => {
    assertRejected({ metadata: meta({ minIOS: '26.0' }) }, /no matching @available/);
  });

  it('rejects @available for another version', () => {
    const source = swift('GlowButton', '@available(iOS 26, *)\nstruct Glass {}');

    assertRejected({ metadata: meta({ minIOS: '27.0' }), source }, /no matching @available/);
  });

  it('requires the minor version when it is not zero', () => {
    const source = swift('GlowButton', '@available(iOS 27, *)\nstruct Glass {}');

    assertRejected({ metadata: meta({ minIOS: '27.2' }), source }, /no matching @available/);
  });

  const bannedCode = [
    ['ObservableObject', 'final class Model: ObservableObject {}', /uses ObservableObject/],
    ['@StateObject', '@StateObject var model = Model()', /uses @StateObject/],
    ['@ObservedObject', '@ObservedObject var model: Model', /uses @ObservedObject/],
    ['@Published', '@Published var value = 0', /uses @Published/],
    ['XCTest', 'import XCTest', /imports XCTest/],
    ['public declarations', 'public struct Glow {}', /declares something public/],
  ];

  for (const [label, code, expected] of bannedCode) {
    it(`rejects ${label}`, () => {
      assertRejected({ source: swift('GlowButton', code) }, expected);
    });
  }
});

describe('a component with a shader', () => {
  function outputsFor(shader = metal()) {
    const root = makeRoot();
    addComponent(root, { source: swiftWithShader(), shader });
    const { components, errors } = loadCatalog(root);
    assert.deepEqual(errors, []);
    return renderOutputs(root, components);
  }

  it('records the path and the URL of its shader', () => {
    const [entry] = JSON.parse(outputsFor().get('catalog.json')).components;

    assert.equal(entry.shader, 'Components/Buttons/GlowButton/GlowButton.metal');
    assert.match(entry.shaderRawURL, /\/HEAD\/Components\/Buttons\/GlowButton\/GlowButton\.metal$/);
    assert.equal(entry.shaderSource, undefined);
  });

  it('links its shader in the short index', () => {
    assert.match(
      outputsFor().get('llms.txt'),
      /Glow Button.*Copy its shader too: \[GlowButton\.metal\]\(https:\/\/raw\.githubusercontent\.com\/[^)]+\/GlowButton\.metal\)/,
    );
  });

  it('adds the code of its shader to the full index', () => {
    const full = outputsFor().get('llms-full.txt');

    assert.match(full, /Shader: Components\/Buttons\/GlowButton\/GlowButton\.metal/);
    assert.match(full, /```metal\n\/\/ SPDX-License-Identifier: MIT\n#include <SwiftUI\/SwiftUI_Metal\.h>/);
    assert.ok(full.indexOf('```swift') < full.indexOf('```metal'));
  });

  it('links its shader on the page of its category', () => {
    assert.match(
      outputsFor().get('catalog/Buttons.md'),
      /\[Glow Button\]\(\.\.\/Components\/Buttons\/GlowButton\/GlowButton\.swift\) and its \[shader\]\(\.\.\/Components\/Buttons\/GlowButton\/GlowButton\.metal\)/,
    );
  });

  it('may define helpers and types next to its functions', () => {
    const shader = metal(
      [
        '#define SCALE(value) { value * 2.0 }',
        'struct GlowButtonLight { float2 position; };',
        'static float GlowButtonNoise(float2 point) {',
        '    if (point.x > 0.0) { return sin(point.x); }',
        '    return fract(point.y);',
        '}',
        '// float Comment(float value) { return value; }',
        '/* float Block(float value) { return value; } */',
        '[[ stitchable ]] half4 GlowButtonTint(',
        '    float2 position,',
        '    half4 color',
        ') {',
        '    return color * half(GlowButtonNoise(position));',
        '}',
      ].join('\n'),
    );

    outputsFor(shader);
  });

  it('keeps the license of adapted code on its shader', () => {
    const root = makeRoot();
    const origin = { kind: 'adapted', url: 'https://x.dev', license: 'Apache-2.0' };
    addComponent(root, {
      metadata: meta({ origin }),
      source: swiftWithShader().replace('MIT', 'Apache-2.0'),
      shader: metal().replace('MIT', 'Apache-2.0'),
    });

    assert.deepEqual(loadCatalog(root).errors, []);
  });
});

describe('invalid shaders', () => {
  function assertShaderRejected(shader, expected, source = swiftWithShader()) {
    assertRejected({ source, shader }, expected);
  }

  it('rejects a missing MIT header', () => {
    assertShaderRejected(metal().replace('// SPDX-License-Identifier: MIT\n', ''), /first line of GlowButton\.metal must be/);
  });

  it('rejects a function without the name of the component', () => {
    assertShaderRejected(
      metal('[[ stitchable ]] half4 Tint(float2 position, half4 color) {\n    return color;\n}'),
      /function Tint in GlowButton\.metal must start with GlowButton/,
    );
  });

  it('rejects a helper without the name of the component', () => {
    const helper = 'static float noise(float2 point) {\n    return fract(point.x);\n}';

    assertShaderRejected(metal(`${helper}\n\n${SHADER_FUNCTION}`), /function noise in GlowButton\.metal must start with GlowButton/);
  });

  it('rejects a shader without functions', () => {
    assertShaderRejected(metal('struct GlowButtonLight { float2 position; };'), /GlowButton\.metal defines no function/);
  });

  it('rejects Swift that does not name its shader', () => {
    assertShaderRejected(metal(), /GlowButton\.swift must say that GlowButton\.metal is copied with it/, swift());
  });

  it('rejects a shader named after something else', () => {
    const root = makeRoot();
    const directory = addComponent(root);
    writeFileSync(join(directory, 'Tint.metal'), metal());

    assert.match(loadCatalog(root).errors.join('\n'), /Tint\.metal must be named GlowButton\.metal/);
  });

  it('rejects a second shader', () => {
    const root = makeRoot();
    const directory = addComponent(root, { source: swiftWithShader(), shader: metal() });
    writeFileSync(join(directory, 'GlowButtonExtra.metal'), metal());

    assert.match(loadCatalog(root).errors.join('\n'), /GlowButtonExtra\.metal must be named GlowButton\.metal/);
  });

  it('leaves the component out of the catalog', () => {
    const root = makeRoot();
    addComponent(root, { source: swift(), shader: metal() });

    assert.deepEqual(loadCatalog(root).components, []);
  });
});

describe('the Showcase registry', () => {
  const REGISTRY = 'Showcase/Showcase/Generated/ComponentRegistry.swift';

  function registryFor(metadata = meta()) {
    const root = makeRoot();
    addComponent(root, {
      metadata,
      source: swift('GlowButton', metadata.minIOS === '18.0' ? '' : `@available(iOS ${metadata.minIOS}, *)\nstruct Glass {}`),
    });
    const { components, errors } = loadCatalog(root);
    assert.deepEqual(errors, []);
    return renderOutputs(root, components).get(REGISTRY);
  }

  it('is an empty list when there are no components', () => {
    const registry = renderOutputs(makeRoot(), []).get(REGISTRY);

    assert.match(registry, /static let entries: \[ShowcaseEntry\] = \[\]/);
  });

  it('calls the demo directly at the baseline', () => {
    const registry = registryFor();

    assert.match(registry, /demo: \{ AnyView\(GlowButtonDemo\(\)\) \}/);
    assert.doesNotMatch(registry, /#available/);
  });

  it('gates the demo of a newer component', () => {
    const registry = registryFor(meta({ minIOS: '26.0' }));

    assert.match(registry, /guard #available\(iOS 26\.0, \*\) else \{ return nil \}/);
    assert.match(registry, /return AnyView\(GlowButtonDemo\(\)\)/);
  });

  it('includes the keywords of both languages', () => {
    assert.match(registryFor(), /keywords: \["button", "boton"\]/);
  });

  it('escapes quotes in the text', () => {
    assert.match(registryFor(meta({ summary: 'A "glowing" button.' })), /summary: "A \\"glowing\\" button\."/);
  });
});

describe('recording a preview', () => {
  it('waits a few seconds for a demo that animates by itself', () => {
    assert.deepEqual(previewPlan({}), { record: true, steps: ['sleep 4'] });
  });

  it('follows the given steps', () => {
    assert.deepEqual(previewPlan({ previewSteps: ['tap --label Like'] }), { record: true, steps: ['tap --label Like'] });
  });

  it('leaves a manual preview alone', () => {
    assert.deepEqual(previewPlan({ previewManual: true }), { record: false });
  });

  it('accepts the recording fields in the metadata', () => {
    assert.deepEqual(errorsFor({ metadata: meta({ previewSteps: ['sleep 1'] }) }), []);
    assert.deepEqual(errorsFor({ metadata: meta({ previewManual: true }) }), []);
  });

  it('rejects invalid recording fields', () => {
    assertRejected({ metadata: meta({ previewSteps: [] }) }, /"previewSteps" must be/);
    assertRejected({ metadata: meta({ previewManual: false }) }, /"previewManual" can only be true/);
  });

  for (const [field, value] of [['previewSteps', ['sleep 1']], ['previewManual', true]]) {
    it(`keeps ${field} out of the public catalog`, () => {
      const root = makeRoot();
      addComponent(root, { metadata: meta({ [field]: value }) });

      const [entry] = JSON.parse(renderOutputs(root, loadCatalog(root).components).get('catalog.json')).components;

      assert.equal(entry[field], undefined);
    });
  }

  it('picks the booted simulator with the newest iOS', () => {
    const devices = {
      'com.apple.CoreSimulator.SimRuntime.iOS-18-5': [{ udid: 'old' }],
      'com.apple.CoreSimulator.SimRuntime.iOS-27-2': [{ udid: 'new' }],
      'com.apple.CoreSimulator.SimRuntime.watchOS-27-0': [{ udid: 'watch' }],
    };

    assert.deepEqual(newestSimulator(devices), { udid: 'new', version: [27, 2] });
  });

  it('finds no simulator when none is booted', () => {
    assert.equal(newestSimulator({}), null);
  });

  const supported = [
    [[27, 2], '27.0', true],
    [[27, 0], '27.0', true],
    [[26, 5], '27.0', false],
    [[18, 5], '26.0', false],
    [[27, 0], '27.2', false],
  ];

  for (const [version, minIOS, expected] of supported) {
    it(`${expected ? 'allows' : 'refuses'} iOS ${minIOS} on a ${version.join('.')} simulator`, () => {
      assert.equal(simulatorSupports(version, minIOS), expected);
    });
  }
});

describe('components for an older SDK', () => {
  const versions = [
    ['18.0', false],
    ['26.0', false],
    ['26.4', false],
    ['27.0', true],
    ['27.2', true],
  ];

  for (const [minIOS, expected] of versions) {
    it(`${expected ? 'selects' : 'keeps'} iOS ${minIOS} when the SDK stops at 26`, () => {
      assert.equal(componentsNewerThan([{ minIOS }], 26).length, expected ? 1 : 0);
    });
  }
});

describe('the documentation site', () => {
  const INDEX = 'docs/src/content/docs/catalog/index.mdx';
  const PAGE = 'docs/src/content/docs/catalog/Buttons/glow-button.md';

  function docsFor(metadata = meta(), source = swift()) {
    const root = makeRoot();
    addComponent(root, { metadata, source });
    const { components, errors } = loadCatalog(root);
    assert.deepEqual(errors, []);
    return { pages: renderDocsPages(components), assets: docsAssets() };
  }

  it('says so when the catalog is empty', () => {
    const pages = renderDocsPages([]);

    assert.deepEqual([...pages.keys()], [INDEX]);
    assert.match(pages.get(INDEX), /No components yet\./);
    assert.doesNotMatch(pages.get(INDEX), /CatalogGallery/);
  });

  function galleryItems(index) {
    const lines = index.split('\n').filter((line) => line.startsWith('    {'));
    return lines.map((line) => JSON.parse(line.slice(0, -1)));
  }

  it('gives the gallery what it shows and what it filters by', () => {
    const index = docsFor().pages.get(INDEX);

    assert.match(index, /import CatalogGallery from '\.\.\/\.\.\/\.\.\/components\/CatalogGallery\.astro';/);
    assert.deepEqual(galleryItems(index), [
      {
        title: 'Glow Button',
        summary: 'A button that glows.',
        preview:
          'https://raw.githubusercontent.com/magnoscg/swiftui-components/HEAD/Components/Buttons/GlowButton/GlowButton.webp',
        href: '/swiftui-components/catalog/buttons/glow-button/',
        category: 'Buttons',
        minIOS: '18.0',
        difficulty: 'beginner',
        keywords: 'button boton',
      },
    ]);
  });

  it('keeps braces in the text from being read as MDX', () => {
    const index = docsFor(meta({ summary: 'Uses {braces} and <tags>.' })).pages.get(INDEX);

    assert.equal(galleryItems(index)[0].summary, 'Uses {braces} and <tags>.');
  });

  it('gives each component a page with its keywords and source', () => {
    const page = docsFor().pages.get(PAGE);

    assert.match(page, /^---\ntitle: "Glow Button"\ndescription: "A button that glows\."\n---/);
    assert.match(
      page,
      /<img src="https:\/\/raw\.githubusercontent\.com\/magnoscg\/swiftui-components\/HEAD\/Components\/Buttons\/GlowButton\/GlowButton\.webp"/,
    );
    assert.match(page, /\| Keywords \| button, boton \|/);
    assert.match(page, /\| Minimum iOS \| 18\.0 \|/);
    assert.match(page, /`````swift title="GlowButton\.swift"\n\/\/ SPDX-License-Identifier: MIT/);
  });

  it('offers one file to copy when there is no shader', () => {
    const page = docsFor().pages.get(PAGE);

    assert.match(page, /Copy this code into your project, or \[download the file\]\(/);
    assert.equal(page.match(/^`````\w/gm).length, 1);
  });

  it('shows the shader as a second file to copy', () => {
    const root = makeRoot();
    addComponent(root, { source: swiftWithShader(), shader: metal() });
    const page = renderDocsPages(loadCatalog(root).components).get(PAGE);

    assert.match(page, /Copy both files into your project/);
    assert.match(page, /\[GlowButton\.swift\]\([^)]+\/GlowButton\.swift\) and \[GlowButton\.metal\]\([^)]+\/GlowButton\.metal\)/);
    assert.match(page, /`````swift title="GlowButton\.swift"\n\/\/ SPDX-License-Identifier: MIT/);
    assert.match(page, /`````cpp title="GlowButton\.metal"\n\/\/ SPDX-License-Identifier: MIT\n#include/);
    assert.ok(page.indexOf('title="GlowButton.swift"') < page.indexOf('title="GlowButton.metal"'));
  });

  it('escapes HTML in the text of a page', () => {
    const page = docsFor(meta({ summary: 'A <b> tag.' })).pages.get(PAGE);

    assert.match(page, /\nA &lt;b&gt; tag\.\n/);
  });

  const origins = [
    ['original work', { kind: 'original' }, /\| Origin \| Original \|/],
    [
      'linked inspiration',
      { kind: 'inspired', credit: 'A talk', url: 'https://x.dev' },
      /\| Origin \| Inspired by \[A talk\]\(https:\/\/x\.dev\) \|/,
    ],
    [
      'adapted code',
      { kind: 'adapted', url: 'https://x.dev', license: 'Apache-2.0' },
      /\| Origin \| Adapted from \[the source\]\(https:\/\/x\.dev\), Apache-2\.0 \|/,
    ],
  ];

  for (const [label, origin, expected] of origins) {
    it(`states ${label}`, () => {
      const source = origin.kind === 'adapted' ? swift().replace('MIT', 'Apache-2.0') : swift();

      assert.match(docsFor(meta({ origin }), source).pages.get(PAGE), expected);
    });
  }

  it('copies the indexes into the site and leaves the previews out', () => {
    const { assets } = docsFor();

    assert.equal(assets.get('llms.txt'), 'docs/public/llms.txt');
    assert.equal(assets.get('catalog.json'), 'docs/public/catalog.json');
    assert.equal(assets.has('Components/Buttons/GlowButton/GlowButton.webp'), false);
  });
});

describe('generated files', () => {
  it('fails clearly when the README has no markers', () => {
    const root = makeRoot('No markers\n');

    assert.throws(() => renderOutputs(root, []), /must contain <!-- catalog:start -->/);
  });

  it('reports the leftover page of a removed category as stale', () => {
    const root = makeRoot();
    mkdirSync(join(root, 'catalog'));
    writeFileSync(join(root, 'catalog/Old.md'), 'gone');
    writeFileSync(join(root, 'catalog/Kept.md'), 'same');
    const outputs = new Map([['catalog/Kept.md', 'same']]);

    assert.deepEqual(findStale(root, outputs), ['catalog/Old.md']);
  });

  it('reports missing and outdated files as stale', () => {
    const root = makeRoot();
    writeFileSync(join(root, 'current.txt'), 'same');
    writeFileSync(join(root, 'old.txt'), 'before');
    const outputs = new Map([
      ['current.txt', 'same'],
      ['old.txt', 'after'],
      ['missing.txt', 'new'],
    ]);

    assert.deepEqual(findStale(root, outputs), ['old.txt', 'missing.txt']);
  });

  it('renders the same output twice', () => {
    const root = makeRoot();
    addComponent(root);
    const { components } = loadCatalog(root);
    const first = renderOutputs(root, components);
    for (const [path, content] of first) {
      mkdirSync(dirname(join(root, path)), { recursive: true });
      writeFileSync(join(root, path), content);
    }

    const second = renderOutputs(root, loadCatalog(root).components);

    assert.deepEqual([...second], [...first]);
    assert.deepEqual(findStale(root, second), []);
  });
});
