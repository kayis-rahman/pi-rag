# SYNAPSE MCP Tools Setup for Claude Code Integration
## Feature Requirements

### Overview
This feature implements the setup and enforcement of SYNAPSE MCP tools specifically for Claude Code integration. The goal is to ensure that Claude Code can effectively utilize the RAG system's capabilities through the standardized MCP protocol.

### User Stories
1. As a developer, I want to configure SYNAPSE to work with Claude Code so that Claude Code can access RAG capabilities
2. As a system administrator, I want to enforce MCP tool usage for Claude Code so that the integration is secure and consistent
3. As a developer, I want to verify that all 7 MCP tools are available and working with Claude Code

### Acceptance Criteria
- [ ] MCP server is configured to accept connections from Claude Code
- [ ] All 7 MCP tools are properly registered and accessible
- [ ] Claude Code can connect to the SYNAPSE MCP server at `http://localhost:8002/mcp`
- [ ] Tool usage protocols are established for Claude Code workflows
- [ ] Context injection is properly configured for Claude Code integration
- [ ] Security considerations are properly implemented

### Technical Requirements
1. **MCP Server Configuration**
   - Server must listen on port 8002 (default)
   - Must support Streamable HTTP transport
   - Must be compatible with opencode and other MCP clients

2. **Tool Availability**
   - All 7 MCP tools must be registered:
     - `sy.proj.list` - List all projects in RAG memory system
     - `sy.src.list` - List document sources for a project in semantic memory
     - `sy.ctx.get` - Get comprehensive project context with authority hierarchy
     - `sy.mem.search` - Semantic search across all memory types
     - `sy.mem.ingest` - Ingest file OR text content into semantic memory
     - `sy.mem.fact.add` - Add a symbolic memory fact (authoritative)
     - `sy.mem.ep.add` - Add an episodic memory episode (advisory)

3. **Integration Requirements**
   - Claude Code must be able to discover and use all MCP tools
   - Tool permissions must be properly configured
   - Context injection must be enabled for enhanced agent performance

### Non-Functional Requirements
1. **Security**
   - Transport security must allow remote connections
   - CORS configuration must be appropriate for cross-origin access
   - Authentication/authorization mechanisms must be implemented

2. **Performance**
   - Server must respond to tool calls within 100ms for common operations
   - Query performance must be maintained at <1000ms for complex queries

3. **Compatibility**
   - Must be compatible with Claude Code's MCP protocol implementation
   - Should work with both local and remote tool execution patterns
   - Backward compatibility with existing tool usage must be maintained

### Dependencies
- SYNAPSE MCP server implementation (already exists)
- Python 3.8+ environment
- Required Python packages (listed in requirements.txt)
- Properly configured SYNAPSE data directory
- Running MCP server instance on port 8002