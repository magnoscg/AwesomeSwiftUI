// Reads from the Swift source of a component what its page on the site shows:
// the comment a caller reads first, the demo, and what a caller sets. It reads
// the layout every component keeps, not Swift in general: a form it does not
// recognize gives no table rather than a wrong one.

const DEMO_MARK = '// MARK: - Demo';
const ASIDES = { Important: 'caution', Note: 'note', Tip: 'tip', Warning: 'danger' };
const PARAMETER_CALLOUTS = /^- (?:Parameters?|Returns|Throws)\b/;
// Wrappers whose value the view owns, so no caller sets it.
const INITIALIZER = /^ {4}(?:(?:private|fileprivate|nonisolated|convenience|@\w+)\s+)*init[?!]?\s*[(<]/;
const OWNED_WRAPPERS = /@(?:State|Environment|GestureState|ScaledMetric|Namespace|FocusState|AppStorage|SceneStorage)\b/;

export function componentDocs(source, name) {
  const lines = source.split('\n');
  const demoStart = lines.findIndex((line) => line.trim() === DEMO_MARK);
  const declarations = demoStart === -1 ? lines : lines.slice(0, demoStart);
  const type = findType(declarations, name);
  const modifiers = modifierFunctions(declarations);
  const demo = demoStart === -1 ? '' : lines.slice(demoStart).join('\n');
  const isViewModifier = type && /\bViewModifier\b/.test(type.declaration);
  // A view its demo never builds is shown through its modifier first, like a
  // toast, and then as the view, which a caller can still place by itself.
  const showsThroughModifier =
    modifiers.length > 0 && type && !isViewModifier && !new RegExp(`\\b${name}\\s*[({]`).test(demo);
  const isModifier = modifiers.length > 0 && (!type || isViewModifier || showsThroughModifier);
  const modifierDoc = modifiers.find((modifier) => modifier.doc.length)?.doc;
  const doc = !isModifier
    ? type?.doc
    : showsThroughModifier
      ? [...(modifierDoc ?? []), ...(modifierDoc?.length && type.doc.length ? [''] : []), ...type.doc]
      : (modifierDoc ?? type?.doc);
  const viewTables = showsThroughModifier
    ? typeTables(declarations, type, name).map((table) => ({ ...table, title: table.title ?? name }))
    : [];
  return {
    overview: doc?.length ? overviewOf(doc) : null,
    usage: demoStart === -1 ? null : usageOf(lines, demoStart),
    api: isModifier ? [...modifiers.map(functionTable), ...viewTables] : typeTables(declarations, type, name),
  };
}

// MARK: - Comments

// The `///` lines right above a declaration, past its attributes, without the
// slashes and the one space after them.
function docAbove(lines, index) {
  let line = index - 1;
  while (line >= 0 && lines[line].trim().startsWith('@')) line -= 1;
  const doc = [];
  for (; line >= 0 && lines[line].trim().startsWith('///'); line -= 1) {
    doc.unshift(lines[line].trim().replace(/^\/\/\/ ?/, ''));
  }
  return doc;
}

function overviewOf(doc) {
  const blocks = [];
  let block = null;
  let skipping = false;
  const flush = () => {
    if (block) blocks.push(block);
    block = null;
  };

  for (const raw of doc) {
    const line = raw.trimEnd();
    const text = line.trim();
    if (!text) {
      flush();
      skipping = false;
      continue;
    }
    const callout = line.match(/^- (Important|Note|Tip|Warning):\s*(.*)$/);
    if (callout) {
      flush();
      skipping = false;
      block = { type: 'aside', variant: ASIDES[callout[1]], title: callout[1], text: callout[2] };
      continue;
    }
    if (PARAMETER_CALLOUTS.test(line)) {
      flush();
      skipping = true;
      continue;
    }
    if (skipping && /^\s/.test(line)) continue;
    skipping = false;

    if (line.startsWith('- ')) {
      if (block?.type !== 'list') {
        flush();
        block = { type: 'list', items: [] };
      }
      block.items.push(line.slice(2).trim());
    } else if (block?.type === 'aside') {
      block.text += ` ${text}`;
    } else if (block?.type === 'list' && /^\s/.test(line)) {
      block.items[block.items.length - 1] += ` ${text}`;
    } else if (block?.type === 'paragraph') {
      block.text += ` ${text}`;
    } else {
      flush();
      block = { type: 'paragraph', text };
    }
  }
  flush();
  return blocks.length ? blocks : null;
}

// What `- Parameters:` and `- Parameter name:` say about each parameter.
function parameterDocs(doc) {
  const docs = {};
  let current = null;
  let inList = false;
  for (const line of doc) {
    let match;
    if ((match = line.match(/^- Parameter (\w+):\s*(.*)$/))) {
      [, current] = match;
      docs[current] = match[2];
      inList = false;
    } else if (/^- Parameters:\s*$/.test(line)) {
      current = null;
      inList = true;
    } else if (inList && (match = line.match(/^\s+- (\w+):\s*(.*)$/))) {
      [, current] = match;
      docs[current] = match[2];
    } else if (current && /^\s+\S/.test(line)) {
      docs[current] += ` ${line.trim()}`;
    } else {
      current = null;
      if (!/^\s/.test(line)) inList = false;
    }
  }
  return docs;
}

function plainDoc(doc) {
  return doc.filter((line) => line.trim()).map((line) => line.trim()).join(' ');
}

// MARK: - Usage

function usageOf(lines, demoStart) {
  const end = lines.findIndex((line, index) => index > demoStart && line.startsWith('#Preview'));
  return lines
    .slice(demoStart + 1, end === -1 ? undefined : end)
    .join('\n')
    .replace(/^\s*\n/, '')
    .trimEnd();
}

// MARK: - Declarations

function findType(lines, name) {
  const pattern = new RegExp(`^(?:(?:@\\w+|nonisolated|final)\\s+)*(?:struct|class|enum|actor)\\s+${name}\\b`);
  const index = lines.findIndex((line) => pattern.test(line));
  if (index === -1) return null;
  return { index, declaration: lines[index], doc: docAbove(lines, index), end: blockEnd(lines, index) };
}

// The line that closes a top-level declaration: the first `}` at the start of a line.
function blockEnd(lines, start) {
  const end = lines.findIndex((line, index) => index > start && line.startsWith('}'));
  return end === -1 ? lines.length : end;
}

function modifierFunctions(lines) {
  const functions = [];
  lines.forEach((line, index) => {
    if (!/^extension View\b/.test(line)) return;
    for (let member = index + 1; member < blockEnd(lines, index); member += 1) {
      if (/^ {4}(?:@\w+\s+)*func \w+/.test(lines[member])) {
        functions.push({ ...signature(lines, member, /func (\w+)/), doc: docAbove(lines, member) });
      }
    }
  });
  return functions;
}

function typeTables(lines, type, name) {
  if (!type) return [];
  const extensions = lines.flatMap((line, index) =>
    new RegExp(`^extension ${name}\\b`).test(line) ? [[index, blockEnd(lines, index)]] : [],
  );
  const initializersIn = ([start, end]) => {
    const found = [];
    for (let member = start + 1; member < end; member += 1) {
      const line = lines[member];
      if (!INITIALIZER.test(line)) continue;
      found.push({ ...signature(lines, member, /(init)\b/), doc: docAbove(lines, member), hidden: /^\s*(?:private|fileprivate)\b/.test(line) });
    }
    return found;
  };
  const inBody = initializersIn([type.index, type.end]);
  const inExtensions = extensions.flatMap(initializersIn).filter((initializer) => !initializer.hidden);
  const visible = inBody.filter((initializer) => !initializer.hidden);
  // An initializer in the body takes the memberwise one away, even a private one.
  if (inBody.length) return [...visible, ...inExtensions].map(functionTable);

  const rows = storedProperties(lines, type);
  return [...(rows.length ? [{ title: null, rows }] : []), ...inExtensions.map(functionTable)];
}

// MARK: - Signatures

// The name and the parameters of a function or initializer that starts on a line.
function signature(lines, index, namePattern) {
  const text = lines.slice(index, index + 40).join('\n');
  const [, name] = text.match(namePattern);
  let open = text.indexOf(name) + name.length;
  if (text[open] === '<') open = closing(text, open, '<', '>') + 1;
  open = text.indexOf('(', open);
  const close = closing(text, open, '(', ')');
  return { name, parameters: splitTopLevel(text.slice(open + 1, close), ',').map(parameterOf).filter(Boolean) };
}

function closing(text, start, open, close) {
  let depth = 0;
  for (let index = start; index < text.length; index += 1) {
    if (text[index] === '-' && text[index + 1] === '>') {
      index += 1;
    } else if (text[index] === open) {
      depth += 1;
    } else if (text[index] === close) {
      depth -= 1;
      if (depth === 0) return index;
    }
  }
  return text.length;
}

// Splits at a separator that is outside brackets, generics and strings, and is
// not part of `->` or of an operator such as `==`. A `<` opens a generic only
// right after a name, so `0..<1` and `1 > 0` are not taken for one.
function splitTopLevel(text, separator) {
  const parts = [];
  let depth = 0;
  let generics = 0;
  let quoted = false;
  let start = 0;
  for (let index = 0; index < text.length; index += 1) {
    const character = text[index];
    if (quoted) {
      if (character === '\\') index += 1;
      else if (character === '"') quoted = false;
    } else if (character === '"') {
      quoted = true;
    } else if (character === '-' && text[index + 1] === '>') {
      index += 1;
    } else if (character === '<' && /\w/.test(text[index - 1] ?? '')) {
      generics += 1;
    } else if (character === '>' && generics > 0) {
      generics -= 1;
    } else if ('([{'.includes(character)) {
      depth += 1;
    } else if (')]}'.includes(character)) {
      depth -= 1;
    } else if (
      depth === 0 &&
      generics === 0 &&
      character === separator &&
      !(separator === '=' && /[=!<>]/.test(text[index - 1] ?? '')) &&
      !(separator === '=' && text[index + 1] === '=')
    ) {
      parts.push(text.slice(start, index));
      start = index + 1;
    }
  }
  parts.push(text.slice(start));
  return parts.map((part) => part.trim()).filter((part) => part.length);
}

function parameterOf(text) {
  const match = text.replace(/^(?:@\w+(?:\([^)]*\))?\s+)+/, '').match(/^(\w+)(?:\s+(\w+))?\s*:\s*([\s\S]+)$/);
  if (!match) return null;
  const [, first, second, rest] = match;
  const [type, value] = splitTopLevel(rest, '=');
  return { label: first, name: second ?? first, type: collapse(type), default: value === undefined ? null : collapse(value) };
}

function functionTable({ name, parameters, doc }) {
  const docs = parameterDocs(doc);
  return {
    title: `${name}(${parameters.map((parameter) => `${parameter.label}:`).join('')})`,
    rows: parameters.map((parameter) => ({
      name: parameter.name,
      type: parameter.type,
      default: parameter.default,
      description: docs[parameter.name] ?? '',
    })),
  };
}

// MARK: - Stored properties

function storedProperties(lines, type) {
  const rows = [];
  for (let index = type.index + 1; index < type.end; index += 1) {
    if (!/^ {4}[@a-z]/.test(lines[index])) continue;
    let text = lines[index].trim();
    let last = index;
    while (unbalanced(text) && last + 1 < type.end) {
      last += 1;
      text += `\n${lines[last].trim()}`;
    }
    const row = propertyOf(text, docAbove(lines, index));
    if (row) rows.push(row);
    index = last;
  }
  return rows;
}

function unbalanced(text) {
  let depth = 0;
  for (const character of text.replace(/"(?:[^"\\]|\\.)*"/g, '""')) {
    if ('([{'.includes(character)) depth += 1;
    else if (')]}'.includes(character)) depth -= 1;
  }
  return depth > 0;
}

function propertyOf(text, doc) {
  const match = text.match(/^((?:@[\w.]+(?:\([^)]*\))?\s+)*)(let|var)\s+(\w+)\s*([\s\S]*)$/);
  if (!match) return null;
  const [, attributes, kind, name, rest] = match;
  if (OWNED_WRAPPERS.test(attributes)) return null;

  let [type, value] = rest.startsWith(':') ? splitTopLevel(rest.slice(1), '=') : [undefined, rest.replace(/^=/, '')];
  // A body in braces after the type, or after nothing, makes it computed.
  if ((type ?? '').includes('{') || /^\s*\{/.test(rest)) return null;
  value = value?.trim() ? collapse(value) : null;
  if (kind === 'let' && value !== null) return null;

  type = type ? collapse(type) : inferredType(value);
  // What the memberwise initializer takes: nil for an optional var, and a closure for a view built by @ViewBuilder.
  if (kind === 'var' && value === null && !attributes.trim() && /[?!]$/.test(type)) value = 'nil';
  if (/@ViewBuilder\b/.test(attributes) && type && !type.includes('->')) type = `() -> ${type}`;
  if (/@Binding\b/.test(attributes)) type = `Binding<${type}>`;
  return { name, type, default: value, description: plainDoc(doc) };
}

function inferredType(value) {
  if (value === null) return '';
  if (/^(?:true|false)$/.test(value)) return 'Bool';
  if (/^-?\d+$/.test(value)) return 'Int';
  if (/^-?\d+\.\d+$/.test(value)) return 'Double';
  if (/^"/.test(value)) return 'String';
  // `Color.green` is not always a Color, as `Rule.defaults` may be an array, but `Gradient(…)` is a Gradient.
  return value.match(/^([A-Z][\w.]*)\(/)?.[1] ?? '';
}

// One line for a value written over several.
function collapse(text) {
  return text
    .replace(/\s+/g, ' ')
    .replace(/([[(]) /g, '$1')
    .replace(/,? ([\])])/g, '$1')
    .trim();
}
