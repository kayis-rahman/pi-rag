import type { Metadata } from "next";
import { DocsLayout } from "fumadocs-ui/layouts/docs";
import { docs } from "@/.source";
import { loader } from "fumadocs-core/source";

const rawSource = loader({
  baseUrl: '/synapse/docs',
  source: docs.toFumadocsSource(),
});

export const metadata: Metadata = {
  title: 'Documentation',
  description: 'Complete SYNAPSE documentation',
};

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <DocsLayout tree={rawSource.getPageTree()}>
      {children}
    </DocsLayout>
  );
}
