import { docs as rawDocs } from "@/.source";
import { loader } from "fumadocs-core/source";
import defaultMdxComponents from "fumadocs-ui/mdx";
import {
  DocsBody,
  DocsDescription,
  DocsPage,
  DocsTitle,
} from "fumadocs-ui/page";

const source = loader({
  baseUrl: '/synapse/docs',
  source: rawDocs.toFumadocsSource(),
});

export async function generateStaticParams() {
  const pages = source.getPages();
  return pages.map((page: any) => ({
    slug: page.slugs,
    lang: 'en',
  }));
}

export default async function Page({ params }: { params: Promise<{ lang?: string; slug?: string[] }> }) {
  const { slug } = await params;
  const page = source.getPage(slug) as any;

  if (!page) {
    return <div>Not Found</div>;
  }

  const MDX = page.data.body;

  return (
    <DocsPage toc={page.data.toc}>
      <DocsTitle>{page.data.title}</DocsTitle>
      <DocsDescription>{page.data.description}</DocsDescription>
      <DocsBody>
        <MDX components={defaultMdxComponents} />
      </DocsBody>
    </DocsPage>
  );
}
