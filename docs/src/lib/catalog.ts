// The catalog the site is built from, read at build time, so the landing page
// never states a number by hand.
import { readFileSync, statSync } from 'node:fs';
import { resolve } from 'node:path';

interface Component {
  id: string;
  name: string;
  title: string;
  category: string;
  summary: string;
  preview: string;
  keywords: { en: string[]; es: string[] };
  difficulty: string;
  minIOS: string;
  apis: string[];
  origin: { kind: 'original' } | { kind: 'inspired'; credit: string; url: string } | { kind: 'adapted'; url: string; license: string };
  shader?: string;
  rawURL: string;
  shaderRawURL?: string;
}

// `pnpm --dir docs` runs with docs/ as the working directory.
const root = resolve(process.cwd(), '..');
const RAW_BASE = 'https://raw.githubusercontent.com/magnoscg/swiftui-components/HEAD';
export const SITE_BASE = '/swiftui-components';
export const REPOSITORY = 'https://github.com/magnoscg/swiftui-components';

const catalog = JSON.parse(readFileSync(resolve(root, 'catalog.json'), 'utf8')) as {
  count: number;
  components: Component[];
};

export const components = catalog.components;
export const count = catalog.count;

export const categories = [...new Set(components.map((component) => component.category))]
  .sort()
  .map((name) => ({
    name,
    count: components.filter((component) => component.category === name).length,
    href: categoryURL(name),
  }));

export function categoryURL(category: string) {
  return `${SITE_BASE}/catalog/${category.toLowerCase()}/`;
}

export function previewURL(component: Component) {
  return `${RAW_BASE}/${component.preview}`;
}

export function pageURL(component: Component) {
  return `${SITE_BASE}/catalog/${component.category.toLowerCase()}/${component.id}/`;
}

/** The size of a preview in bytes, to leave the heavy ones out of the landing page. */
export function previewBytes(component: Component) {
  return statSync(resolve(root, component.preview)).size;
}
