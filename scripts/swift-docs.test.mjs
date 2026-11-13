import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, it } from 'node:test';
import { componentDocs } from './swift-docs.mjs';

const HEADER = '// SPDX-License-Identifier: MIT\n\nimport SwiftUI\n\n';

function file(body, name = 'GlowButton') {
  return `${HEADER}${body}\n// MARK: - Demo\n\nstruct ${name}Demo: View {\n    var body: some View { ${name}(title: "Hi") }\n}\n\n#Preview {\n    ${name}Demo()\n}\n`;
}

describe('the overview of a component', () => {
  it('reads the comment of the main type past its attributes', () => {
    const docs = componentDocs(
      file('/// A button that glows.\n///\n/// It dims with Reduce Motion on.\n@available(iOS 26.0, *)\nstruct GlowButton: View {\n    let title: String\n}\n'),
      'GlowButton',
    );

    assert.deepEqual(docs.overview, [
      { type: 'paragraph', text: 'A button that glows.' },
      { type: 'paragraph', text: 'It dims with Reduce Motion on.' },
    ]);
  });

  it('joins the lines of a paragraph and keeps lists and callouts apart', () => {
    const docs = componentDocs(
      file(
        [
          '/// A button that glows',
          '/// around its edge.',
          '///',
          '/// - It pulses while pressed.',
          '/// - It stops when released.',
          '///',
          '/// - Important: Copy `GlowButton.metal` too,',
          '///   in the same target.',
          '/// - Note: Uses ``GlowButtonStyle``.',
          '/// - Warning: Heavy.',
          '/// - Parameters:',
          '///   - title: The text.',
          '/// - Returns: Nothing.',
          'struct GlowButton: View {',
          '    let title: String',
          '}',
        ].join('\n'),
      ),
      'GlowButton',
    );

    assert.deepEqual(docs.overview, [
      { type: 'paragraph', text: 'A button that glows around its edge.' },
      { type: 'list', items: ['It pulses while pressed.', 'It stops when released.'] },
      { type: 'aside', variant: 'caution', title: 'Important', text: 'Copy `GlowButton.metal` too, in the same target.' },
      { type: 'aside', variant: 'note', title: 'Note', text: 'Uses ``GlowButtonStyle``.' },
      { type: 'aside', variant: 'danger', title: 'Warning', text: 'Heavy.' },
    ]);
  });

  it('takes the comment of the modifier when the type is a ViewModifier', () => {
    const docs = componentDocs(
      file(
        [
          'extension View {',
          '    /// Wobbles the view.',
          '    func jiggle(_ isActive: Bool, amplitude: Double = 2.4) -> some View {',
          '        modifier(Jiggle(isActive: isActive, amplitude: amplitude))',
          '    }',
          '}',
          '',
          '/// With Reduce Motion on, the view stays still.',
          'struct Jiggle: ViewModifier {',
          '    var isActive: Bool',
          '    var amplitude: Double',
          '}',
        ].join('\n'),
        'Jiggle',
      ),
      'Jiggle',
    );

    assert.deepEqual(docs.overview, [{ type: 'paragraph', text: 'Wobbles the view.' }]);
  });

  it('takes the comment of the modifier when there is no main type', () => {
    const docs = componentDocs(
      file('extension View {\n    /// Pixelates the view.\n    func pixelate(amount: Double) -> some View {\n        self\n    }\n}\n', 'Pixelate'),
      'Pixelate',
    );

    assert.deepEqual(docs.overview, [{ type: 'paragraph', text: 'Pixelates the view.' }]);
  });

  it('has no overview when nothing is documented', () => {
    const docs = componentDocs(file('struct GlowButton: View {\n    let title: String\n}\n'), 'GlowButton');

    assert.equal(docs.overview, null);
  });
});

describe('the usage of a component', () => {
  it('is its demo section, with the helpers it declares and without the preview', () => {
    const source = `${HEADER}struct Stack: View {}\n\n// MARK: - Demo\n\nprivate struct DemoPlace {\n    let name: String\n}\n\nstruct StackDemo: View {\n    var body: some View { Stack() }\n}\n\n#Preview {\n    StackDemo()\n}\n`;

    const docs = componentDocs(source, 'Stack');

    assert.equal(
      docs.usage,
      'private struct DemoPlace {\n    let name: String\n}\n\nstruct StackDemo: View {\n    var body: some View { Stack() }\n}',
    );
  });
});

describe('the API of a component', () => {
  it('lists what a caller sets on the main type and leaves out the rest', () => {
    const docs = componentDocs(
      file(
        [
          'struct GlowButton<Label: View>: View {',
          '    /// The text it shows.',
          '    let title: LocalizedStringResource',
          '    var tint: Color = .indigo',
          '    var isLoud = true',
          '    var reach = 80',
          '    var scale = 1.5',
          '    var name = "Glow"',
          '    var colors: [Color] = [',
          '        .red,',
          '        .blue,',
          '    ]',
          '    @Binding var isOn: Bool',
          '    @ViewBuilder var label: () -> Label',
          '    let action: () -> Void',
          '    let fixed = 3',
          '    static var shared = 1',
          '    private var hidden = 0',
          '    @State private var pressed = false',
          '    @Environment(\\.accessibilityReduceMotion) private var reduceMotion',
          '    var computed: Double { 1 }',
          '    var body: some View {',
          '        let inner = 2',
          '        Text(title)',
          '    }',
          '}',
        ].join('\n'),
      ),
      'GlowButton',
    );

    assert.deepEqual(docs.api, [
      {
        title: null,
        rows: [
          { name: 'title', type: 'LocalizedStringResource', default: null, description: 'The text it shows.' },
          { name: 'tint', type: 'Color', default: '.indigo', description: '' },
          { name: 'isLoud', type: 'Bool', default: 'true', description: '' },
          { name: 'reach', type: 'Int', default: '80', description: '' },
          { name: 'scale', type: 'Double', default: '1.5', description: '' },
          { name: 'name', type: 'String', default: '"Glow"', description: '' },
          { name: 'colors', type: '[Color]', default: '[.red, .blue]', description: '' },
          { name: 'isOn', type: 'Binding<Bool>', default: null, description: '' },
          { name: 'label', type: '() -> Label', default: null, description: '' },
          { name: 'action', type: '() -> Void', default: null, description: '' },
        ],
      },
    ]);
  });

  it('takes a type from an initializer and leaves one it cannot tell empty', () => {
    const docs = componentDocs(
      file('struct GlowButton: View {\n    var size = CGSize(width: 1, height: 2)\n    var rules = GlowButtonRule.defaults\n}\n'),
      'GlowButton',
    );

    assert.deepEqual(docs.api[0].rows, [
      { name: 'size', type: 'CGSize', default: 'CGSize(width: 1, height: 2)', description: '' },
      { name: 'rules', type: '', default: 'GlowButtonRule.defaults', description: '' },
    ]);
  });

  it('prefers the initializers, also those in extensions, with their documented parameters', () => {
    const docs = componentDocs(
      file(
        [
          'struct GlowButton<Label: View>: View {',
          '    let action: () -> Void',
          '    let label: Label',
          '',
          '    /// Creates a button.',
          '    ///',
          '    /// - Parameters:',
          '    ///   - action: What a tap runs.',
          '    ///   - label: What it shows,',
          '    ///     in any view.',
          '    init(',
          '        action: @escaping () -> Void,',
          '        @ViewBuilder label: () -> Label',
          '    ) {',
          '        self.action = action',
          '        self.label = label()',
          '    }',
          '',
          '    private init(other: Int) {}',
          '}',
          '',
          'extension GlowButton where Label == Text {',
          '    /// - Parameter title: The text.',
          '    init(_ title: LocalizedStringResource, tint: Color = .blue, action: @escaping () -> Void) {',
          '        self.init(action: action) { Text(title) }',
          '    }',
          '}',
        ].join('\n'),
      ),
      'GlowButton',
    );

    assert.deepEqual(docs.api, [
      {
        title: 'init(action:label:)',
        rows: [
          { name: 'action', type: '@escaping () -> Void', default: null, description: 'What a tap runs.' },
          { name: 'label', type: '() -> Label', default: null, description: 'What it shows, in any view.' },
        ],
      },
      {
        title: 'init(_:tint:action:)',
        rows: [
          { name: 'title', type: 'LocalizedStringResource', default: null, description: 'The text.' },
          { name: 'tint', type: 'Color', default: '.blue', description: '' },
          { name: 'action', type: '@escaping () -> Void', default: null, description: '' },
        ],
      },
    ]);
  });

  it('reads a modifier from its function, where its defaults are', () => {
    const docs = componentDocs(
      file(
        [
          'extension View {',
          '    /// Wobbles the view.',
          '    ///',
          '    /// - Parameter seed: Keeps views out of step.',
          '    func jiggle(_ isActive: Bool, amplitude: Double = 2.4, seed: Int = 0) -> some View {',
          '        modifier(Jiggle(isActive: isActive, amplitude: amplitude, seed: seed))',
          '    }',
          '}',
          '',
          'struct Jiggle: ViewModifier {',
          '    var isActive: Bool',
          '    var amplitude: Double',
          '    var seed: Int',
          '}',
        ].join('\n'),
        'Jiggle',
      ),
      'Jiggle',
    );

    assert.deepEqual(docs.api, [
      {
        title: 'jiggle(_:amplitude:seed:)',
        rows: [
          { name: 'isActive', type: 'Bool', default: null, description: '' },
          { name: 'amplitude', type: 'Double', default: '2.4', description: '' },
          { name: 'seed', type: 'Int', default: '0', description: 'Keeps views out of step.' },
        ],
      },
    ]);
  });

  it('follows the memberwise initializer: an optional var defaults to nil and a built view is a closure', () => {
    const docs = componentDocs(
      file(
        [
          'struct GlowButton<Content: View>: View {',
          '    var subtitle: String?',
          '    let badge: Int?',
          '    @Binding var selection: Int?',
          '    @ViewBuilder var content: Content',
          '}',
        ].join('\n'),
      ),
      'GlowButton',
    );

    assert.deepEqual(docs.api[0].rows, [
      { name: 'subtitle', type: 'String?', default: 'nil', description: '' },
      { name: 'badge', type: 'Int?', default: null, description: '' },
      { name: 'selection', type: 'Binding<Int?>', default: null, description: '' },
      { name: 'content', type: '() -> Content', default: null, description: '' },
    ]);
  });

  it('keeps generics apart from range and comparison operators in a signature', () => {
    const docs = componentDocs(
      file(
        'struct GlowButton: View {\n    init(range: Range<Double> = 0..<1, isOn: Bool = 1 > 0, tint: Color = .red) {}\n}\n',
      ),
      'GlowButton',
    );

    assert.deepEqual(
      docs.api[0].rows.map((row) => [row.name, row.type, row.default]),
      [
        ['range', 'Range<Double>', '0..<1'],
        ['isOn', 'Bool', '1 > 0'],
        ['tint', 'Color', '.red'],
      ],
    );
  });

  it('reads failable and nonisolated initializers, and gives no table when every initializer is private', () => {
    const failable = componentDocs(
      file('struct GlowButton: View {\n    nonisolated init(level: Int) {}\n    init?(name: String) {}\n}\n'),
      'GlowButton',
    );
    const hidden = componentDocs(
      file('struct GlowButton: View {\n    var level = 1\n    private init(level: Int) {}\n}\n'),
      'GlowButton',
    );

    assert.deepEqual(
      failable.api.map((table) => table.title),
      ['init(level:)', 'init(name:)'],
    );
    assert.deepEqual(hidden.api, []);
  });

  it('keeps the memberwise initializer when the only initializers are in extensions', () => {
    const docs = componentDocs(
      file(
        [
          'struct GlowButton<Controls: View>: View {',
          '    let title: String',
          '    @ViewBuilder var controls: Controls',
          '}',
          '',
          'extension GlowButton where Controls == EmptyView {',
          '    init(title: String) {',
          '        self.init(title: title) { EmptyView() }',
          '    }',
          '}',
        ].join('\n'),
      ),
      'GlowButton',
    );

    assert.deepEqual(
      docs.api.map((table) => [table.title, table.rows.map((row) => row.name)]),
      [
        [null, ['title', 'controls']],
        ['init(title:)', ['title']],
      ],
    );
  });

  it('reads a view its demo only shows through a modifier as that modifier', () => {
    const source = [
      HEADER,
      'extension View {',
      '    /// Shows a toast.',
      '    func toast(isPresented: Binding<Bool>, duration: Double = 2) -> some View {',
      '        overlay { Toast() }',
      '    }',
      '}',
      '',
      '/// The capsule the modifier shows.',
      'struct Toast: View {',
      '    var message = "Saved"',
      '}',
      '',
      '// MARK: - Demo',
      '',
      'struct ToastDemo: View {',
      '    @State private var shown = false',
      '    var body: some View { Text("Hi").toast(isPresented: $shown) }',
      '}',
      '',
      '#Preview {',
      '    ToastDemo()',
      '}',
    ].join('\n');

    const docs = componentDocs(source, 'Toast');

    assert.deepEqual(docs.overview, [{ type: 'paragraph', text: 'Shows a toast.' }]);
    assert.deepEqual(docs.api.map((table) => table.title), ['toast(isPresented:duration:)']);
  });

  it('has no table when the main type takes nothing', () => {
    const docs = componentDocs(file('struct GlowButton: View {\n    var body: some View { Text("Hi") }\n}\n'), 'GlowButton');

    assert.deepEqual(docs.api, []);
  });
});

describe('the components of the catalog', () => {
  const root = join(import.meta.dirname, '..', 'Components');
  const components = readdirSync(root).flatMap((category) =>
    readdirSync(join(root, category)).map((name) => ({
      name,
      source: readFileSync(join(root, category, name, `${name}.swift`), 'utf8'),
    })),
  );

  it('all have a usage and nearly all an overview', () => {
    const docs = components.map(({ name, source }) => ({ name, ...componentDocs(source, name) }));

    assert.deepEqual(
      docs.filter((doc) => !doc.usage?.includes(`struct ${doc.name}Demo`)).map((doc) => doc.name),
      [],
    );
    assert.deepEqual(docs.filter((doc) => doc.overview === null).map((doc) => doc.name), []);
  });

  // Checked by hand against each source: the title of each table, then its rows as name, type and default.
  const expected = {
    AsyncActionButton: [['init(action:label:)'], ['init(_:action:)'], ['init(_:systemImage:action:)']],
    ChatBubbleShape: [
      [
        'init(side:position:radius:tightRadius:)',
        ['side', 'ChatBubbleShapeSide', '.trailing'],
        ['position', 'ChatBubbleShapePosition', '.single'],
        ['radius', 'CGFloat', '18'],
        ['tightRadius', 'CGFloat', '5'],
      ],
    ],
    CoachMarkTour: [['coachMarkTourTarget(_:)'], ['coachMarkTour(steps:isPresented:onFinish:)']],
    DateStripPicker: [
      [
        'init(selection:center:daysBefore:daysAfter:calendar:tint:)',
        ['selection', 'Binding<Date>', null],
        ['center', 'Date', '.now'],
        ['daysBefore', 'Int', '30'],
        ['daysAfter', 'Int', '30'],
        ['calendar', 'Calendar', '.current'],
        ['tint', 'Color', '.indigo'],
      ],
    ],
    ElasticDragButton: [
      [
        null,
        ['systemImage', 'String', null],
        ['label', 'LocalizedStringResource', null],
        ['tint', 'Color', '.indigo'],
        ['reach', 'Double', '80'],
        ['action', '() -> Void', null],
      ],
    ],
    HolographicCard: [
      [
        null,
        ['maxAngle', 'Double', '16'],
        ['cornerRadius', 'CGFloat', '28'],
        ['intensity', 'Double', '1'],
        ['content', '() -> Content', null],
      ],
    ],
    JiggleEditModifier: [
      [
        'jiggleEditing(_:amplitude:seed:)',
        ['isActive', 'Bool', null],
        ['amplitude', 'Double', '2.4'],
        ['seed', 'Int', '0'],
      ],
    ],
    KanbanBoard: [
      ['init(columns:columnWidth:)', ['columns', 'Binding<[KanbanBoardColumn]>', null], ['columnWidth', 'CGFloat', '220']],
    ],
    PressableButtonStyle: [[null, ['pressedScale', 'CGFloat', '0.94'], ['pressedOpacity', 'Double', '0.8']]],
    ToastHost: [['toastHost()']],
    ShimmerButton: [
      [
        null,
        ['title', 'LocalizedStringResource', null],
        ['systemImage', 'String?', 'nil'],
        ['colors', '[Color]', '[.indigo, .purple]'],
        ['sweepDuration', 'Double', '1.1'],
        ['pause', 'Double', '0.9'],
        ['action', '() -> Void', null],
      ],
    ],
    BottomDrawer: [
      [
        null,
        ['detent', 'Binding<CGFloat>', null],
        ['detents', '[CGFloat]', '[0.16, 0.5, 0.88]'],
        ['content', '() -> Content', null],
      ],
    ],
    ToastBanner: [
      [
        'toast(isPresented:message:systemImage:tint:duration:)',
        ['isPresented', 'Binding<Bool>', null],
        ['message', 'LocalizedStringResource', null],
        ['systemImage', 'String', '"checkmark.circle.fill"'],
        ['tint', 'Color', '.green'],
        ['duration', 'Double', '2.2'],
      ],
    ],
  };

  for (const [name, tables] of Object.entries(expected)) {
    it(`reads the tables of ${name}`, () => {
      const { source } = components.find((component) => component.name === name);
      const api = componentDocs(source, name).api;

      assert.deepEqual(
        api.map((table) => table.title),
        tables.map(([title]) => title),
      );
      tables.forEach(([, ...rows], index) => {
        if (rows.length === 0) return;
        assert.deepEqual(
          api[index].rows.map((row) => [row.name, row.type, row.default]),
          rows,
        );
      });
    });
  }
});
