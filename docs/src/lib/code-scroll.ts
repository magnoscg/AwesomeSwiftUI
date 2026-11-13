// The blocks of code of the page of a component scroll down as well as
// across. Expressive Code makes a block reachable by keyboard only while it
// overflows across, and takes the tabindex away otherwise, so this gives it
// back to every block that overflows down.
const LABEL = 'Code';

function reachable(pre: HTMLElement) {
  const overflows = pre.scrollHeight > pre.clientHeight || pre.scrollWidth > pre.clientWidth;
  if (!overflows || pre.getAttribute('tabindex') === '0') return;
  pre.setAttribute('tabindex', '0');
  pre.setAttribute('role', 'region');
  const title = pre.closest('figure')?.querySelector('figcaption .title')?.textContent;
  pre.setAttribute('aria-label', title || LABEL);
}

function watch() {
  if (!document.querySelector('.component-header')) return;
  const blocks = document.querySelectorAll<HTMLElement>('.expressive-code pre');
  const observer = new MutationObserver((changes) => changes.forEach((change) => reachable(change.target as HTMLElement)));
  blocks.forEach((pre) => {
    reachable(pre);
    observer.observe(pre, { attributes: true, attributeFilter: ['tabindex'] });
  });
}

watch();
