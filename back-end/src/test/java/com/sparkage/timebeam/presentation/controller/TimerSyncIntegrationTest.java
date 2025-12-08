package com.sparkage.timebeam.presentation.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sparkage.timebeam.TimeBeamBackendApplication;
import com.sparkage.timebeam.presentation.dto.TimerStateDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.Instant;
import java.util.Base64;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.springframework.security.test.context.support.WithMockUser;

@SpringBootTest(classes = TimeBeamBackendApplication.class)
@AutoConfigureWebMvc
@ActiveProfiles("test")
@Transactional
public class TimerSyncIntegrationTest {

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private ObjectMapper objectMapper;

    private MockMvc mockMvc;

    // Test devices (simulating different devices for the same user)
    private final String deviceId1 = "test-device-1";
    private final String deviceId2 = "test-device-2";
    private final String testUserId = "88475a64-7bd3-45ff-a33e-d1617c1e349e"; // Must match TestSecurityConfig.TEST_USER_ID
    private final String testPassword = "password";

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(context)
                .apply(springSecurity())
                .build();

        // Setup test data will be done in individual tests
    }

    // ============================================================================
    // BASIC COLLABORATIVE CONTROL TESTS
    // ============================================================================

    @Test
    @WithMockUser(username = "88475a64-7bd3-45ff-a33e-d1617c1e349e")
    public void testDeviceAStartsTimer_DeviceBSeesRunning() throws Exception {
        // Device A starts timer
        TimerStateDto startState = createTimerState(true, "work", 1500);
        mockMvc.perform(post("/api/sessions/timer/state")
                .header("Authorization", createAuthHeader())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(startState)))
                .andExpect(status().isOk());

        // Device B pulls timer state and sees it running
        mockMvc.perform(get("/api/sessions/timer/state")
                .header("Authorization", createAuthHeader()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isRunning").value(true))
                .andExpect(jsonPath("$.phase").value("work"))
                .andExpect(jsonPath("$.remainingSeconds").value(1500));
    }

    @Test
    public void testDeviceBPausesTimer_DeviceASeesPaused() throws Exception {
        // First start the timer
        TimerStateDto startState = createTimerState(true, "work", 1500);
        mockMvc.perform(post("/api/sessions/timer/state")
                .with(httpBasic(testUserId, testPassword))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(startState)))
                .andExpect(status().isOk());

        // Device B pauses the timer
        TimerStateDto pauseState = createTimerState(false, "work", 1200);
        mockMvc.perform(post("/api/sessions/timer/state")
                .with(httpBasic(testUserId, testPassword))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(pauseState)))
                .andExpect(status().isOk());

        // Device A pulls timer state and sees it paused
        mockMvc.perform(get("/api/sessions/timer/state")
                .with(httpBasic(testUserId, testPassword)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isRunning").value(false))
                .andExpect(jsonPath("$.remainingSeconds").value(1200));
    }

    @Test
    
    public void testDeviceAResetsTimer_DeviceBSeesReset() throws Exception {
        // First start the timer
        TimerStateDto startState = createTimerState(true, "work", 1500);
        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(startState)))
                .andExpect(status().isOk());

        // Device A resets the timer
        TimerStateDto resetState = createTimerState(false, "work", 1500);
        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(resetState)))
                .andExpect(status().isOk());

        // Device B pulls timer state and sees it reset
        mockMvc.perform(get("/api/sessions/timer/state"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isRunning").value(false))
                .andExpect(jsonPath("$.remainingSeconds").value(1500));
    }

    // ============================================================================
    // CONFLICT RESOLUTION TESTS
    // ============================================================================

    @Test
    
    public void testSimultaneousChanges_NewerTimestampWins() throws Exception {
        // Device A sends update with timestamp T1
        TimerStateDto stateT1 = createTimerState(true, "work", 1500);
        stateT1.setTimestamp(Instant.parse("2025-12-03T10:00:00Z"));

        // Device B sends update with timestamp T2 (newer)
        TimerStateDto stateT2 = createTimerState(false, "break", 300);
        stateT2.setTimestamp(Instant.parse("2025-12-03T10:00:01Z"));

        // Send both updates (simulate concurrent requests)
        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(stateT1)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(stateT2)))
                .andExpect(status().isOk());

        // Verify newer state (T2) is persisted
        mockMvc.perform(get("/api/sessions/timer/state"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isRunning").value(false))
                .andExpect(jsonPath("$.phase").value("break"))
                .andExpect(jsonPath("$.remainingSeconds").value(300));
    }

    @Test
    
    public void testSameTimestamp_SecondUpdateAccepted() throws Exception {
        Instant sameTimestamp = Instant.parse("2025-12-03T10:00:00Z");

        // Device A sends update
        TimerStateDto stateA = createTimerState(true, "work", 1500);
        stateA.setTimestamp(sameTimestamp);

        // Device B sends update with same timestamp
        TimerStateDto stateB = createTimerState(false, "break", 300);
        stateB.setTimestamp(sameTimestamp);

        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(stateA)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(stateB)))
                .andExpect(status().isOk());

        // Second update should win due to same timestamp acceptance
        mockMvc.perform(get("/api/sessions/timer/state"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isRunning").value(false))
                .andExpect(jsonPath("$.phase").value("break"));
    }

    @Test
    
    public void testOlderTimestamp_Rejected() throws Exception {
        // Send newer update first
        TimerStateDto newState = createTimerState(true, "work", 1500);
        newState.setTimestamp(Instant.parse("2025-12-03T10:00:01Z"));

        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(newState)))
                .andExpect(status().isOk());

        // Try to send older update - should be accepted but ignored
        TimerStateDto oldState = createTimerState(false, "break", 300);
        oldState.setTimestamp(Instant.parse("2025-12-03T10:00:00Z"));

        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(oldState)))
                .andExpect(status().isOk()); // Request succeeds but state unchanged

        // Verify newer state is still persisted
        mockMvc.perform(get("/api/sessions/timer/state"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isRunning").value(true))
                .andExpect(jsonPath("$.phase").value("work"));
    }

    // ============================================================================
    // OFFLINE/ONLINE SYNCHRONIZATION TESTS
    // ============================================================================

    @Test
    
    public void testOfflineDeviceComesOnlineWithNewerState() throws Exception {
        // Simulate: Device was offline, made changes, now coming online

        // Server has old state
        TimerStateDto serverState = createTimerState(true, "work", 1500);
        serverState.setTimestamp(Instant.parse("2025-12-03T09:00:00Z"));
        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(serverState)))
                .andExpect(status().isOk());

        // Device comes online with newer state (simulating offline changes)
        TimerStateDto deviceState = createTimerState(false, "break", 300);
        deviceState.setTimestamp(Instant.parse("2025-12-03T10:00:00Z"));
        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(deviceState)))
                .andExpect(status().isOk());

        // Verify device's newer state is accepted
        mockMvc.perform(get("/api/sessions/timer/state"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isRunning").value(false))
                .andExpect(jsonPath("$.phase").value("break"));
    }

    @Test
    
    public void testOfflineDeviceComesOnlineWithOlderState() throws Exception {
        // Server has newer state
        TimerStateDto serverState = createTimerState(false, "break", 300);
        serverState.setTimestamp(Instant.parse("2025-12-03T10:00:00Z"));
        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(serverState)))
                .andExpect(status().isOk());

        // Device comes online with older state - should be ignored
        TimerStateDto deviceState = createTimerState(true, "work", 1500);
        deviceState.setTimestamp(Instant.parse("2025-12-03T09:00:00Z"));
        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(deviceState)))
                .andExpect(status().isOk());

        // Verify server's newer state is preserved
        mockMvc.perform(get("/api/sessions/timer/state"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isRunning").value(false))
                .andExpect(jsonPath("$.phase").value("break"));
    }

    // ============================================================================
    // EDGE CASES AND ERROR HANDLING
    // ============================================================================

    @Test
    
    public void testInvalidDeviceId_Rejected() throws Exception {
        TimerStateDto state = createTimerState(true, "work", 1500);
        state.setDeviceId("invalid-device-id");

        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(state)))
                .andExpect(status().isInternalServerError());
    }

    @Test
    
    public void testMalformedJson_BadRequest() throws Exception {
        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{invalid json}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    
    public void testMissingRequiredFields_BadRequest() throws Exception {
        TimerStateDto incompleteState = new TimerStateDto();
        // Missing required fields

        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(incompleteState)))
                .andExpect(status().isBadRequest());
    }

    @Test
    
    public void testNegativeRemainingSeconds_ValidationError() throws Exception {
        TimerStateDto invalidState = createTimerState(true, "work", -100);

        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidState)))
                .andExpect(status().isBadRequest());
    }

    @Test
    
    public void testInvalidPhase_Rejected() throws Exception {
        TimerStateDto invalidState = createTimerState(true, "invalid_phase", 1500);

        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidState)))
                .andExpect(status().isBadRequest());
    }

    // ============================================================================
    // RAPID SUCCESSIVE CHANGES TESTS
    // ============================================================================

    @Test
    
    public void testRapidSuccessiveChanges_AllProcessed() throws Exception {
        // Simulate rapid button presses from different devices

        // Start → Pause → Resume → Reset sequence
        TimerStateDto[] states = {
            createTimerState(true, "work", 1500),     // Start
            createTimerState(false, "work", 1200),    // Pause
            createTimerState(true, "work", 1200),     // Resume
            createTimerState(false, "work", 1500)     // Reset
        };

        // Send all changes rapidly
        for (TimerStateDto state : states) {
            mockMvc.perform(post("/api/sessions/timer/state")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(state)))
                    .andExpect(status().isOk());
        }

        // Verify final state (reset)
        mockMvc.perform(get("/api/sessions/timer/state"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isRunning").value(false))
                .andExpect(jsonPath("$.remainingSeconds").value(1500));
    }

    // ============================================================================
    // DEVICE MANAGEMENT TESTS
    // ============================================================================

    @Test
    
    public void testMultipleDevicesSameUser_AllCanControl() throws Exception {
        // Device 1 starts timer
        TimerStateDto state1 = createTimerState(true, "work", 1500);
        state1.setDeviceId(deviceId1);
        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(state1)))
                .andExpect(status().isOk());

        // Device 2 can modify it
        TimerStateDto state2 = createTimerState(false, "break", 300);
        state2.setDeviceId(deviceId2);
        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(state2)))
                .andExpect(status().isOk());

        // Verify device 2's changes are applied
        mockMvc.perform(get("/api/sessions/timer/state"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isRunning").value(false))
                .andExpect(jsonPath("$.phase").value("break"))
                .andExpect(jsonPath("$.deviceId").isNotEmpty());
    }

    // ============================================================================
    // TIMER STATE VALIDATION TESTS
    // ============================================================================

    @Test
    
    public void testTimerStateBoundaries_ValidValuesAccepted() throws Exception {
        // Test boundary values
        TimerStateDto boundaryState = new TimerStateDto();
        boundaryState.setPhase("work");
        boundaryState.setRemainingSeconds(0);  // Minimum valid value
        boundaryState.setIsRunning(false);
        boundaryState.setWorkDuration(1);      // Minimum valid duration
        boundaryState.setBreakDuration(1);
        boundaryState.setLongBreakDuration(1);
        boundaryState.setAutoStartNextSession(true);
        boundaryState.setShortBreaksCompleted(0);
        boundaryState.setTimestamp(Instant.now());
        boundaryState.setDeviceId(deviceId1);

        mockMvc.perform(post("/api/sessions/timer/state")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(boundaryState)))
                .andExpect(status().isOk());
    }

    // ============================================================================
    // HELPER METHODS
    // ============================================================================

    private String createAuthHeader() {
        String credentials = testUserId + ":" + testPassword;
        String encodedCredentials = Base64.getEncoder().encodeToString(credentials.getBytes());
        return "Basic " + encodedCredentials;
    }

    private TimerStateDto createTimerState(boolean isRunning, String phase, int remainingSeconds) {
        TimerStateDto state = new TimerStateDto();
        state.setPhase(phase);
        state.setRemainingSeconds(remainingSeconds);
        state.setIsRunning(isRunning);
        state.setWorkDuration(1500);
        state.setBreakDuration(300);
        state.setLongBreakDuration(900);
        state.setAutoStartNextSession(true);
        state.setShortBreaksCompleted(0);
        state.setTimestamp(Instant.now());
        state.setDeviceId(deviceId1);
        return state;
    }
}
