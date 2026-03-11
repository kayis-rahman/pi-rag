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
 * Production configuration for embedding services.
 * This configuration is optimized for production environments
 * with strict performance and reliability requirements.
 *
 * @since 2.0
 */
public final class ProductionConfiguration implements EmbeddingConfigurationType {

    private static final String ENVIRONMENT_TYPE = "production";

    private final EmbeddingConfiguration configuration;

    /**
     * Creates a new production configuration.
     * Uses optimized settings for high-performance production usage.
     */
    public ProductionConfiguration() {
        this.configuration = new EmbeddingConfiguration(
            "text-embedding-3-large",  // High-performing model for production
            3072,                      // Higher dimensional embeddings for production
            200,                       // Larger batch size for efficiency
            3,                         // Fewer retries in production
            15000L,                    // Shorter timeout for responsiveness
            System.getenv("EMBEDDING_API_KEY"),  // Production API key from environment
            System.getenv("EMBEDDING_ENDPOINT_URL"), // Production endpoint from environment
            true,                      // Enable caching in production
            7200                       // Longer cache TTL in production
        );
    }

    /**
     * Creates a new production configuration with custom settings.
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
    public ProductionConfiguration(
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
     * Creates a production configuration with specific optimized settings.
     *
     * @param apiKey the API key for embedding services
     * @param endpointUrl the endpoint URL for embedding services
     * @return a new production configuration with specified settings
     */
    public static ProductionConfiguration optimized(String apiKey, String endpointUrl) {
        return new ProductionConfiguration(
            "text-embedding-3-large",
            3072,
            200,
            3,
            15000L,
            apiKey,
            endpointUrl,
            true,
            7200
        );
    }

    /**
     * Gets a production configuration with minimal settings.
     *
     * @return a new production configuration with minimal settings
     */
    public static ProductionConfiguration minimal() {
        return new ProductionConfiguration(
            "text-embedding-3-small",
            1536,
            100,
            2,
            20000L,
            System.getenv("EMBEDDING_API_KEY"),
            System.getenv("EMBEDDING_ENDPOINT_URL"),
            true,
            3600
        );
    }
}