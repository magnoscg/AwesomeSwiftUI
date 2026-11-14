// Gives the page of each component its own social card in place of the one
// of the site, which astro.config.mjs sets for every other page.
import { defineRouteMiddleware } from '@astrojs/starlight/route-data';
import { cardURL, components } from './lib/catalog';

export const onRequest = defineRouteMiddleware((context) => {
  const { entry, head } = context.locals.starlightRoute;
  const [section, , id] = entry.id.split('/');
  const component = section === 'catalog' ? components.find((candidate) => candidate.id === id) : undefined;
  if (!component) return;

  const card = cardURL(component);
  const replacements: Record<string, string> = {
    'og:image': card,
    'og:image:alt': `${component.title}, running on iPhone.`,
    'twitter:image': card,
  };
  for (const tag of head) {
    const key = tag.attrs?.property ?? tag.attrs?.name;
    if (tag.tag === 'meta' && typeof key === 'string' && key in replacements) tag.attrs!.content = replacements[key];
  }
});
