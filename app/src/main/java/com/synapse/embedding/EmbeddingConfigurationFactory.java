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

import java.util.Map;
import java.util.HashMap;

/**
 * Factory class for creating embedding configurations based on environment detection.
 * This class uses Java 25 pattern matching features to determine the appropriate
 * configuration type for different environments.
 *
 * @since 2.0
 */
public class EmbeddingConfigurationFactory {

    /**
     * Creates an embedding configuration based on the detected environment.
     * Uses Java 25 pattern matching to detect environment from system properties
     * and select the appropriate configuration type.
     *
     * @return an EmbeddingConfigurationType based on the detected environment
     */
    public static EmbeddingConfigurationType createConfiguration() {
        // Using Java 25 pattern matching to detect environment
        return switch (detectEnvironment()) {
            case "development" -> new DevelopmentConfiguration();
            case "staging" -> new StagingConfiguration();
            case "production" -> new ProductionConfiguration();
            default -> {
                // Fallback to development configuration for unknown environments
                System.err.println("Unknown environment detected: " + detectEnvironment() +
                    ". Falling back to development configuration.");
                yield new DevelopmentConfiguration();
            }
        };
    }

    /**
     * Creates an embedding configuration for a specific environment.
     *
     * @param environmentType the environment type (development, staging, production)
     * @return an EmbeddingConfigurationType for the specified environment
     */
    public static EmbeddingConfigurationType createConfiguration(String environmentType) {
        return switch (environmentType.toLowerCase()) {
            case "development" -> new DevelopmentConfiguration();
            case "staging" -> new StagingConfiguration();
            case "production" -> new ProductionConfiguration();
            default -> {
                System.err.println("Unknown environment type: " + environmentType +
                    ". Falling back to development configuration.");
                yield new DevelopmentConfiguration();
            }
        };
    }

    /**
     * Creates an embedding configuration with custom settings for a specific environment.
     *
     * @param environmentType the environment type (development, staging, production)
     * @param modelName the name of the embedding model
     * @param dimensions the dimensionality of the embedding vectors
     * @param batchSize the batch size for processing embeddings
     * @param maxRetries maximum retry attempts for embedding requests
     * @param timeoutMs timeout in milliseconds for embedding requests
     * @param apiKey optional API key for external embedding services
     * @param endpointUrl optional endpoint URL for external embedding services
     * @param useCache whether to enable caching for embeddings
     * @param cacheTtlSeconds time-to-live for cached embeddings in seconds
     * @return an EmbeddingConfigurationType with the specified settings
     */
    public static EmbeddingConfigurationType createConfiguration(
            String environmentType,
            String modelName,
            Integer dimensions,
            Integer batchSize,
            Integer maxRetries,
            Long timeoutMs,
            String apiKey,
            String endpointUrl,
            Boolean useCache,
            Integer cacheTtlSeconds) {

        return switch (environmentType.toLowerCase()) {
            case "development" -> new DevelopmentConfiguration(
                modelName, dimensions, batchSize, maxRetries, timeoutMs, apiKey, endpointUrl, useCache, cacheTtlSeconds);
            case "staging" -> new StagingConfiguration(
                modelName, dimensions, batchSize, maxRetries, timeoutMs, apiKey, endpointUrl, useCache, cacheTtlSeconds);
            case "production" -> new ProductionConfiguration(
                modelName, dimensions, batchSize, maxRetries, timeoutMs, apiKey, endpointUrl, useCache, cacheTtlSeconds);
            default -> {
                System.err.println("Unknown environment type: " + environmentType +
                    ". Falling back to development configuration.");
                yield new DevelopmentConfiguration(
                    modelName, dimensions, batchSize, maxRetries, timeoutMs, apiKey, endpointUrl, useCache, cacheTtlSeconds);
            }
        };
    }

    /**
     * Detects the current environment based on system properties and environment variables.
     * Uses Java 25 pattern matching for robust environment detection.
     *
     * @return the detected environment type as a string
     */
    private static String detectEnvironment() {
        // Using Java 25 pattern matching to check multiple environment sources
        return switch (getEnvironmentVariable()) {
            case "production" -> "production";
            case "staging" -> "staging";
            case "development" -> "development";
            case null -> {
                // If environment variable is null, check system property
                String systemProperty = getSystemProperty();
                yield switch (systemProperty) {
                    case "production" -> "production";
                    case "staging" -> "staging";
                    case "development" -> "development";
                    default -> "development"; // Default to development
                };
            }
            case "" -> {
                // If environment variable is empty, check system property
                String systemProperty = getSystemProperty();
                yield switch (systemProperty) {
                    case "production" -> "production";
                    case "staging" -> "staging";
                    case "development" -> "development";
                    default -> "development"; // Default to development
                };
            }
            default -> {
                // Fall back to checking for common development environment indicators
                String envValue = getEnvironmentVariable().toLowerCase();
                yield switch (envValue) {
                    case "prod", "prd", "release" -> "production";
                    case "stage", "stg" -> "staging";
                    case "dev", "development", "local" -> "development";
                    default -> "development"; // Default to development
                };
            }
        };
    }

    /**
     * Gets the environment variable from the system.
     *
     * @return the value of the SYNAPSE_ENV environment variable or null if not found
     */
    private static String getEnvironmentVariable() {
        return System.getenv("SYNAPSE_ENV");
    }

    /**
     * Gets the system property for environment.
     *
     * @return the value of the "synapse.env" system property or null if not found
     */
    private static String getSystemProperty() {
        return System.getProperty("synapse.env");
    }

    /**
     * Gets the current environment type.
     *
     * @return the current environment type as a string
     */
    public static String getCurrentEnvironment() {
        return detectEnvironment();
    }

    /**
     * Creates a configuration map with environment-specific settings.
     *
     * @return a map containing environment-specific configuration settings
     */
    public static Map<String, Object> createConfigurationMap() {
        Map<String, Object> configMap = new HashMap<>();
        String environment = detectEnvironment();

        configMap.put("environment", environment);
        configMap.put("configuration", switch (environment) {
            case "development" -> new DevelopmentConfiguration();
            case "staging" -> new StagingConfiguration();
            case "production" -> new ProductionConfiguration();
            default -> new DevelopmentConfiguration();
        });

        return configMap;
    }
}