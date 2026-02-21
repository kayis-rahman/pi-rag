import * as vscode from 'vscode';
import { SynapseMcpClient } from '../mcp/mcpClientEnhanced';

export class HoverProvider implements vscode.HoverProvider {
    private mcpClient: SynapseMcpClient;

    constructor(mcpClient: SynapseMcpClient) {
        this.mcpClient = mcpClient;
    }

    async provideHover(
        document: vscode.TextDocument,
        position: vscode.Position,
        token: vscode.CancellationToken
    ): Promise<vscode.Hover | null> {
        // Get the word at the cursor position
        const range = document.getWordRangeAtPosition(position);
        if (!range) {
            return null;
        }

        const word = document.getText(range);

        // If it's a relatively short word, try to get context from Synapse
        if (word.length > 2 && word.length < 50) {
            try {
                // Get context from Synapse's memory system
                const context = await this.mcpClient.getContext('global', 'all', word, 5);

                // Get semantic search results
                const searchResults = await this.mcpClient.search('global', word, 'semantic', 5);

                // Format the hover content
                const hoverContent = new vscode.MarkdownString();
                hoverContent.appendMarkdown(`### Synapse Analysis for \`${word}\`\n\n`);

                if (context.symbolic && context.symbolic.length > 0) {
                    hoverContent.appendMarkdown('**Symbolic Memory (Authoritative):**\n');
                    context.symbolic.slice(0, 3).forEach((fact: any) => {
                        hoverContent.appendMarkdown(`- ${fact.key}: ${fact.value}\n`);
                    });
                }

                if (context.semantic && context.semantic.length > 0) {
                    hoverContent.appendMarkdown('\n**Semantic Memory (Reference):**\n');
                    context.semantic.slice(0, 3).forEach((chunk: any) => {
                        hoverContent.appendMarkdown(`- ${chunk.source}: ${chunk.content.substring(0, 100)}...\n`);
                    });
                }

                if (searchResults.results && searchResults.results.length > 0) {
                    hoverContent.appendMarkdown('\n**Related Documentation:**\n');
                    searchResults.results.slice(0, 3).forEach((result: any) => {
                        hoverContent.appendMarkdown(`- ${result.source || 'Unknown'}: ${result.content.substring(0, 100)}...\n`);
                    });
                }

                hoverContent.appendMarkdown('\n---\n\n');
                hoverContent.appendMarkdown('_[Synapse Claude Plugin]_');

                return new vscode.Hover(hoverContent);
            } catch (error) {
                console.error('Hover provider failed:', error);
                // Return a simple hover with error info
                const errorContent = new vscode.MarkdownString();
                errorContent.appendMarkdown(`### Synapse Analysis Error\n\nFailed to retrieve context for \`${word}\``);
                return new vscode.Hover(errorContent);
            }
        }

        return null;
    }
}