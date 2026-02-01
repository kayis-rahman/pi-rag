// @ts-nocheck
import { browser } from 'fumadocs-mdx/runtime/browser';
import type * as Config from '../source.config';

const create = browser<typeof Config, import("fumadocs-mdx/runtime/types").InternalTypeConfig & {
  DocData: {
  }
}>();
const browserCollections = {
  docs: create.doc("docs", {"api-reference/cli-commands.mdx": () => import("../content/docs/api-reference/cli-commands.mdx?collection=docs"), "api-reference/memory-tools.mdx": () => import("../content/docs/api-reference/memory-tools.mdx?collection=docs"), "api-reference/server-api.mdx": () => import("../content/docs/api-reference/server-api.mdx?collection=docs"), "architecture/mcp-protocol.mdx": () => import("../content/docs/architecture/mcp-protocol.mdx?collection=docs"), "architecture/memory-system.mdx": () => import("../content/docs/architecture/memory-system.mdx?collection=docs"), "architecture/overview.mdx": () => import("../content/docs/architecture/overview.mdx?collection=docs"), "development/contributing.mdx": () => import("../content/docs/development/contributing.mdx?collection=docs"), "development/deployment.mdx": () => import("../content/docs/development/deployment.mdx?collection=docs"), "development/testing.mdx": () => import("../content/docs/development/testing.mdx?collection=docs"), "getting-started/configuration.mdx": () => import("../content/docs/getting-started/configuration.mdx?collection=docs"), "getting-started/installation.mdx": () => import("../content/docs/getting-started/installation.mdx?collection=docs"), "getting-started/introduction.mdx": () => import("../content/docs/getting-started/introduction.mdx?collection=docs"), "getting-started/quick-start.mdx": () => import("../content/docs/getting-started/quick-start.mdx?collection=docs"), "usage/ingestion.mdx": () => import("../content/docs/usage/ingestion.mdx?collection=docs"), "usage/mcp-tools.mdx": () => import("../content/docs/usage/mcp-tools.mdx?collection=docs"), "usage/querying.mdx": () => import("../content/docs/usage/querying.mdx?collection=docs"), }),
};
export default browserCollections;