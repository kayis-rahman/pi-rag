# SYNAPSE MCP Tools Setup for Claude Code Integration
## Technical Plan

### Overview
This document outlines the technical approach for implementing the SYNAPSE MCP tools setup specifically for Claude Code integration. The plan builds upon the existing MCP server infrastructure and extends it to properly support Claude Code's requirements.

### Implementation Approach

#### 1. Verify Existing MCP Server Configuration
- Confirm that the MCP server is properly configured to accept connections
- Ensure the server listens on the correct port (default 8002)
- Validate that all required tools are registered

#### 2. Configure Claude Code for MCP Integration
- Set up Claude Code to use the SYNAPSE MCP server
- Configure appropriate tool usage permissions
- Ensure proper authentication/authorization mechanisms

#### 3. Establish Tool Usage Protocols
- Define which tools should be used for different operations
- Set up proper context injection for Claude Code
- Configure appropriate project scoping

#### 4. Testing and Validation
- Test connectivity to the MCP server
- Verify tool execution works correctly
- Ensure proper integration with Claude Code workflows

### Critical Files to Modify

1. **Primary MCP Server**: `/home/dietpi/synapse/mcp_server/http_wrapper.py`
   - Contains all 7 MCP tools implementations
   - Uses FastMCP for proper MCP protocol compliance

2. **Configuration**: `/home/dietpi/synapse/configs/synapse_config.json`
   - Contains server configuration including port settings
   - Has automatic learning and universal hooks configurations

3. **CLI Commands**: `/home/dietpi/synapse/synapse/cli/main.py`
   - Contains startup logic for the MCP server
   - Has commands for status checking and server management

### MCP Server Startup
The MCP server can be started with:
```bash
# Native mode (recommended for local development)
synapse start

# Or using the direct Python script
python3 -m mcp_server.http_wrapper
```

The server will listen on port 8002 by default, as configured in the environment or config.

### Tool Usage Patterns

For Claude Code integration, the following patterns should be established:

1. **Context Retrieval**: Use `sy.ctx.get` to get comprehensive context
2. **Information Retrieval**: Use `sy.mem.search` for semantic search
3. **Knowledge Storage**: Use `sy.mem.fact.add` for authoritative facts and `sy.mem.ep.add` for advisory lessons
4. **Document Ingestion**: Use `sy.mem.ingest` for adding new documents

### Security Considerations

The MCP server is configured with:
- Transport security allowing remote connections
- CORS configuration for cross-origin access
- Proper authentication/authorization mechanisms

### Implementation Phases

#### Phase 1: Server Configuration Verification
- Check MCP server configuration in `http_wrapper.py`
- Validate port binding and tool registration
- Confirm security settings are appropriate

#### Phase 2: Integration Setup
- Configure Claude Code to use the MCP endpoint
- Set up proper tool permissions
- Configure context injection settings

#### Phase 3: Protocol Establishment
- Define usage patterns for Claude Code
- Configure project scoping
- Set up appropriate memory authority handling

#### Phase 4: Testing and Validation
- Test server connectivity
- Verify tool execution
- Validate Claude Code integration

### Expected Outcomes

1. Claude Code can successfully connect to the SYNAPSE MCP server
2. All 7 MCP tools are available for use with Claude Code
3. Proper context injection and memory management is enabled
4. The system can handle both local and remote tool execution patterns
5. Automatic learning and adaptive memory features are accessible

### Verification Plan

1. **Server Status Check**:
   ```bash
   synapse status
   ```

2. **Health Check Endpoint**:
   ```bash
   curl http://localhost:8002/health
   ```

3. **Tool Discovery**:
   ```bash
   curl http://localhost:8002/mcp
   ```

4. **Test Tool Execution**:
   ```bash
   curl -X POST http://localhost:8002/mcp \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"sy.proj.list"},"id":1}'
   ```

### Integration with Claude Code

To properly enforce SYNAPSE MCP tools for Claude Code:

1. **Configure Claude Code to use the MCP endpoint**:
   - Point Claude Code to `http://localhost:8002/mcp`
   - Ensure proper authentication if needed

2. **Define Tool Permissions**:
   - Allow access to all 7 MCP tools for Claude Code
   - Configure appropriate project scopes

3. **Set up Context Injection**:
   - Configure context injection for enhanced agent performance
   - Set up appropriate memory authority hierarchy handling

### Risk Assessment

1. **Integration Compatibility**: Potential issues with Claude Code's specific MCP implementation
2. **Security Configuration**: Need to balance accessibility with security
3. **Performance Impact**: Additional overhead from context injection and memory management
4. **Version Compatibility**: Ensuring MCP protocol compatibility across versions

### Success Metrics

- [ ] Server connects successfully to Claude Code
- [ ] All 7 MCP tools are discoverable and executable
- [ ] Context injection works properly for Claude Code workflows
- [ ] Performance meets expectations for typical Claude Code operations
- [ ] Security settings are appropriate for the integration