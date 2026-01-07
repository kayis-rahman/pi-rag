import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({

  // srcDir is relative to config file location (docs/app/.vitepress/)
  // md folder is now in app/ directory
  srcDir: "./md",

  // GitHub Pages base path - site is served from /synapse/ subdirectory
  base: "/synapse/",

  title: "SYNAPSE",
  description: "Your Data Meets Intelligence - Local-first RAG system",

  // Ignore dead link check for now (resolving build issues)
  ignoreDeadLinks: true,

  // Note: vue/server-renderer externalization handled by VitePress internally

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Getting Started', link: '/getting-started/introduction' },
      { text: 'Architecture', link: '/architecture/overview' },
      { text: 'Usage', link: '/usage/mcp-tools' },
      { text: 'API Reference', link: '/api-reference/memory-tools' },
      { text: 'Development', link: '/development/contributing' }
    ],

    sidebar: [
      {
        text: 'Getting Started',
        items: [
          { text: 'Introduction', link: '/getting-started/introduction' },
          { text: 'Installation', link: '/getting-started/installation' },
          { text: 'Quick Start', link: '/getting-started/quick-start' },
          { text: 'Configuration', link: '/getting-started/configuration' }
        ]
      },
      {
        text: 'Architecture',
        items: [
          { text: 'Overview', link: '/architecture/overview' },
          { text: 'Memory System', link: '/architecture/memory-system' },
          { text: 'MCP Protocol', link: '/architecture/mcp-protocol' }
        ]
      },
      {
        text: 'Usage',
        items: [
          { text: 'MCP Tools', link: '/usage/mcp-tools' },
          { text: 'Ingestion', link: '/usage/ingestion' },
          { text: 'Querying', link: '/usage/querying' }
        ]
      },
      {
        text: 'API Reference',
        items: [
          { text: 'Memory Tools', link: '/api-reference/memory-tools' },
          { text: 'Server API', link: '/api-reference/server-api' },
          { text: 'CLI Commands', link: '/api-reference/cli-commands' }
        ]
      },
      {
        text: 'Development',
        items: [
          { text: 'Contributing', link: '/development/contributing' },
          { text: 'Testing', link: '/development/testing' },
          { text: 'Deployment', link: '/development/deployment' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/kayis-rahman/synapse' }
    ]
  }
})
