// @ts-nocheck
import * as __fd_glob_15 from "../content/docs/usage/querying.mdx?collection=docs"
import * as __fd_glob_14 from "../content/docs/usage/mcp-tools.mdx?collection=docs"
import * as __fd_glob_13 from "../content/docs/usage/ingestion.mdx?collection=docs"
import * as __fd_glob_12 from "../content/docs/getting-started/quick-start.mdx?collection=docs"
import * as __fd_glob_11 from "../content/docs/getting-started/introduction.mdx?collection=docs"
import * as __fd_glob_10 from "../content/docs/getting-started/installation.mdx?collection=docs"
import * as __fd_glob_9 from "../content/docs/getting-started/configuration.mdx?collection=docs"
import * as __fd_glob_8 from "../content/docs/development/testing.mdx?collection=docs"
import * as __fd_glob_7 from "../content/docs/development/deployment.mdx?collection=docs"
import * as __fd_glob_6 from "../content/docs/development/contributing.mdx?collection=docs"
import * as __fd_glob_5 from "../content/docs/architecture/overview.mdx?collection=docs"
import * as __fd_glob_4 from "../content/docs/architecture/memory-system.mdx?collection=docs"
import * as __fd_glob_3 from "../content/docs/architecture/mcp-protocol.mdx?collection=docs"
import * as __fd_glob_2 from "../content/docs/api-reference/server-api.mdx?collection=docs"
import * as __fd_glob_1 from "../content/docs/api-reference/memory-tools.mdx?collection=docs"
import * as __fd_glob_0 from "../content/docs/api-reference/cli-commands.mdx?collection=docs"
import { server } from 'fumadocs-mdx/runtime/server';
import type * as Config from '../source.config';

const create = server<typeof Config, import("fumadocs-mdx/runtime/types").InternalTypeConfig & {
  DocData: {
  }
}>({"doc":{"passthroughs":["extractedReferences"]}});

export const docs = await create.docs("docs", "content/docs", {}, {"api-reference/cli-commands.mdx": __fd_glob_0, "api-reference/memory-tools.mdx": __fd_glob_1, "api-reference/server-api.mdx": __fd_glob_2, "architecture/mcp-protocol.mdx": __fd_glob_3, "architecture/memory-system.mdx": __fd_glob_4, "architecture/overview.mdx": __fd_glob_5, "development/contributing.mdx": __fd_glob_6, "development/deployment.mdx": __fd_glob_7, "development/testing.mdx": __fd_glob_8, "getting-started/configuration.mdx": __fd_glob_9, "getting-started/installation.mdx": __fd_glob_10, "getting-started/introduction.mdx": __fd_glob_11, "getting-started/quick-start.mdx": __fd_glob_12, "usage/ingestion.mdx": __fd_glob_13, "usage/mcp-tools.mdx": __fd_glob_14, "usage/querying.mdx": __fd_glob_15, });