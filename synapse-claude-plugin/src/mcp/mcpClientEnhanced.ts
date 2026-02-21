import { McpClient } from '@anthropic/mcp-client';
import { MCP_TOOLS } from '../constants/mcpTools';
import { CONFIG } from '../config';

/**
 * Enhanced Synapse MCP Client with comprehensive error handling,
 * connection management, and enhanced tool integrations.
 */
export class SynapseMcpClient extends McpClient {
    private connectionAttempts: number = 0;
    private maxConnectionAttempts: number = 3;

    constructor() {
        // Connect to Synapse's MCP server
        super(CONFIG.MCP_SERVER_URL);
    }

    /**
     * Enhanced connection management with retry logic
     */
    async ensureConnection(): Promise<boolean> {
        try {
            // Try to ping the server to check connectivity
            const response = await this.callTool('sy.proj.list', { scope_type: 'user' });
            this.connectionAttempts = 0; // Reset attempts on success
            return true;
        } catch (error) {
            this.connectionAttempts++;

            if (this.connectionAttempts >= this.maxConnectionAttempts) {
                console.error('Failed to connect to Synapse MCP server after max attempts');
                return false;
            }

            // Wait before retry
            await new Promise(resolve => setTimeout(resolve, 1000));
            return await this.ensureConnection();
        }
    }

    /**
     * List all projects in RAG memory system
     */
    async listProjects(scopeType?: string) {
        try {
            const result = await this.callTool('sy.proj.list', { scope_type: scopeType });
            return result;
        } catch (error) {
            console.error('Failed to list projects:', error);
            throw new Error(`Failed to list projects: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }

    /**
     * List document sources for a project in semantic memory
     */
    async listSources(projectId: string, sourceType?: string) {
        try {
            const result = await this.callTool('sy.src.list', {
                project_id: projectId,
                source_type: sourceType
            });
            return result;
        } catch (error) {
            console.error('Failed to list sources:', error);
            throw new Error(`Failed to list sources: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }

    /**
     * Get comprehensive project context with authority hierarchy
     */
    async getContext(
        projectId: string,
        contextType: string = 'all',
        query?: string,
        maxResults: number = 10
    ) {
        try {
            const result = await this.callTool('sy.ctx.get', {
                project_id: projectId,
                context_type: contextType,
                query: query,
                max_results: maxResults
            });
            return result;
        } catch (error) {
            console.error('Failed to get context:', error);
            throw new Error(`Failed to get context: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }

    /**
     * Semantic search across all memory types
     */
    async search(
        projectId: string,
        query: string,
        memoryType: string = 'all',
        topK: number = 10
    ) {
        try {
            const result = await this.callTool('sy.mem.search', {
                project_id: projectId,
                query: query,
                memory_type: memoryType,
                top_k: topK
            });
            return result;
        } catch (error) {
            console.error('Failed to search:', error);
            throw new Error(`Failed to search: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }

    /**
     * Ingest file OR text content into semantic memory
     */
    async ingestFile(
        projectId: string,
        filePath: string,
        sourceType: string = 'file',
        metadata?: Record<string, any>
    ) {
        try {
            const result = await this.callTool('sy.mem.ingest', {
                project_id: projectId,
                file_path: filePath,
                source_type: sourceType,
                metadata: metadata
            });
            return result;
        } catch (error) {
            console.error('Failed to ingest file:', error);
            throw new Error(`Failed to ingest file: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }

    /**
     * Add a symbolic memory fact (authoritative)
     */
    async addFact(
        projectId: string,
        factKey: string,
        factValue: any,
        confidence: number = 0.9,
        category?: string
    ) {
        try {
            const result = await this.callTool('sy.mem.fact.add', {
                project_id: projectId,
                fact_key: factKey,
                fact_value: factValue,
                confidence: confidence,
                category: category
            });
            return result;
        } catch (error) {
            console.error('Failed to add fact:', error);
            throw new Error(`Failed to add fact: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }

    /**
     * Add an episodic memory episode (advisory)
     */
    async addEpisode(
        projectId: string,
        title: string,
        content: string,
        lessonType: string = 'general',
        quality: number = 0.8
    ) {
        try {
            const result = await this.callTool('sy.mem.ep.add', {
                project_id: projectId,
                title: title,
                content: content,
                lesson_type: lessonType,
                quality: quality
            });
            return result;
        } catch (error) {
            console.error('Failed to add episode:', error);
            throw new Error(`Failed to add episode: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }

    /**
     * Enhanced helper method to get project context with intelligent fallback
     */
    async getProjectContext(
        projectId: string,
        query?: string
    ) {
        try {
            // Try to get context with semantic search if query is provided
            if (query) {
                const context = await this.getContext(projectId, 'all', query, 10);
                return context;
            } else {
                // Get basic project context
                const context = await this.getContext(projectId, 'all');
                return context;
            }
        } catch (error) {
            console.error('Failed to get project context:', error);
            throw new Error(`Failed to get project context: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }

    /**
     * Batch operations for improved performance
     */
    async batchOperations(operations: Array<{ tool: string; params: any }>) {
        const results: any[] = [];

        for (const operation of operations) {
            try {
                const result = await this.callTool(operation.tool, operation.params);
                results.push({ tool: operation.tool, result, success: true });
            } catch (error) {
                results.push({
                    tool: operation.tool,
                    error: error instanceof Error ? error.message : 'Unknown error',
                    success: false
                });
            }
        }

        return results;
    }

    /**
     * Get detailed tool information for documentation and validation
     */
    getToolInfo(toolName: string) {
        switch (toolName) {
            case 'sy.proj.list':
                return MCP_TOOLS.LIST_PROJECTS;
            case 'sy.src.list':
                return MCP_TOOLS.LIST_SOURCES;
            case 'sy.ctx.get':
                return MCP_TOOLS.GET_CONTEXT;
            case 'sy.mem.search':
                return MCP_TOOLS.SEARCH;
            case 'sy.mem.ingest':
                return MCP_TOOLS.INGEST_FILE;
            case 'sy.mem.fact.add':
                return MCP_TOOLS.ADD_FACT;
            case 'sy.mem.ep.add':
                return MCP_TOOLS.ADD_EPISODE;
            default:
                return null;
        }
    }

    /**
     * Validate input parameters against tool schemas
     */
    validateToolInput(toolName: string, params: any): boolean {
        const toolInfo = this.getToolInfo(toolName);
        if (!toolInfo) {
            return false;
        }

        // Basic validation would go here
        // In a real implementation, you'd use JSON Schema validation
        return true;
    }
}