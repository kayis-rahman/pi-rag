/**
 * MCP Tool Schemas for Synapse Integration
 */

export const MCP_TOOLS = {
    LIST_PROJECTS: {
        name: 'sy.proj.list',
        description: 'List all projects in RAG memory system',
        inputSchema: {
            type: 'object',
            properties: {
                scope_type: {
                    type: 'string',
                    description: 'Optional filter by scope type (user, project, org, session)'
                }
            }
        }
    },

    LIST_SOURCES: {
        name: 'sy.src.list',
        description: 'List document sources for a project in semantic memory',
        inputSchema: {
            type: 'object',
            required: ['project_id'],
            properties: {
                project_id: {
                    type: 'string',
                    description: 'Project identifier'
                },
                source_type: {
                    type: 'string',
                    description: 'Filter by source type (file, code, web)',
                    enum: ['file', 'code', 'web']
                }
            }
        }
    },

    GET_CONTEXT: {
        name: 'sy.ctx.get',
        description: 'Get comprehensive project context with authority hierarchy',
        inputSchema: {
            type: 'object',
            required: ['project_id'],
            properties: {
                project_id: {
                    type: 'string',
                    description: 'Project identifier'
                },
                context_type: {
                    type: 'string',
                    description: 'Type of context to retrieve',
                    enum: ['all', 'symbolic', 'episodic', 'semantic'],
                    default: 'all'
                },
                query: {
                    type: 'string',
                    description: 'Query for semantic retrieval (required if context_type="semantic" or "all")'
                },
                max_results: {
                    type: 'number',
                    description: 'Maximum results per memory type',
                    default: 10
                }
            }
        }
    },

    SEARCH: {
        name: 'sy.mem.search',
        description: 'Semantic search across all memory types',
        inputSchema: {
            type: 'object',
            required: ['project_id', 'query'],
            properties: {
                project_id: {
                    type: 'string',
                    description: 'Project identifier'
                },
                query: {
                    type: 'string',
                    description: 'Search query'
                },
                memory_type: {
                    type: 'string',
                    description: 'Type of memory to search',
                    enum: ['all', 'symbolic', 'episodic', 'semantic'],
                    default: 'all'
                },
                top_k: {
                    type: 'number',
                    description: 'Number of results',
                    default: 10
                }
            }
        }
    },

    INGEST_FILE: {
        name: 'sy.mem.ingest',
        description: 'Ingest a file into semantic memory with automatic validation and chunking',
        inputSchema: {
            type: 'object',
            required: ['project_id', 'file_path'],
            properties: {
                project_id: {
                    type: 'string',
                    description: 'Project identifier'
                },
                file_path: {
                    type: 'string',
                    description: 'Path to file to ingest'
                },
                source_type: {
                    type: 'string',
                    description: 'Type of source',
                    enum: ['file', 'code', 'web'],
                    default: 'file'
                }
            }
        }
    },

    ADD_FACT: {
        name: 'sy.mem.fact.add',
        description: 'Add a symbolic memory fact (authoritative)',
        inputSchema: {
            type: 'object',
            required: ['project_id', 'fact_key', 'fact_value'],
            properties: {
                project_id: {
                    type: 'string',
                    description: 'Project identifier'
                },
                fact_key: {
                    type: 'string',
                    description: 'The fact key'
                },
                fact_value: {
                    description: 'The fact value (any JSON-serializable type)'
                },
                confidence: {
                    type: 'number',
                    description: 'Confidence level (0.0-1.0)',
                    minimum: 0.0,
                    maximum: 1.0,
                    default: 0.9
                }
            }
        }
    },

    ADD_EPISODE: {
        name: 'sy.mem.ep.add',
        description: 'Add an episodic memory episode (advisory)',
        inputSchema: {
            type: 'object',
            required: ['project_id', 'title', 'content'],
            properties: {
                project_id: {
                    type: 'string',
                    description: 'Project identifier'
                },
                title: {
                    type: 'string',
                    description: 'Episode title'
                },
                content: {
                    type: 'string',
                    description: 'Episode content (situation, action, outcome, lesson)'
                },
                lesson_type: {
                    type: 'string',
                    description: 'Type of lesson',
                    enum: ['general', 'pattern', 'mistake', 'success', 'failure'],
                    default: 'general'
                },
                quality: {
                    type: 'number',
                    description: 'Quality score (0.0-1.0).',
                    minimum: 0.0,
                    maximum: 1.0,
                    default: 0.8
                }
            }
        }
    }
};