import * as vscode from 'vscode';
import { SynapseMcpClient } from './mcp/mcpClientEnhanced';
import { CodeAnalyzer } from './analysis/codeAnalyzer';
import { CodeLensProvider } from './ide/codeLensProvider';
import { HoverProvider } from './ide/hoverProvider';

export async function activate(context: vscode.ExtensionContext) {
    console.log('Synapse Claude Plugin is now active!');

    // Initialize MCP client
    const mcpClient = new SynapseMcpClient();

    // Initialize code analyzer
    const codeAnalyzer = new CodeAnalyzer(mcpClient);

    // Register commands
    const analyzeCommand = vscode.commands.registerCommand('synapse.analyze', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showInformationMessage('No active text editor');
            return;
        }

        const document = editor.document;
        const text = document.getText();

        try {
            const analysis = await codeAnalyzer.analyzeCode(document);
            vscode.window.showInformationMessage(`Analysis complete: ${analysis.message || 'Success'}`);
        } catch (error) {
            vscode.window.showErrorMessage(`Analysis failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    });

    const generateDocsCommand = vscode.commands.registerCommand('synapse.generateDocs', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showInformationMessage('No active text editor');
            return;
        }

        try {
            const documentation = await codeAnalyzer.generateDocumentation(editor.document);
            vscode.window.showInformationMessage('Documentation generated successfully');
        } catch (error) {
            vscode.window.showErrorMessage(`Documentation generation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    });

    const searchKnowledgeCommand = vscode.commands.registerCommand('synapse.searchKnowledge', async () => {
        const query = await vscode.window.showInputBox({
            prompt: 'Enter your knowledge search query',
            placeHolder: 'e.g., How to implement REST API in Python?'
        });

        if (!query) {
            return;
        }

        try {
            const results = await mcpClient.search(query, 'all', 10);
            const resultText = JSON.stringify(results, null, 2);

            const panel = vscode.window.createWebviewPanel(
                'synapseKnowledgeResults',
                'Synapse Knowledge Results',
                vscode.ViewColumn.One,
                {}
            );

            panel.webview.html = `
                <!DOCTYPE html>
                <html>
                <head>
                    <style>
                        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe WPC', 'Segoe UI', system-ui, 'Ubuntu', 'Droid Sans', sans-serif; }
                        pre { white-space: pre-wrap; word-wrap: break-word; }
                    </style>
                </head>
                <body>
                    <h2>Search Results for: "${query}"</h2>
                    <pre>${resultText}</pre>
                </body>
                </html>
            `;
        } catch (error) {
            vscode.window.showErrorMessage(`Search failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    });

    // Register providers
    const codeLensProvider = new CodeLensProvider(mcpClient);
    const codeLensDisposable = vscode.languages.registerCodeLensProvider('*', codeLensProvider);

    const hoverProvider = new HoverProvider(mcpClient);
    const hoverDisposable = vscode.languages.registerHoverProvider('*', hoverProvider);

    // Add to context subscriptions
    context.subscriptions.push(
        analyzeCommand,
        generateDocsCommand,
        searchKnowledgeCommand,
        codeLensDisposable,
        hoverDisposable
    );

    // Show welcome message
    vscode.window.showInformationMessage('Synapse Claude Plugin activated!');
}

export function deactivate() {
    console.log('Synapse Claude Plugin is now deactivated');
}