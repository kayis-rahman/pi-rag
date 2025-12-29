//package com.sparkage.timebeam.presentation.controller;
//
//import java.security.Principal;
//import java.time.Instant;
//import java.util.UUID;
//
//import org.junit.jupiter.api.BeforeEach;
//import org.junit.jupiter.api.Test;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
//import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
//import org.springframework.boot.test.mock.mockito.MockBean;
//import org.springframework.http.MediaType;
//import org.springframework.test.web.servlet.MockMvc;
//
//import com.sparkage.timebeam.application.service.SessionService;
//import com.sparkage.timebeam.infrastructure.external.JwtAuthenticationFilter;
//import com.sparkage.timebeam.infrastructure.external.JwtUtils;
//import com.sparkage.timebeam.presentation.dto.SessionRecordDto;
//
//import static org.mockito.ArgumentMatchers.any;
//import static org.mockito.ArgumentMatchers.eq;
//import static org.mockito.Mockito.when;
//import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
//import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
//import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
//
//@WebMvcTest(controllers = SessionController.class)
//@AutoConfigureMockMvc(addFilters = false)
//class SessionControllerTest {
//    @Autowired
//    private MockMvc mvc;
//
//    @MockBean
//    private SessionService sessionService;
//
//    @MockBean
//    private JwtUtils jwtUtils;
//
//    @MockBean
//    private JwtAuthenticationFilter jwtAuthenticationFilter;
//
//    private final UUID userId = UUID.randomUUID();
//
//    @BeforeEach
//    void setUp() {
//    }
//
//    @Test
//    void start_via_create_withoutStartedAt_authenticated_returns201() throws Exception {
//        // request body only supplies kind -> controller should call start and return 201
//        String kind = "WORK";
//        String body = "{\"kind\":\"WORK\"}";
//
//        SessionRecordDto resp = new SessionRecordDto(UUID.randomUUID(), userId, Instant.now(), 0L, kind);
//        when(sessionService.start(eq(kind), eq(userId))).thenReturn(resp);
//
//        Principal principal = () -> userId.toString();
//
//        mvc.perform(post("/api/sessions")
//                .principal(principal)
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(body))
//                .andExpect(status().isCreated())
//                .andExpect(jsonPath("$.kind").value(kind))
//                .andExpect(jsonPath("$.userId").value(userId.toString()));
//    }
//
//    @Test
//    void create_withStartedAt_authenticated_returns200() throws Exception {
//        String kind = "WORK";
//        Instant startedAt = Instant.parse("2025-11-18T10:00:00Z");
//        String body = String.format("{\"startedAt\":\"%s\",\"durationSeconds\":1500,\"kind\":\"%s\"}", startedAt.toString(), kind);
//
//        // return whatever was passed in but with an id set
//        when(sessionService.create(any(SessionRecordDto.class))).thenAnswer(invocation -> {
//            SessionRecordDto arg = invocation.getArgument(0);
//            if (arg.getId() == null) arg.setId(UUID.randomUUID());
//            return arg;
//        });
//
//        Principal principal = () -> userId.toString();
//
//        mvc.perform(post("/api/sessions")
//                .principal(principal)
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(body))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.kind").value(kind))
//                .andExpect(jsonPath("$.userId").value(userId.toString()))
//                .andExpect(jsonPath("$.startedAt").value(startedAt.toString()));
//    }
//
//    @Test
//    void create_unauthenticated_returns401() throws Exception {
//        String body = "{\"kind\":\"WORK\"}";
//
//        mvc.perform(post("/api/sessions")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(body))
//                .andExpect(status().isUnauthorized());
//    }
//}
