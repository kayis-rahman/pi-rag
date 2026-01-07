/**
 * Synapse Auto-Learning Plugin for OpenCode
 *
 * Hooks: tool.execute.before, tool.execute.after
 * Purpose: Automatically extract facts and episodes from agent conversations
 * Mode: Heuristic extraction only (no LLM)
 *
 * Usage: Configure via rag_config.json -> universal_hooks -> adapters -> opencode
 */

import type { PluginInput, Hooks } from "@opencode-ai/plugin";

/**
 * Synapse Plugin Configuration
 */
interface SynapseConfig {
  enabled: boolean;
  priority: number;
  analyze_after_tools: string[];
  min_message_length: number;
  skip_patterns: string[];
  rag_project_id: string;
  async_processing: boolean;
  extraction_mode: string;
}

/**
 * Synapse Auto-Learning Plugin
 */
const SynapseAutoLearningPlugin = async (ctx: PluginInput): Promise<Hooks> => {
  // Load configuration
  const config: SynapseConfig = {
    enabled: true,
    priority: 1,
    analyze_after_tools: ["rag.add_fact", "rag.add_episode", "rag.search", "rag.get_context", "rag.ingest_file"],
    min_message_length: 10,
    skip_patterns: ["^test$", "^hello$", "^help$"],
    rag_project_id: "synapse",
    async_processing: true,
    extraction_mode: "heuristic"
  };

  // Return hooks object
  return {
    /**
     * Hook called before tool execution
     * Analyzes conversation after configured tools execute
     */
    "tool.execute.before": async (input, output) => {
      const startTime = Date.now();

      try {
        // Check if plugin is enabled
        if (!config.enabled) {
          return;
        }

        // Check if this tool should trigger analysis
        if (!config.analyze_after_tools.includes(input.tool)) {
          return;
        }

        // Get user message if available from SDK
        const userMessage = (input as any).userMessage || (input as any).message || "";
        const lastAgentResponse = (input as any).lastAgentResponse || (input as any).agentResponse || "";

        // Apply min_message_length filter
        if (userMessage.length > 0 && userMessage.length < config.min_message_length) {
          return;
        }

        // Apply skip_patterns filter
        for (const pattern of config.skip_patterns) {
          try {
            const regex = new RegExp(pattern, 'i');
            if (regex.test(userMessage)) {
              return;
            }
          } catch (error) {
            // Invalid pattern - skip silently
          }
        }

        // Try to call RAG tool if we have context
        try {
          if (userMessage.length > 0 || lastAgentResponse.length > 0) {
            await ctx.tools.call("rag.analyze_conversation", {
              project_id: config.rag_project_id,
              user_message: userMessage,
              agent_response: lastAgentResponse,
              context: {
                tool_name: input.tool,
                tool_arguments: input.arguments,
                timestamp: new Date().toISOString()
              },
              auto_store: true,
              extraction_mode: config.extraction_mode,
              return_only: false
            });
          }
        } catch (ragError) {
          // RAG tool call failed silently
        }

        return;
      } catch (error) {
        // Hook error - continue silently
        return;
      }
    },

    /**
     * Hook called after tool execution
     * Tracks tool execution
     */
    "tool.execute.after": async (input, output) => {
      try {
        if (!config.enabled) {
          return;
        }

        // Hook completed silently
        return;
      } catch (error) {
        // Hook error - continue silently
        return;
      }
    }
  };
};

/**
 * Helper function to call RAG tool
 * Note: This requires access to ctx.client which is provided by OpenCode
 */
async function callRAGTool(client: any, toolName: string, args: any): Promise<any> {
  try {
    const result = await client.tools.call(toolName, args);
    return result;
  } catch (error) {
    // RAG tool call failed - throw to allow error handling
    throw error;
  }
}

export default SynapseAutoLearningPlugin;
