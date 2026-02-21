import * as assert from 'assert';
import { SynapseMcpClient } from '../../src/mcp/mcpClientEnhanced';

// Unit tests for the enhanced MCP client
describe('Synapse MCP Client Unit Tests', function() {

    it('should create client instance successfully', () => {
        const client = new SynapseMcpClient();
        assert.ok(client instanceof SynapseMcpClient);
    });

    it('should have correct property structure', () => {
        const client = new SynapseMcpClient();

        // Check that it has the expected properties
        assert.ok(client.hasOwnProperty('connectionAttempts'));
        assert.ok(client.hasOwnProperty('maxConnectionAttempts'));
    });

    it('should have method signatures', () => {
        const client = new SynapseMcpClient();

        // Check that all expected methods exist
        assert.equal(typeof client.listProjects, 'function');
        assert.equal(typeof client.listSources, 'function');
        assert.equal(typeof client.getContext, 'function');
        assert.equal(typeof client.search, 'function');
        assert.equal(typeof client.ingestFile, 'function');
        assert.equal(typeof client.addFact, 'function');
        assert.equal(typeof client.addEpisode, 'function');
        assert.equal(typeof client.getProjectContext, 'function');
        assert.equal(typeof client.batchOperations, 'function');
        assert.equal(typeof client.getToolInfo, 'function');
        assert.equal(typeof client.validateToolInput, 'function');
    });
});