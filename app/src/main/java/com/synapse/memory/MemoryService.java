//package com.synapse.memory;
//
//import com.synapse.memory.episodic.EpisodicMemoryService;
//import com.synapse.memory.semantic.SemanticMemoryService;
//import com.synapse.memory.knowledgegraph.KnowledgeGraphService;
//import java.util.List;
//
//public interface MemoryService {
//    void storeEpisode(Episode episode);
//    List<Episode> getRecentEpisodes(String sessionId, int limit);
//    void indexCodebase(String codebasePath);
//    List<CodeMatch> searchSimilarCode(String query, int limit);
//    void storeRelationship(String entity1, String relationship, String entity2);
//    List<String> findRelatedConcepts(String concept);
//}