import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, describe, it } from 'node:test';
import { findStale, loadCatalog, renderOutputs } from './catalog-lib.mjs';

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

function addComponent(root, { category = 'Buttons', name = 'GlowButton', metadata = meta(), source = swift(name) } = {}) {
  const directory = join(root, 'Components', category, name);
  mkdirSync(directory, { recursive: true });
  if (metadata !== null) {
    const text = typeof metadata === 'string' ? metadata : JSON.stringify(metadata);
    writeFileSync(join(directory, `${name}.meta.json`), text);
  }
  if (source !== null) writeFileSync(join(directory, `${name}.swift`), source);
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
    assert.match(entry.rawURL, /\/HEAD\/Components\/Buttons\/GlowButton\/GlowButton\.swift$/);
    assert.match(outputs.get('llms.txt'), /Glow Button.*iOS 18\.0\+.*button, boton/);
    assert.match(outputs.get('llms-full.txt'), /```swift\n\/\/ SPDX-License-Identifier: MIT/);
    assert.match(outputs.get('README.md'), /### Buttons/);
    assert.match(outputs.get('README.md'), /\| \[Glow Button\]\(Components\/Buttons\/GlowButton\/GlowButton\.swift\)/);
  });

  it('keeps the README outside the markers', () => {
    const root = makeRoot();
    addComponent(root);

    const readme = renderOutputs(root, loadCatalog(root).components).get('README.md');

    assert.ok(readme.startsWith('Intro\n'));
    assert.ok(readme.endsWith('<!-- catalog:end -->\n\nOutro\n'));
    assert.doesNotMatch(readme, /old/);
  });

  it('escapes pipes in the README table', () => {
    const root = makeRoot();
    addComponent(root, { metadata: meta({ summary: 'One | two.' }) });

    const readme = renderOutputs(root, loadCatalog(root).components).get('README.md');

    assert.match(readme, /One \\\| two\./);
  });

  it('records a preview only when the gif exists', () => {
    const root = makeRoot();
    const directory = addComponent(root);
    assert.equal(loadCatalog(root).components[0].preview, null);

    writeFileSync(join(directory, 'GlowButton.gif'), '');

    assert.equal(loadCatalog(root).components[0].preview, 'Components/Buttons/GlowButton/GlowButton.gif');
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
    ['inspiration without credit', { origin: { kind: 'inspired' } }, /"origin\.credit"/],
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

describe('generated files', () => {
  it('fails clearly when the README has no markers', () => {
    const root = makeRoot('No markers\n');

    assert.throws(() => renderOutputs(root, []), /must contain <!-- catalog:start -->/);
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
    for (const [path, content] of first) writeFileSync(join(root, path), content);

    const second = renderOutputs(root, loadCatalog(root).components);

    assert.deepEqual([...second], [...first]);
    assert.deepEqual(findStale(root, second), []);
  });
});
