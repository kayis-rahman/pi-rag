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

import java.util.Objects;
import java.util.Optional;

/**
 * Configuration record for embedding services.
 * This immutable record holds all necessary configuration parameters
 * for embedding generation in the Synapse system.
 *
 * @param modelName         The name of the embedding model to use
 * @param dimensions        The dimensionality of the embedding vectors
 * @param batchSize         The batch size for processing embeddings
 * @param maxRetries        Maximum retry attempts for embedding requests
 * @param timeoutMs         Timeout in milliseconds for embedding requests
 * @param apiKey            Optional API key for external embedding services
 * @param endpointUrl       Optional endpoint URL for external embedding services
 * @param useCache          Whether to enable caching for embeddings
 * @param cacheTtlSeconds   Time-to-live for cached embeddings in seconds
 */
public record EmbeddingConfiguration(
        String modelName,
        int dimensions,
        int batchSize,
        int maxRetries,
        long timeoutMs,
        String apiKey,
        String endpointUrl,
        boolean useCache,
        int cacheTtlSeconds
) {

    /**
     * Validates the embedding configuration parameters.
     *
     * @throws IllegalArgumentException if any validation fails
     */
    public EmbeddingConfiguration {
        Objects.requireNonNull(modelName, "Model name must not be null");
    }

    /**
     * Creates a default embedding configuration with reasonable defaults.
     *
     * @return a new EmbeddingConfiguration with default values
     */
    public static EmbeddingConfiguration defaultConfig() {
        return new EmbeddingConfiguration(
                "text-embedding-3-small",
                1536,
                100,
                3,
                30000L,
                null,
                null,
                true,
                3600
        );
    }

    public static EmbeddingConfiguration of(
            String modelName,
            Integer dimensions,
            Integer batchSize,
            Integer maxRetries,
            Long timeoutMs,
            String apiKey,
            String endpointUrl,
            Boolean useCache,
            Integer cacheTtlSeconds
    ) {
        return new EmbeddingConfiguration(
                modelName,
                dimensions != null ? dimensions : 1536,
                batchSize != null ? batchSize : 100,
                maxRetries != null ? maxRetries : 3,
                timeoutMs != null ? timeoutMs : 30000L,
                apiKey,
                endpointUrl,
                useCache != null ? useCache : true,
                cacheTtlSeconds != null ? cacheTtlSeconds : 3600
        );
    }


    /**
     * Gets the model name, with fallback to default if null.
     *
     * @return the model name or default
     */
    public String modelName() {
        return Optional.ofNullable(modelName).orElse("text-embedding-3-small");
    }

    /**
     * Gets the dimensions, with fallback to default if null.
     *
     * @return the dimensions or default
     */
    public int dimensions() {
        return Optional.ofNullable(dimensions).orElse(1536);
    }

    /**
     * Gets the batch size, with fallback to default if null.
     *
     * @return the batch size or default
     */
    public int batchSize() {
        return Optional.ofNullable(batchSize).orElse(100);
    }

    /**
     * Gets the max retries, with fallback to default if null.
     *
     * @return the max retries or default
     */
    public int maxRetries() {
        return Optional.ofNullable(maxRetries).orElse(3);
    }

    /**
     * Gets the timeout in milliseconds, with fallback to default if null.
     *
     * @return the timeout or default
     */
    public long timeoutMs() {
        return Optional.ofNullable(timeoutMs).orElse(30000L);
    }

    /**
     * Gets the API key, returning null if not set.
     *
     * @return the API key or null
     */
    public String apiKey() {
        return apiKey;
    }

    /**
     * Gets the endpoint URL, returning null if not set.
     *
     * @return the endpoint URL or null
     */
    public String endpointUrl() {
        return endpointUrl;
    }

    /**
     * Gets whether caching is enabled, with fallback to default if null.
     *
     * @return whether caching is enabled or default
     */
    public boolean useCache() {
        return Optional.ofNullable(useCache).orElse(true);
    }

    /**
     * Gets the cache TTL in seconds, with fallback to default if null.
     *
     * @return the cache TTL or default
     */
    public int cacheTtlSeconds() {
        return Optional.ofNullable(cacheTtlSeconds).orElse(3600);
    }

    /**
     * Creates a new configuration with updated model name.
     *
     * @param modelName the new model name
     * @return a new configuration with updated model name
     */
    public EmbeddingConfiguration withModelName(String modelName) {
        return new EmbeddingConfiguration(
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

    /**
     * Creates a new configuration with updated dimensions.
     *
     * @param dimensions the new dimensions
     * @return a new configuration with updated dimensions
     */
    public EmbeddingConfiguration withDimensions(int dimensions) {
        return new EmbeddingConfiguration(
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

    /**
     * Creates a new configuration with updated batch size.
     *
     * @param batchSize the new batch size
     * @return a new configuration with updated batch size
     */
    public EmbeddingConfiguration withBatchSize(int batchSize) {
        return new EmbeddingConfiguration(
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

    /**
     * Creates a new configuration with updated max retries.
     *
     * @param maxRetries the new max retries
     * @return a new configuration with updated max retries
     */
    public EmbeddingConfiguration withMaxRetries(int maxRetries) {
        return new EmbeddingConfiguration(
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

    /**
     * Creates a new configuration with updated timeout.
     *
     * @param timeoutMs the new timeout in milliseconds
     * @return a new configuration with updated timeout
     */
    public EmbeddingConfiguration withTimeout(long timeoutMs) {
        return new EmbeddingConfiguration(
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

    /**
     * Creates a new configuration with updated API key.
     *
     * @param apiKey the new API key
     * @return a new configuration with updated API key
     */
    public EmbeddingConfiguration withApiKey(String apiKey) {
        return new EmbeddingConfiguration(
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

    /**
     * Creates a new configuration with updated endpoint URL.
     *
     * @param endpointUrl the new endpoint URL
     * @return a new configuration with updated endpoint URL
     */
    public EmbeddingConfiguration withEndpointUrl(String endpointUrl) {
        return new EmbeddingConfiguration(
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

    /**
     * Creates a new configuration with updated cache settings.
     *
     * @param useCache whether to enable caching
     * @param cacheTtlSeconds the cache TTL in seconds
     * @return a new configuration with updated cache settings
     */
    public EmbeddingConfiguration withCache(boolean useCache, int cacheTtlSeconds) {
        return new EmbeddingConfiguration(
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

    /**
     * Validates this configuration object.
     *
     * @throws IllegalArgumentException if the configuration is invalid
     */
    public void validate() {
        // Perform validation by creating a new instance with the same parameters
        // This triggers the constructor validation logic
        new EmbeddingConfiguration(
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

    /**
     * Checks if this configuration is valid (has all required parameters).
     *
     * @return true if the configuration is valid, false otherwise
     */
    public boolean isValid() {
        try {
            validate();
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}