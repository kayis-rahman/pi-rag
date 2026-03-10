//package com.synapse.agent.tools;
//
//import com.synapse.memory.CodeMatch;
//import com.synapse.memory.semantic.SemanticMemoryService;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.stereotype.Component;
//
//import java.util.List;
//
//@Component
//public class CodeSearchTool {
//
//    @Autowired
//    private SemanticMemoryService semanticMemoryService;
//
//    public String searchCode(String query) {
//        List<CodeMatch> results = semanticMemoryService.searchSimilarCode(query, 5);
//        return formatResults(results);
//    }
//
//    private String formatResults(List<CodeMatch> results) {
//        StringBuilder sb = new StringBuilder();
//        sb.append("Code search results:\n");
//        for (CodeMatch match : results) {
//            sb.append("- ").append(match.getFilePath())
//              .append(" (Score: ").append(match.getSimilarityScore()).append(")\n");
//        }
//        return sb.toString();
//    }
//}