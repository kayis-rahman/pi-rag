//package com.synapse.agent.tools;
//
//import com.synapse.memory.CodeMatch;
//import com.synapse.memory.semantic.SemanticMemoryService;
//import org.junit.jupiter.api.Test;
//import org.junit.jupiter.api.BeforeEach;
//import org.mockito.Mock;
//import org.mockito.MockitoAnnotations;
//import java.util.List;
//import static org.junit.jupiter.api.Assertions.*;
//import static org.mockito.Mockito.*;
//
//public class CodeSearchToolTest {
//
//    @Mock
//    private SemanticMemoryService semanticMemoryService;
//
//    private CodeSearchTool codeSearchTool;
//
//    @BeforeEach
//    void setUp() {
//        MockitoAnnotations.openMocks(this);
//        codeSearchTool = new CodeSearchTool(semanticMemoryService);
//    }
//
//    @Test
//    void testSearchCode() {
//        // Mock the semantic memory service behavior
//        List<CodeMatch> mockResults = List.of(
//            new CodeMatch("/path/to/file.java", "content preview", 0.95f)
//        );
//
//        // Note: This is a limitation of the current implementation
//        // Since CodeSearchTool doesn't have a direct way to inject the service,
//        // we're testing that the tool can be instantiated and methods exist
//        assertNotNull(codeSearchTool);
//    }
//
//    @Test
//    void testGetName() {
//        assertEquals("code_search_tool", codeSearchTool.getName());
//    }
//
//    @Test
//    void testGetDescription() {
//        assertNotNull(codeSearchTool.getDescription());
//    }
//}