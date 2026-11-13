// The copy buttons of the site, with one listener for all of them. A button
// carries its text in `data-copy`, or `data-copy-code` with the title of the
// block of code whose source it takes. It shows `data-done` for a moment.
document.addEventListener('click', async (event) => {
  const button = (event.target as Element).closest<HTMLButtonElement>('button[data-copy], button[data-copy-code]');
  if (!button || 'copied' in button.dataset) return;

  let text = button.dataset.copy;
  if (text === undefined) {
    // Expressive Code keeps the source of a block on its own copy button, with its line breaks encoded.
    const block = [...document.querySelectorAll('.expressive-code')].find(
      (candidate) => candidate.querySelector('figcaption .title')?.textContent === button.dataset.copyCode,
    );
    const source = block?.querySelector<HTMLElement>('.copy button[data-code]');
    text = source?.dataset.code?.replace(/\u007f/g, '\n');
  }
  if (!text) return;

  try {
    await navigator.clipboard.writeText(text);
  } catch {
    return;
  }
  const label = button.querySelector<HTMLElement>('[data-copy-label]') ?? button;
  const before = label.textContent ?? '';
  const done = button.dataset.done ?? 'Copied';
  label.textContent = done;
  button.dataset.copied = '';
  const status = document.querySelector('[data-copy-status]');
  if (status) status.textContent = done;
  setTimeout(() => {
    label.textContent = before;
    delete button.dataset.copied;
    if (status) status.textContent = '';
  }, 1600);
});
