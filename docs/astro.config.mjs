import starlight from '@astrojs/starlight';
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://magnoscg.github.io',
  base: '/swiftui-components',
  integrations: [
    starlight({
      title: 'Awesome SwiftUI Components',
      description: 'Copy-paste SwiftUI components, animations and transitions for iOS 18 through iOS 27.',
      // The card shown when a page of the site is shared.
      head: [
        { tag: 'meta', attrs: { property: 'og:image', content: 'https://magnoscg.github.io/swiftui-components/social-card.png' } },
        { tag: 'meta', attrs: { property: 'og:image:alt', content: 'Six components of the catalog running on iPhone.' } },
        { tag: 'meta', attrs: { name: 'twitter:card', content: 'summary_large_image' } },
        { tag: 'meta', attrs: { name: 'twitter:image', content: 'https://magnoscg.github.io/swiftui-components/social-card.png' } },
      ],
      social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/magnoscg/swiftui-components' }],
      sidebar: [
        { label: 'Start here', items: ['getting-started', 'for-ai-agents'] },
        { label: 'Catalog', items: [{ autogenerate: { directory: 'catalog' } }] },
      ],
    }),
  ],
});
