import { McpClient } from '@anthropic/mcp-client';
import { CONFIG } from '../config';

export class SynapseMcpClient extends McpClient {
    constructor() {
        // Connect to Synapse's MCP server
        super(CONFIG.MCP_SERVER_URL);
    }

    // Wrapper methods for Synapse's MCP tools

    async listProjects(scopeType?: string) {
        return await this.callTool('sy.proj.list', { scope_type: scopeType });
    }

    async listSources(projectId: string, sourceType?: string) {
        return await this.callTool('sy.src.list', {
            project_id: projectId,
            source_type: sourceType
        });
    }

    async getContext(
        projectId: string,
        contextType: string = 'all',
        query?: string,
        maxResults: number = 10
    ) {
        return await this.callTool('sy.ctx.get', {
            project_id: projectId,
            context_type: contextType,
            query: query,
            max_results: maxResults
        });
    }

    async search(
        projectId: string,
        query: string,
        memoryType: string = 'all',
        topK: number = 10
    ) {
        return await this.callTool('sy.mem.search', {
            project_id: projectId,
            query: query,
            memory_type: memoryType,
            top_k: topK
        });
    }

    async ingestFile(
        projectId: string,
        filePath: string,
        sourceType: string = 'file',
        metadata?: Record<string, any>
    ) {
        return await this.callTool('sy.mem.ingest', {
            project_id: projectId,
            file_path: filePath,
            source_type: sourceType,
            metadata: metadata
        });
    }

    async addFact(
        projectId: string,
        factKey: string,
        factValue: any,
        confidence: number = 0.9,
        category?: string
    ) {
        return await this.callTool('sy.mem.fact.add', {
            project_id: projectId,
            fact_key: factKey,
            fact_value: factValue,
            confidence: confidence,
            category: category
        });
    }

    async addEpisode(
        projectId: string,
        title: string,
        content: string,
        lessonType: string = 'general',
        quality: number = 0.8
    ) {
        return await this.callTool('sy.mem.ep.add', {
            project_id: projectId,
            title: title,
            content: content,
            lesson_type: lessonType,
            quality: quality
        });
    }

    // Helper method to get project context with intelligent fallback
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
            throw error;
        }
    }
}