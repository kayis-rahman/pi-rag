/*
 * Copyright (c) 2026 Synapse AI
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.synapse.embedding;

/**
 * Development configuration for embedding services.
 * This configuration is optimized for development and testing environments
 * with relaxed constraints and enhanced debugging capabilities.
 *
 * @since 2.0
 */
public final class DevelopmentConfiguration implements EmbeddingConfigurationType {

    private static final String ENVIRONMENT_TYPE = "development";

    private final EmbeddingConfiguration configuration;

    /**
     * Creates a new development configuration.
     * Uses optimized settings for rapid development and testing.
     */
    public DevelopmentConfiguration() {
        this.configuration = new EmbeddingConfiguration(
            "text-embedding-3-small",  // Model name
            1536,                      // Dimensions
            50,                        // Batch size
            5,                         // Max retries
            30000L,                    // Timeout in ms
            null,                      // API key (null for local development)
            "http://localhost:8080/embeddings",  // Local endpoint for development
            true,                      // Use cache
            3600                       // Cache TTL in seconds
        );
    }

    /**
     * Creates a new development configuration with custom settings.
     *
     * @param modelName the name of the embedding model
     * @param dimensions the dimensionality of the embedding vectors
     * @param batchSize the batch size for processing embeddings
     * @param maxRetries maximum retry attempts for embedding requests
     * @param timeoutMs timeout in milliseconds for embedding requests
     * @param apiKey optional API key for external embedding services
     * @param endpointUrl optional endpoint URL for external embedding services
     * @param useCache whether to enable caching for embeddings
     * @param cacheTtlSeconds time-to-live for cached embeddings in seconds
     */
    public DevelopmentConfiguration(
            String modelName,
            Integer dimensions,
            Integer batchSize,
            Integer maxRetries,
            Long timeoutMs,
            String apiKey,
            String endpointUrl,
            Boolean useCache,
            Integer cacheTtlSeconds) {

        this.configuration = new EmbeddingConfiguration(
            modelName,
            dimensions,
            batchSize,
            maxRetries,
            timeoutMs,
            apiKey,
            endpointUrl,
            useCache,
            cacheTtlSeconds
        );
    }

    @Override
    public EmbeddingConfiguration getConfiguration() {
        return configuration;
    }

    @Override
    public String getEnvironmentType() {
        return ENVIRONMENT_TYPE;
    }

    /**
     * Gets a development-specific configuration with debug logging enabled.
     *
     * @return a new development configuration with debug settings
     */
    public static DevelopmentConfiguration debug() {
        return new DevelopmentConfiguration(
            "text-embedding-3-small",
            1536,
            50,
            5,
            30000L,
            null,
            "http://localhost:8080/embeddings",
            true,
            3600
        );
    }

    /**
     * Gets a development configuration optimized for testing.
     *
     * @return a new development configuration optimized for testing
     */
    public static DevelopmentConfiguration testing() {
        return new DevelopmentConfiguration(
            "text-embedding-3-small",
            1536,
            10,
            3,
            10000L,
            null,
            "http://localhost:8080/embeddings",
            false,
            1800
        );
    }
}