export default function Page() {
  return (
    <div className="flex min-h-screen flex-col">
      <header className="border-b">
        <nav className="container mx-auto flex h-16 items-center justify-between px-4">
          <div className="font-bold text-xl">
            <a href="/synapse/docs/getting-started/introduction" className="hover:underline">
              SYNAPSE
            </a>
          </div>
        </nav>
      </header>
      <main className="flex-1 container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-4xl font-bold mb-6">SYNAPSE Documentation</h1>
          <p className="text-xl mb-8">Your Data Meets Intelligence</p>
          <div className="grid gap-6 md:grid-cols-2">
            <a href="/synapse/docs/getting-started/introduction" className="block p-6 border rounded-lg hover:bg-gray-50">
              <h2 className="text-2xl font-bold mb-2">Getting Started</h2>
              <p className="text-gray-600">Installation, configuration, and quick start guide</p>
            </a>
            <a href="/synapse/docs/architecture/overview" className="block p-6 border rounded-lg hover:bg-gray-50">
              <h2 className="text-2xl font-bold mb-2">Architecture</h2>
              <p className="text-gray-600">Memory system, MCP protocol, and data flow</p>
            </a>
            <a href="/synapse/docs/usage/mcp-tools" className="block p-6 border rounded-lg hover:bg-gray-50">
              <h2 className="text-2xl font-bold mb-2">Usage</h2>
              <p className="text-gray-600">MCP tools, ingestion, and querying</p>
            </a>
            <a href="/synapse/docs/development/contributing" className="block p-6 border rounded-lg hover:bg-gray-50">
              <h2 className="text-2xl font-bold mb-2">Development</h2>
              <p className="text-gray-600">Contributing, testing, and deployment</p>
            </a>
          </div>
        </div>
      </main>
      <footer className="border-t mt-8 py-6">
        <div className="container mx-auto px-4 text-center text-sm text-gray-600">
          <p>© 2025 SYNAPSE. MIT License.</p>
        </div>
      </footer>
    </div>
  );
}
