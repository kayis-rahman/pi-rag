//package com.sparkage.timebeam.presentation.controller;
//
//import com.fasterxml.jackson.databind.ObjectMapper;
//import com.sparkage.timebeam.TimeBeamBackendApplication;
//import com.sparkage.timebeam.presentation.dto.TimerActionDto;
//import com.sparkage.timebeam.presentation.dto.TimerStateDto;
//import org.junit.jupiter.api.BeforeEach;
//import org.junit.jupiter.api.Test;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
//import org.springframework.boot.test.context.SpringBootTest;
//import org.springframework.http.MediaType;
//import org.springframework.test.context.ActiveProfiles;
//import org.springframework.test.web.servlet.MockMvc;
//import org.springframework.test.web.servlet.setup.MockMvcBuilders;
//import org.springframework.transaction.annotation.Transactional;
//import org.springframework.web.context.WebApplicationContext;
//
//import java.time.Instant;
//import java.util.Base64;
//
//import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
//import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
//import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
//import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
//
//import org.springframework.security.test.context.support.WithMockUser;
//
//@SpringBootTest(classes = TimeBeamBackendApplication.class)
//@AutoConfigureWebMvc
//@ActiveProfiles("test")
//@Transactional
//public class TimerSyncIntegrationTest {
//
//    @Autowired
//    private WebApplicationContext context;
//
//    @Autowired
//    private ObjectMapper objectMapper;
//
//    private MockMvc mockMvc;
//
//    // Test devices (simulating different devices for the same user)
//    private final String deviceId1 = "test-device-1";
//    private final String deviceId2 = "test-device-2";
//    private final String testUserId = "88475a64-7bd3-45ff-a33e-d1617c1e349e"; // Must match TestSecurityConfig.TEST_USER_ID
//    private final String testPassword = "password";
//
//    @BeforeEach
//    void setUp() {
//        mockMvc = MockMvcBuilders
//                .webAppContextSetup(context)
//                .apply(springSecurity())
//                .build();
//
//        // Setup test data will be done in individual tests
//    }
//
//    // ============================================================================
//    // BASIC COLLABORATIVE CONTROL TESTS
//    // ============================================================================
//
//    @Test
//    @WithMockUser(username = "88475a64-7bd3-45ff-a33e-d1617c1e349e")
//    public void testDeviceAStartsTimer_DeviceBSeesRunning() throws Exception {
//        // Device A starts timer
//        TimerStateDto startState = createTimerState(true, "work", 1500);
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .header("Authorization", createAuthHeader())
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(startState)))
//                .andExpect(status().isOk());
//
//        // Device B pulls timer state and sees it running
//        mockMvc.perform(get("/api/sessions/timer/state")
//                .header("Authorization", createAuthHeader()))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(true))
//                .andExpect(jsonPath("$.phase").value("work"))
//                .andExpect(jsonPath("$.remainingSeconds").value(1500));
//    }
//
//    @Test
//    public void testDeviceBPausesTimer_DeviceASeesPaused() throws Exception {
//        // First start the timer
//        TimerStateDto startState = createTimerState(true, "work", 1500);
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .with(httpBasic(testUserId, testPassword))
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(startState)))
//                .andExpect(status().isOk());
//
//        // Device B pauses the timer
//        TimerStateDto pauseState = createTimerState(false, "work", 1200);
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .with(httpBasic(testUserId, testPassword))
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(pauseState)))
//                .andExpect(status().isOk());
//
//        // Device A pulls timer state and sees it paused
//        mockMvc.perform(get("/api/sessions/timer/state")
//                .with(httpBasic(testUserId, testPassword)))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(false))
//                .andExpect(jsonPath("$.remainingSeconds").value(1200));
//    }
//
//    @Test
//
//    public void testDeviceAResetsTimer_DeviceBSeesReset() throws Exception {
//        // First start the timer
//        TimerStateDto startState = createTimerState(true, "work", 1500);
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(startState)))
//                .andExpect(status().isOk());
//
//        // Device A resets the timer
//        TimerStateDto resetState = createTimerState(false, "work", 1500);
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(resetState)))
//                .andExpect(status().isOk());
//
//        // Device B pulls timer state and sees it reset
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(false))
//                .andExpect(jsonPath("$.remainingSeconds").value(1500));
//    }
//
//    // ============================================================================
//    // CONFLICT RESOLUTION TESTS
//    // ============================================================================
//
//    @Test
//
//    public void testSimultaneousChanges_NewerTimestampWins() throws Exception {
//        // Device A sends update with timestamp T1
//        TimerStateDto stateT1 = createTimerState(true, "work", 1500);
//        stateT1.setLastModifiedTimestamp(Instant.parse("2025-12-03T10:00:00Z"));
//
//        // Device B sends update with timestamp T2 (newer)
//        TimerStateDto stateT2 = createTimerState(false, "break", 300);
//        stateT2.setLastModifiedTimestamp(Instant.parse("2025-12-03T10:00:01Z"));
//
//        // Send both updates (simulate concurrent requests)
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(stateT1)))
//                .andExpect(status().isOk());
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(stateT2)))
//                .andExpect(status().isOk());
//
//        // Verify newer state (T2) is persisted
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(false))
//                .andExpect(jsonPath("$.phase").value("break"))
//                .andExpect(jsonPath("$.remainingSeconds").value(300));
//    }
//
//    @Test
//
//    public void testSameTimestamp_SecondUpdateAccepted() throws Exception {
//        Instant sameTimestamp = Instant.parse("2025-12-03T10:00:00Z");
//
//        // Device A sends update
//        TimerStateDto stateA = createTimerState(true, "work", 1500);
//        stateA.setLastModifiedTimestamp(sameTimestamp);
//
//        // Device B sends update with same timestamp
//        TimerStateDto stateB = createTimerState(false, "break", 300);
//        stateB.setLastModifiedTimestamp(sameTimestamp);
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(stateA)))
//                .andExpect(status().isOk());
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(stateB)))
//                .andExpect(status().isOk());
//
//        // Second update should win due to same timestamp acceptance
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(false))
//                .andExpect(jsonPath("$.phase").value("break"));
//    }
//
//    @Test
//
//    public void testOlderTimestamp_Rejected() throws Exception {
//        // Send newer update first
//        TimerStateDto newState = createTimerState(true, "work", 1500);
//        newState.setLastModifiedTimestamp(Instant.parse("2025-12-03T10:00:01Z"));
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(newState)))
//                .andExpect(status().isOk());
//
//        // Try to send older update - should be accepted but ignored
//        TimerStateDto oldState = createTimerState(false, "break", 300);
//        oldState.setLastModifiedTimestamp(Instant.parse("2025-12-03T10:00:00Z"));
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(oldState)))
//                .andExpect(status().isOk()); // Request succeeds but state unchanged
//
//        // Verify newer state is still persisted
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(true))
//                .andExpect(jsonPath("$.phase").value("work"));
//    }
//
//    // ============================================================================
//    // OFFLINE/ONLINE SYNCHRONIZATION TESTS
//    // ============================================================================
//
//    @Test
//
//    public void testOfflineDeviceComesOnlineWithNewerState() throws Exception {
//        // Simulate: Device was offline, made changes, now coming online
//
//        // Server has old state
//        TimerStateDto serverState = createTimerState(true, "work", 1500);
//        serverState.setLastModifiedTimestamp(Instant.parse("2025-12-03T09:00:00Z"));
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(serverState)))
//                .andExpect(status().isOk());
//
//        // Device comes online with newer state (simulating offline changes)
//        TimerStateDto deviceState = createTimerState(false, "break", 300);
//        deviceState.setLastModifiedTimestamp(Instant.parse("2025-12-03T10:00:00Z"));
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(deviceState)))
//                .andExpect(status().isOk());
//
//        // Verify device's newer state is accepted
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(false))
//                .andExpect(jsonPath("$.phase").value("break"));
//    }
//
//    @Test
//
//    public void testOfflineDeviceComesOnlineWithOlderState() throws Exception {
//        // Server has newer state
//        TimerStateDto serverState = createTimerState(false, "break", 300);
//        serverState.setLastModifiedTimestamp(Instant.parse("2025-12-03T10:00:00Z"));
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(serverState)))
//                .andExpect(status().isOk());
//
//        // Device comes online with older state - should be ignored
//        TimerStateDto deviceState = createTimerState(true, "work", 1500);
//        deviceState.setLastModifiedTimestamp(Instant.parse("2025-12-03T09:00:00Z"));
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(deviceState)))
//                .andExpect(status().isOk());
//
//        // Verify server's newer state is preserved
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(false))
//                .andExpect(jsonPath("$.phase").value("break"));
//    }
//
//    // ============================================================================
//    // EDGE CASES AND ERROR HANDLING
//    // ============================================================================
//
//    @Test
//
//    public void testInvalidDeviceId_Rejected() throws Exception {
//        TimerStateDto state = createTimerState(true, "work", 1500);
//        state.setDeviceId("invalid-device-id");
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(state)))
//                .andExpect(status().isInternalServerError());
//    }
//
//    @Test
//
//    public void testMalformedJson_BadRequest() throws Exception {
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content("{invalid json}"))
//                .andExpect(status().isBadRequest());
//    }
//
//    @Test
//
//    public void testMissingRequiredFields_BadRequest() throws Exception {
//        TimerStateDto incompleteState = new TimerStateDto();
//        // Missing required fields
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(incompleteState)))
//                .andExpect(status().isBadRequest());
//    }
//
//    @Test
//
//    public void testNegativeRemainingSeconds_ValidationError() throws Exception {
//        TimerStateDto invalidState = createTimerState(true, "work", -100);
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(invalidState)))
//                .andExpect(status().isBadRequest());
//    }
//
//    @Test
//
//    public void testInvalidPhase_Rejected() throws Exception {
//        TimerStateDto invalidState = createTimerState(true, "invalid_phase", 1500);
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(invalidState)))
//                .andExpect(status().isBadRequest());
//    }
//
//    // ============================================================================
//    // RAPID SUCCESSIVE CHANGES TESTS
//    // ============================================================================
//
//    @Test
//
//    public void testRapidSuccessiveChanges_AllProcessed() throws Exception {
//        // Simulate rapid button presses from different devices
//
//        // Start → Pause → Resume → Reset sequence
//        TimerStateDto[] states = {
//            createTimerState(true, "work", 1500),     // Start
//            createTimerState(false, "work", 1200),    // Pause
//            createTimerState(true, "work", 1200),     // Resume
//            createTimerState(false, "work", 1500)     // Reset
//        };
//
//        // Send all changes rapidly
//        for (TimerStateDto state : states) {
//            mockMvc.perform(post("/api/sessions/timer/state")
//                    .contentType(MediaType.APPLICATION_JSON)
//                    .content(objectMapper.writeValueAsString(state)))
//                    .andExpect(status().isOk());
//        }
//
//        // Verify final state (reset)
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(false))
//                .andExpect(jsonPath("$.remainingSeconds").value(1500));
//    }
//
//    // ============================================================================
//    // DEVICE MANAGEMENT TESTS
//    // ============================================================================
//
//    @Test
//
//    public void testMultipleDevicesSameUser_AllCanControl() throws Exception {
//        // Device 1 starts timer
//        TimerStateDto state1 = createTimerState(true, "work", 1500);
//        state1.setDeviceId(deviceId1);
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(state1)))
//                .andExpect(status().isOk());
//
//        // Device 2 can modify it
//        TimerStateDto state2 = createTimerState(false, "break", 300);
//        state2.setDeviceId(deviceId2);
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(state2)))
//                .andExpect(status().isOk());
//
//        // Verify device 2's changes are applied
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(false))
//                .andExpect(jsonPath("$.phase").value("break"))
//                .andExpect(jsonPath("$.deviceId").isNotEmpty());
//    }
//
//    // ============================================================================
//    // TIMER ACTION AND APN TESTS
//    // ============================================================================
//
////    @Test
////    public void testPushTimerActionWithCompleteStateToBackend() throws Exception {
////        TimerActionDto actionDto = createTimerAction("pause", deviceId1);
////        actionDto.setPhase("work");
////        actionDto.setRemainingSeconds(1200);
////        actionDto.setIsRunning(false);
////        actionDto.setWorkDuration(25);
////        actionDto.setBreakDuration(5);
////        actionDto.setLongBreakDuration(15);
////        actionDto.setAutoStartNextSession(true);
////        actionDto.setShortBreaksCompleted(2);
////
////        mockMvc.perform(post("/api/sessions/timer/action")
////                .contentType(MediaType.APPLICATION_JSON)
////                .content(objectMapper.writeValueAsString(actionDto)))
////                .andExpect(status().isOk());
////
////        // Verify complete state was stored
////        mockMvc.perform(get("/api/sessions/timer/state"))
////                .andExpect(status().isOk())
////                .andExpect(jsonPath("$.phase").value("work"))
////                .andExpect(jsonPath("$.remainingSeconds").value(1200))
////                .andExpect(jsonPath("$.isRunning").value(false))
////                .andExpect(jsonPath("$.workDuration").value(25))
////                .andExpect(jsonPath("$.breakDuration").value(5))
////                .andExpect(jsonPath("$.longBreakDuration").value(15))
////                .andExpect(jsonPath("$.autoStartNextSession").value(true))
////                .andExpect(jsonPath("$.shortBreaksCompleted").value(2));
////    }
//
////    @Test
////    public void testApnNotificationSendingDoesNotFailRequest() throws Exception {
////        // Test that even if APN sending fails, the timer action still succeeds
////        TimerActionDto actionDto = createTimerAction("start", deviceId1);
////
////        // This should succeed even if APN notifications fail internally
////        mockMvc.perform(post("/api/sessions/timer/action")
////                .contentType(MediaType.APPLICATION_JSON)
////                .content(objectMapper.writeValueAsString(actionDto)))
////                .andExpect(status().isOk());
////    }
//
//    // ============================================================================
//    // SESSION CONTROLLER AND USER RESOLUTION TESTS
//    // ============================================================================
//
////    @Test
////    public void testSessionControllerUserIdResolution() throws Exception {
////        // Test with valid user
////        TimerActionDto actionDto = createTimerAction("start", deviceId1);
////
////        mockMvc.perform(post("/api/sessions/timer/action")
////                .with(httpBasic(testUserId, testPassword))
////                .contentType(MediaType.APPLICATION_JSON)
////                .content(objectMapper.writeValueAsString(actionDto)))
////                .andExpect(status().isOk());
////    }
//
////    @Test
////    public void testSessionControllerInvalidUserReturns401() throws Exception {
////        TimerActionDto actionDto = createTimerAction("start", deviceId1);
////
////        mockMvc.perform(post("/api/sessions/timer/action")
////                .with(httpBasic("invalid-user", "password"))
////                .contentType(MediaType.APPLICATION_JSON)
////                .content(objectMapper.writeValueAsString(actionDto)))
////                .andExpect(status().isUnauthorized());
////    }
//
//    @Test
//    public void testTimerStateRepositoryQueriesWithLocking() throws Exception {
//        // Test that repository queries work with the updated locking mechanism
//        TimerStateDto state = createTimerState(true, "work", 1500);
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(state)))
//                .andExpect(status().isOk());
//
//        // Verify retrieval works
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(true));
//    }
//
//    // ============================================================================
//    // TIMER STATE VALIDATION TESTS
//    // ============================================================================
//
//    @Test
//
//    public void testTimerStateBoundaries_ValidValuesAccepted() throws Exception {
//        // Test boundary values
//        TimerStateDto boundaryState = new TimerStateDto();
//        boundaryState.setPhase("work");
//        boundaryState.setRemainingSeconds(0);  // Minimum valid value
//        boundaryState.setIsRunning(false);
//        boundaryState.setWorkDuration(1);      // Minimum valid duration
//        boundaryState.setBreakDuration(1);
//        boundaryState.setLongBreakDuration(1);
//        boundaryState.setAutoStartNextSession(true);
//        boundaryState.setShortBreaksCompleted(0);
//        boundaryState.setLastModifiedTimestamp(Instant.now());
//        boundaryState.setDeviceId(deviceId1);
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(boundaryState)))
//                .andExpect(status().isOk());
//    }
//
//    // ============================================================================
//    // DEVICE REGISTRATION AND MISSING DEVICE TESTS
//    // ============================================================================
//
////    @Test
////    public void testPushTimerActionSucceedsWithoutDeviceRegistration() throws Exception {
////        // Test that timer actions can be pushed even when device is not registered
////        TimerActionDto actionDto = createTimerAction("start", "unregistered-device-123");
////
////        mockMvc.perform(post("/api/sessions/timer/action")
////                .contentType(MediaType.APPLICATION_JSON)
////                .content(objectMapper.writeValueAsString(actionDto)))
////                .andExpect(status().isOk());
////
////        // Verify state was created
////        mockMvc.perform(get("/api/sessions/timer/state"))
////                .andExpect(status().isOk())
////                .andExpect(jsonPath("$.phase").value("work"))
////                .andExpect(jsonPath("$.remainingSeconds").value(0)) // default from convertActionToState
////                .andExpect(jsonPath("$.isRunning").value(false));
////    }
//
//    @Test
//    public void testGracefulHandlingOfMissingDeviceInPushTimerState() throws Exception {
//        // This test verifies that pushTimerState handles missing devices gracefully
//        // by logging a warning and proceeding without device tracking
//        TimerStateDto state = createTimerState(true, "work", 1500);
//        state.setDeviceId("non-existent-device");
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(state)))
//                .andExpect(status().isOk());
//    }
//
////    @Test
////    public void testConvertTimerActionToCompleteState() throws Exception {
////        // Test the conversion logic with null values getting defaults
////        TimerActionDto actionDto = new TimerActionDto();
////        actionDto.setAction("start");
////        actionDto.setTimestamp(Instant.now());
////        actionDto.setDeviceId(deviceId1);
////        // Leave other fields null to test defaults
////
////        mockMvc.perform(post("/api/sessions/timer/action")
////                .contentType(MediaType.APPLICATION_JSON)
////                .content(objectMapper.writeValueAsString(actionDto)))
////                .andExpect(status().isOk());
////
////        // Verify defaults were applied
////        mockMvc.perform(get("/api/sessions/timer/state"))
////                .andExpect(status().isOk())
////                .andExpect(jsonPath("$.phase").value("work")) // default phase
////                .andExpect(jsonPath("$.remainingSeconds").value(0)) // default remaining
////                .andExpect(jsonPath("$.isRunning").value(false)) // default running
////                .andExpect(jsonPath("$.workDuration").value(25)) // default work duration
////                .andExpect(jsonPath("$.breakDuration").value(5)) // default break duration
////                .andExpect(jsonPath("$.longBreakDuration").value(15)); // default long break
////    }
//
//    // ============================================================================
//    // OPTIMISTIC LOCKING AND CONFLICT RESOLUTION TESTS
//    // ============================================================================
//
//    @Test
//    public void testOptimisticLockingWithConflictResolution() throws Exception {
//        // Create initial state
//        TimerStateDto initialState = createTimerState(true, "work", 1500);
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(initialState)))
//                .andExpect(status().isOk());
//
//        // Simulate version conflict by updating state rapidly
//        TimerStateDto update1 = createTimerState(false, "break", 300);
//        TimerStateDto update2 = createTimerState(true, "work", 1200);
//
//        // Both updates should succeed due to retry mechanism
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(update1)))
//                .andExpect(status().isOk());
//
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(update2)))
//                .andExpect(status().isOk());
//
//        // Verify final state (last update wins)
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(true))
//                .andExpect(jsonPath("$.phase").value("work"));
//    }
//
//    @Test
//    public void testPessimisticLockingRemovalForBackwardsCompatibility() throws Exception {
//        // Test that the repository method without @Lock still works
//        TimerStateDto state = createTimerState(true, "work", 1500);
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(state)))
//                .andExpect(status().isOk());
//
//        // Verify state can be retrieved
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.isRunning").value(true));
//    }
//
//    // ============================================================================
//    // CONCURRENT UPDATE TESTS
//    // ============================================================================
//
//    @Test
//    public void testConcurrentTimerActionUpdates_SucceedsWithRetry() throws Exception {
//        // Setup initial state
//        TimerStateDto initialState = createTimerState(true, "work", 1500);
//        mockMvc.perform(post("/api/sessions/timer/state")
//                .contentType(MediaType.APPLICATION_JSON)
//                .content(objectMapper.writeValueAsString(initialState)))
//                .andExpect(status().isOk());
//
//        // Simulate concurrent updates using multiple threads
//        java.util.concurrent.ExecutorService executor = java.util.concurrent.Executors.newFixedThreadPool(3);
//        java.util.concurrent.CountDownLatch latch = new java.util.concurrent.CountDownLatch(1);
//        java.util.concurrent.atomic.AtomicInteger successCount = new java.util.concurrent.atomic.AtomicInteger(0);
//        java.util.concurrent.atomic.AtomicInteger failureCount = new java.util.concurrent.atomic.AtomicInteger(0);
//
//        Runnable updateTask = () -> {
//            try {
//                latch.await(); // Wait for all threads to be ready
//                TimerStateDto updateState = createTimerState(false, "break", 300);
//                updateState.setDeviceId(deviceId1);
//                int status = mockMvc.perform(post("/api/sessions/timer/state")
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(objectMapper.writeValueAsString(updateState)))
//                        .andReturn().getResponse().getStatus();
//                if (status == 200) {
//                    successCount.incrementAndGet();
//                } else {
//                    failureCount.incrementAndGet();
//                }
//            } catch (Exception e) {
//                failureCount.incrementAndGet();
//            }
//        };
//
//        // Submit 3 concurrent update tasks
//        for (int i = 0; i < 3; i++) {
//            executor.submit(updateTask);
//        }
//
//        // Start all updates simultaneously
//        latch.countDown();
//
//        // Wait for completion
//        executor.shutdown();
//        executor.awaitTermination(10, java.util.concurrent.TimeUnit.SECONDS);
//
//        // At least one update should succeed (the optimistic locking with retry should handle concurrency)
//        org.junit.jupiter.api.Assertions.assertTrue(successCount.get() >= 1, "At least one concurrent update should succeed");
//        // Some may fail due to optimistic locking, but not all
//        org.junit.jupiter.api.Assertions.assertTrue(failureCount.get() <= 2, "No more than 2 updates should fail due to concurrency");
//
//        // Verify final state is consistent
//        mockMvc.perform(get("/api/sessions/timer/state"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.phase").value("break")) // Should be the updated phase
//                .andExpect(jsonPath("$.isRunning").value(false));
//    }
//
//    // ============================================================================
//    // HELPER METHODS
//    // ============================================================================
//
//    private String createAuthHeader() {
//        String credentials = testUserId + ":" + testPassword;
//        String encodedCredentials = Base64.getEncoder().encodeToString(credentials.getBytes());
//        return "Basic " + encodedCredentials;
//    }
//
//    private TimerStateDto createTimerState(boolean isRunning, String phase, int remainingSeconds) {
//        TimerStateDto state = new TimerStateDto();
//        state.setPhase(phase);
//        state.setRemainingSeconds(remainingSeconds);
//        state.setIsRunning(isRunning);
//        state.setWorkDuration(1500);
//        state.setBreakDuration(300);
//        state.setLongBreakDuration(900);
//        state.setAutoStartNextSession(true);
//        state.setShortBreaksCompleted(0);
//        state.setLastModifiedTimestamp(Instant.now());
//        state.setDeviceId(deviceId1);
//        return state;
//    }
//
////    private TimerActionDto createTimerAction(String action, String deviceId) {
////        TimerActionDto actionDto = new TimerActionDto();
////        actionDto.setAction(action);
////        actionDto.setTimestamp(Instant.now());
////        actionDto.setDeviceId(deviceId);
////        actionDto.setPhase("work");
////        actionDto.setRemainingSeconds(1500);
////        actionDto.setIsRunning(true);
////        actionDto.setWorkDuration(25);
////        actionDto.setBreakDuration(5);
////        actionDto.setLongBreakDuration(15);
////        actionDto.setAutoStartNextSession(true);
////        actionDto.setShortBreaksCompleted(0);
////        return actionDto;
////    }
//}
