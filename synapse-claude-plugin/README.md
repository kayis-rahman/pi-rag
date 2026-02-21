# Synapse Claude Plugin

A Claude Code extension that integrates with the Synapse RAG (Retrieval-Augmented Generation) system to provide intelligent code analysis, documentation generation, and knowledge retrieval capabilities.

## Overview

This plugin extends Claude Code's development environment to provide AI-powered code understanding using Synapse's advanced RAG capabilities. It leverages Synapse's three-tier memory architecture (symbolic, episodic, semantic) to provide contextual insights and intelligent code assistance.

## Features

### 1. Code Analysis
- Real-time code analysis using AST parsing
- Context-aware code understanding
- Pattern recognition and relationship mapping

### 2. Knowledge Integration
- Integration with Synapse's MCP tools:
  - `sy.proj.list` - Project discovery and management
  - `sy.src.list` - Source file cataloging and indexing
  - `sy.ctx.get` - Comprehensive context retrieval for code elements
  - `sy.mem.search` - Semantic search for relevant documentation and code examples
  - `sy.mem.ingest` - Automated code documentation ingestion
  - `sy.mem.fact.add` - Store authoritative code facts and specifications
  - `sy.mem.ep.add` - Log learning episodes from code analysis sessions

### 3. IDE Integration
- Code lens integration for contextual analysis
- Hover provider for detailed code insights
- Command integration with Claude Code's UI

## Installation

1. Install the plugin in Claude Code
2. Ensure Synapse MCP server is running on `http://localhost:8003` (can be configured in src/config.ts)
3. Restart Claude Code to activate the plugin

## Usage

### Commands
- **Synapse: Analyze Current File** - Analyze code with Synapse's knowledge base
- **Synapse: Generate Documentation** - Generate documentation using code context
- **Synapse: Search Knowledge Base** - Search Synapse's knowledge base for code-related information

### Features
- Hover over any code element to see Synapse's contextual analysis
- Code lenses appear in the editor for quick analysis
- Real-time integration with Synapse's RAG system

## Architecture

```
Synapse Claude Plugin
├── src/
│   ├── extension.ts          # Main plugin entry point
│   ├── analysis/             # Code analysis components
│   │   ├── codeAnalyzer.ts     # Core code analysis functionality
│   │   ├── astParser.ts        # AST parsing for different languages
│   │   └── patternMatcher.ts   # Pattern recognition engine
│   ├── mcp/                    # MCP integration layer
│   │   ├── mcpClient.ts        # MCP connection and tool invocation
│   │   └── toolHandlers.ts     # Handler for each MCP tool
│   ├── ide/                    # IDE integration components
│   │   ├── codeLensProvider.ts # Code lens integration
│   │   └── hoverProvider.ts    # Hover information provider
│   ├── utils/                  # Utility functions
│   │   └── cache.ts          # Local caching for performance
│   └── constants/              # MCP tool definitions and schemas
└── package.json              # Plugin manifest and dependencies
```

## Technical Details

### MCP Tool Integration
The plugin connects to Synapse's MCP server at `http://localhost:8003` (configurable in src/config.ts) and provides wrappers for all 7 Synapse MCP tools:

1. `sy.proj.list` - Project discovery
2. `sy.src.list` - Source file cataloging
3. `sy.ctx.get` - Context retrieval with authority hierarchy
4. `sy.mem.search` - Semantic search across memory types
5. `sy.mem.ingest` - File ingestion into semantic memory
6. `sy.mem.fact.add` - Store authoritative facts
7. `sy.mem.ep.add` - Log learning episodes

### Performance Optimization
- Local caching for frequently accessed data
- Async/await for non-blocking operations
- Request batching for efficiency
- Memory usage optimization through proper resource disposal

## Configuration

The plugin connects to Synapse by default at `http://localhost:8003`. This can be customized in the plugin's configuration file (src/config.ts).

## Security

All processing happens locally within the Claude Code environment. No external data transmission occurs. The plugin maintains Synapse's local-first, privacy-focused approach.

## Development

### Building
```bash
npm install
npm run build
```

### Running in Development Mode
```bash
npm run watch
```

## Contributing

Contributions are welcome! Please submit issues and pull requests to the repository.

## License

MIT License - see LICENSE file for details