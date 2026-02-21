import * as vscode from 'vscode';
import { SynapseMcpClient } from '../mcp/mcpClientEnhanced';

export class CodeLensProvider implements vscode.CodeLensProvider {
    private mcpClient: SynapseMcpClient;

    constructor(mcpClient: SynapseMcpClient) {
        this.mcpClient = mcpClient;
    }

    async provideCodeLenses(
        document: vscode.TextDocument,
        token: vscode.CancellationToken
    ): Promise<vscode.CodeLens[]> {
        const codeLenses: vscode.CodeLens[] = [];

        // Add a CodeLens for each function/method in the document
        const text = document.getText();

        // Simple pattern matching to find functions and methods
        const lines = text.split('\n');
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();

            // Look for function declarations
            if (line.startsWith('function ') || line.includes('function') ||
                line.startsWith('def ') || line.includes('def ')) {
                const range = new vscode.Range(i, 0, i, 0);
                const command = {
                    command: 'synapse.analyze',
                    title: '🔍 Analyze Code',
                    tooltip: 'Analyze this code with Synapse'
                };

                codeLenses.push(new vscode.CodeLens(range, command));
            }
        }

        return codeLenses;
    }

    resolveCodeLens(
        codeLens: vscode.CodeLens,
        token: vscode.CancellationToken
    ): vscode.ProviderResult<vscode.CodeLens> {
        return codeLens;
    }
}