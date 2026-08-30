package com.sparkage.synapse;

import com.sparkage.synapse.infrastructure.persistence.TimerStateRepository;
import com.sparkage.synapse.infrastructure.persistence.UserDeviceRepository;
import com.sparkage.synapse.infrastructure.persistence.UserJpaRepository;
import com.sparkage.synapse.infrastructure.persistence.UserPreferencesRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.PostConstruct;

/**
 * Test data setup utility for integration tests
 * Creates test users, devices, and preferences needed for timer sync tests
 */
@Component
public class TestDataSetup {

    @Autowired
    private UserJpaRepository userRepository;

    @Autowired
    private UserDeviceRepository userDeviceRepository;

    @Autowired
    private UserPreferencesRepository userPreferencesRepository;

    @Autowired
    private TimerStateRepository timerStateRepository;

    @PostConstruct
    @Transactional
    public void setupTestData() {
        // This method will be called after the bean is initialized
        // Test data setup is handled in individual test methods for better control
    }

    /**
     * Clean up all test data between tests
     */
    @Transactional
    public void cleanupTestData() {
        timerStateRepository.deleteAll();
        userDeviceRepository.deleteAll();
        userPreferencesRepository.deleteAll();
        userRepository.deleteAll();
    }
}
