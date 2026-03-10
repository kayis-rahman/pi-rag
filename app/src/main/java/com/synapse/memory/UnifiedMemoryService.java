//package com.synapse.memory;
//
//import com.synapse.memory.episodic.EpisodicMemoryService;
//import com.synapse.memory.semantic.SemanticMemoryService;
//import com.synapse.memory.knowledgegraph.KnowledgeGraphService;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.stereotype.Service;
//
//import java.util.List;
//
//@Service
//public class UnifiedMemoryService implements MemoryService {
//
//    @Autowired
//    private EpisodicMemoryService episodicMemoryService;
//
//    @Autowired
//    private SemanticMemoryService semanticMemoryService;
//
//    @Autowired
//    private KnowledgeGraphService knowledgeGraphService;
//
//    @Override
//    public void storeEpisode(Episode episode) {
//        episodicMemoryService.storeEpisode(episode.getSessionId(), episode.getContent());
//    }
//
//    @Override
//    public List<Episode> getRecentEpisodes(String sessionId, int limit) {
//        return episodicMemoryService.getRecentEpisodes(sessionId, limit);
//    }
//
//    @Override
//    public void indexCodebase(String codebasePath) {
//        semanticMemoryService.indexCodebase(codebasePath);
//    }
//
//    @Override
//    public List<CodeMatch> searchSimilarCode(String query, int limit) {
//        return semanticMemoryService.searchSimilarCode(query, limit);
//    }
//
//    @Override
//    public void storeRelationship(String entity1, String relationship, String entity2) {
//        knowledgeGraphService.storeRelationship(entity1, relationship, entity2);
//    }
//
//    @Override
//    public List<String> findRelatedConcepts(String concept) {
//        return knowledgeGraphService.findRelatedConcepts(concept);
//    }
//}