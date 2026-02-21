/**
 * Tool Handlers for Synapse Claude Plugin
 * Handles specific operations for each MCP tool
 */

import { SynapseMcpClient } from '../mcp/mcpClientEnhanced';

export class ToolHandlers {
    private mcpClient: SynapseMcpClient;

    constructor(mcpClient: SynapseMcpClient) {
        this.mcpClient = mcpClient;
    }

    /**
     * Handle project listing operations
     */
    async handleListProjects(scopeType?: string) {
        try {
            const projects = await this.mcpClient.listProjects(scopeType);
            return {
                success: true,
                data: projects,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Handle source listing operations
     */
    async handleListSources(projectId: string, sourceType?: string) {
        try {
            const sources = await this.mcpClient.listSources(projectId, sourceType);
            return {
                success: true,
                data: sources,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Handle context retrieval operations
     */
    async handleGetContext(
        projectId: string,
        contextType: string = 'all',
        query?: string,
        maxResults: number = 10
    ) {
        try {
            const context = await this.mcpClient.getContext(projectId, contextType, query, maxResults);
            return {
                success: true,
                data: context,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Handle semantic search operations
     */
    async handleSearch(
        projectId: string,
        query: string,
        memoryType: string = 'all',
        topK: number = 10
    ) {
        try {
            const results = await this.mcpClient.search(projectId, query, memoryType, topK);
            return {
                success: true,
                data: results,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Handle file ingestion operations
     */
    async handleIngestFile(
        projectId: string,
        filePath: string,
        sourceType: string = 'file',
        metadata?: Record<string, any>
    ) {
        try {
            const result = await this.mcpClient.ingestFile(projectId, filePath, sourceType, metadata);
            return {
                success: true,
                data: result,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Handle fact addition operations
     */
    async handleAddFact(
        projectId: string,
        factKey: string,
        factValue: any,
        confidence: number = 0.9,
        category?: string
    ) {
        try {
            const result = await this.mcpClient.addFact(projectId, factKey, factValue, confidence, category);
            return {
                success: true,
                data: result,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Handle episode addition operations
     */
    async handleAddEpisode(
        projectId: string,
        title: string,
        content: string,
        lessonType: string = 'general',
        quality: number = 0.8
    ) {
        try {
            const result = await this.mcpClient.addEpisode(projectId, title, content, lessonType, quality);
            return {
                success: true,
                data: result,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: new Date().toISOString()
            };
        }
    }
}