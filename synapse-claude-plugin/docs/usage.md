# Synapse Claude Plugin - Usage Guide

This document provides detailed usage instructions for the Synapse Claude Plugin.

## Getting Started

Once installed, the plugin will automatically activate when you open a code file in Claude Code. The plugin provides several key features accessible through commands and IDE integrations.

## Core Features

### 1. Code Analysis

#### Analyze Current File
- Command: `Synapse: Analyze Current File`
- Description: Performs comprehensive code analysis using Synapse's knowledge base
- Features:
  - AST-based code parsing
  - Pattern recognition
  - Contextual relationship mapping
  - Semantic search integration

### 2. Documentation Generation

#### Generate Documentation
- Command: `Synapse: Generate Documentation`
- Description: Creates documentation based on code structure and Synapse's knowledge base
- Features:
  - Auto-detection of code elements (functions, classes, imports)
  - Contextual documentation retrieval
  - Pattern-based documentation generation

### 3. Knowledge Base Search

#### Search Knowledge Base
- Command: `Synapse: Search Knowledge Base`
- Description: Search Synapse's knowledge base for code-related information
- Features:
  - Semantic search across all memory types
  - Context-aware results
  - Integration with code context

## IDE Integration

### Code Lenses
- Appears in the editor for code elements that can be analyzed
- Click "🔍 Analyze Code" to perform immediate analysis

### Hover Information
- Hover over any code element to see Synapse's contextual analysis
- Displays:
  - Symbolic memory facts
  - Semantic memory references
  - Related documentation

## Command Usage

### Analyze Current File
1. Open any code file in Claude Code
2. Execute command: `Synapse: Analyze Current File`
3. View results in Claude Code's output panel

### Generate Documentation
1. Open any code file in Claude Code
2. Execute command: `Synapse: Generate Documentation`
3. View generated documentation in Claude Code's output panel

### Search Knowledge Base
1. Execute command: `Synapse: Search Knowledge Base`
2. Enter a search query when prompted
3. View results in a webview panel

## Configuration

The plugin connects to Synapse by default at `http://localhost:8003`. This can be customized in the plugin's configuration file (src/config.ts).

## Troubleshooting

### Connection Issues
- Ensure Synapse MCP server is running on `http://localhost:8003` (configurable in src/config.ts)
- Check that the server is accessible from your machine
- Verify firewall settings if running on a remote machine

### Performance Issues
- Large files may take longer to analyze
- Consider limiting analysis to smaller code segments
- Monitor system resources during intensive operations

### Plugin Not Activating
- Verify the plugin is properly installed in Claude Code
- Check that the Synapse MCP server is running
- Restart Claude Code to reload the extension

## Best Practices

1. **Regular Analysis**: Use the analysis feature regularly to understand your codebase
2. **Documentation**: Generate documentation for new or modified code
3. **Knowledge Base**: Search the knowledge base before making significant changes
4. **Performance**: For large files, consider breaking them into smaller modules for analysis

## Privacy and Security

All processing happens locally within the Claude Code environment. No external data transmission occurs. The plugin maintains Synapse's local-first, privacy-focused approach.