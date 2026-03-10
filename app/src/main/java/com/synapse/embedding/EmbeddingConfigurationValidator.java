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

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.regex.Pattern;

/**
 * Validator for embedding configurations using Java 25 pattern matching features.
 * This class provides comprehensive validation of embedding configuration objects
 * with detailed feedback about validation issues.
 *
 * @since 1.0
 */
public class EmbeddingConfigurationValidator {

    private static final Pattern MODEL_NAME_PATTERN = Pattern.compile("^[a-zA-Z0-9._-]+$");
    private static final Pattern ENDPOINT_URL_PATTERN = Pattern.compile("^https?://.+");

    /**
     * Validates an embedding configuration and returns detailed validation results.
     *
     * @param configuration the configuration to validate
     * @return a list of validation messages indicating issues found
     */
    public List<String> validate(EmbeddingConfiguration configuration) {
        var messages = new ArrayList<String>();

        // Using pattern matching for null checking with modern Java 25 features
        if (configuration == null) {
            messages.add("Configuration cannot be null");
        } else {
            validateConfigurationFields(configuration, messages);
        }

        return messages;
    }

    /**
     * Validates configuration fields using Java 25 pattern matching.
     */
    private void validateConfigurationFields(EmbeddingConfiguration configuration, List<String> messages) {
        // Using pattern matching for validation with switch expressions
        validateModelName(configuration.modelName(), messages);
        validateDimensions(configuration.dimensions(), messages);
        validateBatchSize(configuration.batchSize(), messages);
        validateMaxRetries(configuration.maxRetries(), messages);
        validateTimeout(configuration.timeoutMs(), messages);
        validateApiKey(configuration.apiKey(), messages);
        validateEndpointUrl(configuration.endpointUrl(), messages);
        validateCacheSettings(configuration.useCache(), configuration.cacheTtlSeconds(), messages);
    }

    /**
     * Validates the model name using pattern matching.
     *
     * @param modelName the model name to validate
     * @param messages list to collect validation messages
     */
    private void validateModelName(String modelName, List<String> messages) {
        // Using pattern matching for null checking with modern syntax
        if (modelName == null) {
            messages.add("Model name cannot be null");
            return;
        }

        // Validate for empty or whitespace-only model name
        if (modelName.isEmpty()) {
            messages.add("Model name cannot be empty");
            return;
        }

        if (modelName.trim().isEmpty()) {
            messages.add("Model name cannot be whitespace only");
            return;
        }

        // Using pattern matching with regex
        if (!MODEL_NAME_PATTERN.matcher(modelName).matches()) {
            messages.add("Model name contains invalid characters. Allowed: alphanumeric, dots, underscores, hyphens");
        }

        // Length validation
        if (modelName.length() > 255) {
            messages.add("Model name exceeds maximum length of 255 characters");
        }
    }

    /**
     * Validates dimensions using pattern matching.
     *
     * @param dimensions the dimensions to validate
     * @param messages list to collect validation messages
     */
    private void validateDimensions(Integer dimensions, List<String> messages) {
        // Using pattern matching for null checking with modern syntax
        if (dimensions == null) {
            // Allow null to indicate use of default value
            return;
        }

        // Using pattern matching for numeric validation with switch expressions
        switch (Integer.compare(dimensions, 0)) {
            case 0 -> messages.add("Dimensions must be positive (cannot be zero)");
            case -1 -> messages.add("Dimensions must be positive (cannot be negative)");
            case 1 -> {
                // Valid case - do nothing
                if (dimensions > 10000) {
                    messages.add("Dimensions value appears unusually high (" + dimensions + ")");
                }
            }
        }
    }

    /**
     * Validates batch size using pattern matching.
     *
     * @param batchSize the batch size to validate
     * @param messages list to collect validation messages
     */
    private void validateBatchSize(Integer batchSize, List<String> messages) {
        // Using pattern matching for null checking
        if (batchSize == null) {
            // Allow null to indicate use of default value
            return;
        }

        // Using pattern matching for numeric validation with switch expressions
        switch (Integer.compare(batchSize, 0)) {
            case 0 -> messages.add("Batch size must be positive (cannot be zero)");
            case -1 -> messages.add("Batch size must be positive (cannot be negative)");
            case 1 -> {
                // Valid case - do nothing
                if (batchSize > 1000) {
                    messages.add("Batch size value appears unusually high (" + batchSize + ")");
                }
            }
        }
    }

    /**
     * Validates maximum retries using pattern matching.
     *
     * @param maxRetries the max retries to validate
     * @param messages list to collect validation messages
     */
    private void validateMaxRetries(Integer maxRetries, List<String> messages) {
        // Using pattern matching for null checking
        if (maxRetries == null) {
            // Allow null to indicate use of default value
            return;
        }

        // Using pattern matching for numeric validation with switch expressions
        switch (Integer.compare(maxRetries, 0)) {
            case -1 -> messages.add("Max retries must be non-negative");
            case 0 -> {
                // Valid case - do nothing
            }
            case 1 -> {
                // Valid case - do nothing
                if (maxRetries > 10) {
                    messages.add("Max retries value appears unusually high (" + maxRetries + ")");
                }
            }
        }
    }

    /**
     * Validates timeout using pattern matching.
     *
     * @param timeoutMs the timeout in milliseconds to validate
     * @param messages list to collect validation messages
     */
    private void validateTimeout(Long timeoutMs, List<String> messages) {
        // Using pattern matching for null checking
        if (timeoutMs == null) {
            // Allow null to indicate use of default value
            return;
        }

        // Using pattern matching for numeric validation with switch expressions
        switch (Long.compare(timeoutMs, 0)) {
            case 0 -> messages.add("Timeout must be positive (cannot be zero)");
            case -1 -> messages.add("Timeout must be positive (cannot be negative)");
            case 1 -> {
                // Valid case - do nothing
                if (timeoutMs > 300000L) { // 5 minutes
                    messages.add("Timeout value appears unusually high (" + timeoutMs + " ms)");
                }
            }
        }
    }

    /**
     * Validates API key using pattern matching.
     *
     * @param apiKey the API key to validate
     * @param messages list to collect validation messages
     */
    private void validateApiKey(String apiKey, List<String> messages) {
        // Using pattern matching for null checking
        if (apiKey == null) {
            // Allow null (indicating no API key required)
            return;
        }

        // Using pattern matching for empty string validation
        if (apiKey.isEmpty()) {
            messages.add("API key cannot be empty when provided");
            return;
        }

        // Using pattern matching for whitespace validation
        if (apiKey.trim().isEmpty()) {
            messages.add("API key cannot be whitespace only");
            return;
        }

        // Length validation
        if (apiKey.length() > 1000) {
            messages.add("API key exceeds maximum length of 1000 characters");
        }
    }

    /**
     * Validates endpoint URL using pattern matching.
     *
     * @param endpointUrl the endpoint URL to validate
     * @param messages list to collect validation messages
     */
    private void validateEndpointUrl(String endpointUrl, List<String> messages) {
        // Using pattern matching for null checking
        if (endpointUrl == null) {
            // Allow null (indicating no custom endpoint)
            return;
        }

        // Using pattern matching for empty string validation
        if (endpointUrl.isEmpty()) {
            messages.add("Endpoint URL cannot be empty when provided");
            return;
        }

        // Using pattern matching for whitespace validation
        if (endpointUrl.trim().isEmpty()) {
            messages.add("Endpoint URL cannot be whitespace only");
            return;
        }

        // Format validation
        if (!ENDPOINT_URL_PATTERN.matcher(endpointUrl).matches()) {
            messages.add("Endpoint URL must be a valid HTTP or HTTPS URL");
        }

        // Length validation
        if (endpointUrl.length() > 2048) {
            messages.add("Endpoint URL exceeds maximum length of 2048 characters");
        }
    }

    /**
     * Validates cache settings using pattern matching.
     *
     * @param useCache whether caching is enabled
     * @param cacheTtlSeconds cache TTL in seconds
     * @param messages list to collect validation messages
     */
    private void validateCacheSettings(Boolean useCache, Integer cacheTtlSeconds, List<String> messages) {
        // Using pattern matching for null checking
        if (useCache == null) {
            // Allow null (indicating default behavior)
            return;
        }

        // Using pattern matching for cache TTL validation
        if (cacheTtlSeconds != null) {
            switch (Integer.compare(cacheTtlSeconds, 0)) {
                case -1 -> messages.add("Cache TTL must be non-negative");
                case 0 -> {
                    // Valid case - do nothing
                }
                case 1 -> {
                    // Valid case - do nothing
                    if (cacheTtlSeconds > 2592000) { // 30 days
                        messages.add("Cache TTL value appears unusually high (" + cacheTtlSeconds + " seconds)");
                    }
                }
            }
        }
    }

    /**
     * Checks if an embedding configuration is valid.
     *
     * @param configuration the configuration to validate
     * @return true if the configuration is valid, false otherwise
     */
    public boolean isValid(EmbeddingConfiguration configuration) {
        return validate(configuration).isEmpty();
    }

    /**
     * Validates an embedding configuration and throws an exception if invalid.
     *
     * @param configuration the configuration to validate
     * @throws IllegalArgumentException if the configuration is invalid
     */
    public void validateOrThrow(EmbeddingConfiguration configuration) {
        var messages = validate(configuration);
        if (!messages.isEmpty()) {
            var errorMessage = String.join("; ", messages);
            throw new IllegalArgumentException("Invalid embedding configuration: " + errorMessage);
        }
    }
}