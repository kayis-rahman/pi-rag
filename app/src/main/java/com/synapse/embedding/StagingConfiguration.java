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
 * Staging configuration for embedding services.
 * This configuration is optimized for staging environments
 * that mirror production but with additional monitoring and testing capabilities.
 *
 * @since 2.0
 */
public final class StagingConfiguration implements EmbeddingConfigurationType {

    private static final String ENVIRONMENT_TYPE = "staging";

    private final EmbeddingConfiguration configuration;

    /**
     * Creates a new staging configuration.
     * Uses settings that balance production performance with staging testing capabilities.
     */
    public StagingConfiguration() {
        this.configuration = new EmbeddingConfiguration(
            "text-embedding-3-large",  // Production-grade model
            3072,                      // Production-level embedding dimensions
            150,                       // Moderate batch size for staging
            5,                         // More retries than production for staging
            20000L,                    // Moderate timeout for staging
            System.getenv("EMBEDDING_API_KEY"),  // API key from environment
            System.getenv("EMBEDDING_ENDPOINT_URL"), // Endpoint from environment
            true,                      // Enable caching
            5400                       // Medium cache TTL for staging
        );
    }

    /**
     * Creates a new staging configuration with custom settings.
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
    public StagingConfiguration(
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
     * Creates a staging configuration optimized for testing and monitoring.
     *
     * @param apiKey the API key for embedding services
     * @param endpointUrl the endpoint URL for embedding services
     * @return a new staging configuration with testing and monitoring settings
     */
    public static StagingConfiguration monitored(String apiKey, String endpointUrl) {
        return new StagingConfiguration(
            "text-embedding-3-large",
            3072,
            150,
            5,
            20000L,
            apiKey,
            endpointUrl,
            true,
            5400
        );
    }

    /**
     * Gets a staging configuration optimized for performance testing.
     *
     * @return a new staging configuration for performance testing
     */
    public static StagingConfiguration performanceTesting() {
        return new StagingConfiguration(
            "text-embedding-3-large",
            3072,
            100,
            3,
            25000L,
            System.getenv("EMBEDDING_API_KEY"),
            System.getenv("EMBEDDING_ENDPOINT_URL"),
            true,
            3600
        );
    }
}