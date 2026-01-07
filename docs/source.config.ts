import { defineDocs, frontmatterSchema } from "fumadocs-mdx/config";

export const docs = defineDocs({
  dir: 'content/docs',
  docs: {
    schema: frontmatterSchema.extend({
      title: { type: 'string', required: true },
      description: { type: 'string' },
    }),
  },
});
