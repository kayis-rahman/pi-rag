//package com.synapse.llm.service;
//
//import com.synapse.llm.api.ChatRequest;
//import com.synapse.llm.api.ChatResponse;
//import com.synapse.llm.config.ChatModel;
//import com.synapse.llm.config.MockChatModel;
//import org.junit.jupiter.api.Test;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.test.autoconfigure.web.reactive.AutoConfigureWebTestClient;
//import org.springframework.boot.test.context.SpringBootTest;
//import org.springframework.boot.test.mock.mockito.MockBean;
//import reactor.core.publisher.Mono;
//import reactor.test.StepVerifier;
//
//import java.util.List;
//
//import static org.junit.jupiter.api.Assertions.*;
//import static org.mockito.Mockito.*;
//
//@SpringBootTest
//@AutoConfigureWebTestClient
//class ReactiveChatServiceTest {
//
//    @MockBean
//    private LlmModelRouter modelRouter;
//
//    @Autowired
//    private ReactiveChatService chatService;
//
//    @Test
//    void testChatReturnsMono() {
//        ChatRequest request = new ChatRequest();
//        request.setModel("claude-sonnet-4-6");
//        request.setMessages(List.of(new ChatRequest.Message("user", "Hello")));
//
//        Mono<ChatResponse> result = chatService.chat(request);
//
//        assertNotNull(result);
//        StepVerifier.create(result)
//            .assertNext(response -> assertNotNull(response))
//            .verifyComplete();
//    }
//
//    @Test
//    void testChatUsesSelectedModel() {
//        ChatRequest request = new ChatRequest();
//        request.setModel("claude-sonnet-4-6");
//        request.setMessages(List.of(new ChatRequest.Message("user", "Test")));
//
//        MockChatModel mockModel = new MockChatModel("claude-sonnet-4-6");
//        when(modelRouter.selectModel("claude-sonnet-4-6")).thenReturn(mockModel);
//
//        Mono<ChatResponse> result = chatService.chat(request);
//
//        StepVerifier.create(result)
//            .assertNext(response -> {
//                assertEquals("claude-sonnet-4-6", response.getModel());
//            })
//            .verifyComplete();
//
//        verify(modelRouter).selectModel("claude-sonnet-4-6");
//    }
//
//    @Test
//    void testChatConstructsResponseCorrectly() {
//        ChatRequest request = new ChatRequest();
//        request.setModel("claude-sonnet-4-6");
//        request.setMessages(List.of(new ChatRequest.Message("user", "Hello")));
//
//        MockChatModel mockModel = new MockChatModel("claude-sonnet-4-6");
//        when(modelRouter.selectModel("claude-sonnet-4-6")).thenReturn(mockModel);
//
//        Mono<ChatResponse> result = chatService.chat(request);
//
//        StepVerifier.create(result)
//            .assertNext(response -> {
//                assertEquals("claude-sonnet-4-6", response.getModel());
//                assertNotNull(response.getId());
//                assertEquals(1, response.getChoices().size());
//                assertEquals("assistant", response.getChoices().get(0).getMessage().getRole());
//                assertEquals("stop", response.getChoices().get(0).getFinishReason());
//            })
//            .verifyComplete();
//    }
//
//    @Test
//    void testChatHandlesEmptyMessages() {
//        ChatRequest request = new ChatRequest();
//        request.setModel("claude-sonnet-4-6");
//        request.setMessages(List.of());
//
//        MockChatModel mockModel = new MockChatModel("claude-sonnet-4-6");
//        when(modelRouter.selectModel("claude-sonnet-4-6")).thenReturn(mockModel);
//
//        Mono<ChatResponse> result = chatService.chat(request);
//
//        StepVerifier.create(result)
//            .assertNext(response -> assertNotNull(response))
//            .verifyComplete();
//    }
//
//    @Test
//    void testChatCalculatesTokenUsage() {
//        ChatRequest request = new ChatRequest();
//        request.setModel("claude-sonnet-4-6");
//        request.setMessages(List.of(new ChatRequest.Message("user", "Test message")));
//
//        MockChatModel mockModel = new MockChatModel("claude-sonnet-4-6");
//        when(modelRouter.selectModel("claude-sonnet-4-6")).thenReturn(mockModel);
//
//        Mono<ChatResponse> result = chatService.chat(request);
//
//        StepVerifier.create(result)
//            .assertNext(response -> {
//                assertNotNull(response.getUsage());
//                assertNotNull(response.getUsage().getTotalTokens());
//                assertTrue(response.getUsage().getTotalTokens() >= 0);
//            })
//            .verifyComplete();
//    }
//}
