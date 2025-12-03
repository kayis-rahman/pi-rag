package com.sparkage.timebeam.presentation.controller;

import java.util.Optional;
import java.util.UUID;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.sparkage.timebeam.application.service.AuthService;
import com.sparkage.timebeam.application.service.UserService;
import com.sparkage.timebeam.infrastructure.external.JwtUtils;
import com.sparkage.timebeam.presentation.dto.AuthRequests;
import com.sparkage.timebeam.presentation.dto.UserDto;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = AuthController.class)
@AutoConfigureMockMvc(addFilters = false)
class AuthControllerTest {
    @Autowired
    private MockMvc mvc;

    @MockBean
    private UserService userService;

    @MockBean
    private AuthService authService;

    @MockBean
    private JwtUtils jwtUtils; // required by controller constructor

    private ObjectMapper om = new ObjectMapper();

    @BeforeEach
    void setUp() {
    }

    @Test
    void register_returnsUserDto() throws Exception {
        AuthRequests.Register r = new AuthRequests.Register("test@x.com", "T");
        UserDto dto = new UserDto(UUID.randomUUID(), "test@x.com", "T");
        when(userService.createUser(anyString(), anyString())).thenReturn(dto);

        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(r)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("test@x.com"));
    }

    @Test
    void login_invalidCredentials_returns401() throws Exception {
        AuthRequests.Login l = new AuthRequests.Login("noone@x.com");
        when(authService.login(anyString())).thenReturn(Optional.empty());

        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(l)))
                .andExpect(status().isUnauthorized());
    }
}
