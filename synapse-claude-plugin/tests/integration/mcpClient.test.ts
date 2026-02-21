import * as assert from 'assert';
import { SynapseMcpClient } from '../../src/mcp/mcpClientEnhanced';

// Integration tests for the enhanced MCP client
describe('Synapse MCP Client Integration Tests', function() {
    this.timeout(10000); // 10 second timeout for network operations

    let client: SynapseMcpClient;

    beforeEach(() => {
        client = new SynapseMcpClient();
    });

    it('should initialize with correct endpoint', () => {
        // The client should be initialized with the correct endpoint
        // This is more of a structural test since we can't easily test the actual connection
        assert.ok(client);
    });

    it('should have all expected tool methods', () => {
        // Test that all expected methods are available
        assert.ok(typeof client.listProjects === 'function');
        assert.ok(typeof client.listSources === 'function');
        assert.ok(typeof client.getContext === 'function');
        assert.ok(typeof client.search === 'function');
        assert.ok(typeof client.ingestFile === 'function');
        assert.ok(typeof client.addFact === 'function');
        assert.ok(typeof client.addEpisode === 'function');
        assert.ok(typeof client.getProjectContext === 'function');
        assert.ok(typeof client.batchOperations === 'function');
    });

    it('should validate tool information', () => {
        // Test that tool information can be retrieved
        const projectToolInfo = client.getToolInfo('sy.proj.list');
        const sourceToolInfo = client.getToolInfo('sy.src.list');
        const contextToolInfo = client.getToolInfo('sy.ctx.get');
        const searchToolInfo = client.getToolInfo('sy.mem.search');
        const ingestToolInfo = client.getToolInfo('sy.mem.ingest');
        const factToolInfo = client.getToolInfo('sy.mem.fact.add');
        const episodeToolInfo = client.getToolInfo('sy.mem.ep.add');

        assert.ok(projectToolInfo);
        assert.ok(sourceToolInfo);
        assert.ok(contextToolInfo);
        assert.ok(searchToolInfo);
        assert.ok(ingestToolInfo);
        assert.ok(factToolInfo);
        assert.ok(episodeToolInfo);
    });

    it('should handle invalid tool gracefully', () => {
        // Test that invalid tools are handled gracefully
        const invalidToolInfo = client.getToolInfo('invalid.tool.name');
        assert.equal(invalidToolInfo, null);
    });
});