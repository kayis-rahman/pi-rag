/**
 * Pattern Matcher for Synapse Claude Plugin
 * Recognizes code patterns and relationships for semantic analysis
 */

import * as vscode from 'vscode';
import { AstParser } from './astParser';

export class PatternMatcher {
    /**
     * Match code patterns and extract relationships
     */
    static matchPatterns(text: string, language: string): any {
        const ast = AstParser.parseCode(text, language);
        const patterns = {
            imports: [],
            functions: [],
            classes: [],
            variables: [],
            methods: []
        };

        // Simple pattern matching based on language
        const lines = text.split('\n');

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();

            // Import patterns
            if (line.startsWith('import ') || line.startsWith('from ')) {
                patterns.imports.push({
                    line: i + 1,
                    content: line,
                    type: 'import'
                });
            }
            // Function definitions
            else if (line.startsWith('function ') || line.includes('function') ||
                     line.startsWith('def ') || line.includes('def ')) {
                patterns.functions.push({
                    line: i + 1,
                    content: line,
                    type: 'function'
                });
            }
            // Class definitions
            else if (line.startsWith('class ')) {
                patterns.classes.push({
                    line: i + 1,
                    content: line,
                    type: 'class'
                });
            }
            // Method/function calls
            else if (line.includes('(') && line.includes(')') &&
                     !line.includes('==') && !line.includes('===') &&
                     !line.includes('import ') && !line.includes('from ')) {
                patterns.methods.push({
                    line: i + 1,
                    content: line,
                    type: 'method-call'
                });
            }
            // Variable assignments
            else if (line.includes('=') && !line.includes('==') && !line.includes('===')) {
                patterns.variables.push({
                    line: i + 1,
                    content: line,
                    type: 'variable'
                });
            }
        }

        return {
            ast: ast,
            patterns: patterns,
            language: language
        };
    }

    /**
     * Extract semantic relationships from parsed code
     */
    static extractRelationships(patternData: any): any {
        const relationships = {
            dependencies: [],
            usages: [],
            inheritance: [],
            calls: []
        };

        const patterns = patternData.patterns;

        // Build dependency relationships
        patterns.imports.forEach((imp: any) => {
            relationships.dependencies.push({
                type: 'import',
                from: imp.line,
                to: imp.content,
                source: 'pattern-matcher'
            });
        });

        // Build usage relationships
        patterns.functions.forEach((func: any) => {
            relationships.usages.push({
                type: 'function',
                name: func.content,
                line: func.line,
                source: 'pattern-matcher'
            });
        });

        return relationships;
    }
}