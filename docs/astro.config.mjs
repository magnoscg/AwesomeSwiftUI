import starlight from '@astrojs/starlight';
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://magnoscg.github.io',
  base: '/swiftui-components',
  integrations: [
    starlight({
      title: 'Awesome SwiftUI Components',
      description: 'Copy-paste SwiftUI components, animations and transitions for iOS 18 through iOS 27.',
      social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/magnoscg/swiftui-components' }],
      sidebar: [
        { label: 'Start here', items: ['getting-started', 'for-ai-agents'] },
        { label: 'Catalog', items: [{ autogenerate: { directory: 'catalog' } }] },
      ],
    }),
  ],
});
