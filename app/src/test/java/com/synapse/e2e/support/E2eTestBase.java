package com.synapse.e2e.support;

import org.junit.jupiter.api.Tag;

/**
 * Base class for E2E tests providing shared utilities and common annotations.
 */
@Tag("e2e")
public abstract class E2eTestBase {

    /**
     * Default API base URL for E2E tests.
     */
    protected static final String DEFAULT_API_BASE_URL = "http://localhost:8080";

    /**
     * Get the API base URL from environment variable or use default.
     *
     * @return the API base URL
     */
    protected static String getApiBaseUrl() {
        return System.getenv("API_BASE_URL") != null
                ? System.getenv("API_BASE_URL")
                : DEFAULT_API_BASE_URL;
    }

    /**
     * Sleep for the specified milliseconds.
     *
     * @param millis milliseconds to sleep
     */
    protected static void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
