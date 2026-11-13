// Splits a line of a Swift documentation comment into text and code, so the
// page draws each piece as a node and never reads the comment as HTML.
// Two backticks link a symbol in DocC; the site shows them as code too.
export interface InlinePiece {
  code: boolean;
  text: string;
}

export function inlineCode(text: string): InlinePiece[] {
  const pieces: InlinePiece[] = [];
  let last = 0;
  for (const match of text.matchAll(/``([^`]+)``|`([^`]+)`/g)) {
    if (match.index > last) pieces.push({ code: false, text: text.slice(last, match.index) });
    pieces.push({ code: true, text: match[1] ?? match[2] });
    last = match.index + match[0].length;
  }
  if (last < text.length) pieces.push({ code: false, text: text.slice(last) });
  return pieces;
}
