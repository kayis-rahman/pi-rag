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

import java.util.List;

/**
 * Demo showcasing the EmbeddingConfigurationValidator with Java 25 pattern matching features.
 */
public class EmbeddingConfigurationValidatorDemo {

    public static void main(String[] args) {
        // Create a validator instance
        EmbeddingConfigurationValidator validator = new EmbeddingConfigurationValidator();

        System.out.println("=== Embedding Configuration Validation Demo ===\n");

        // Test 1: Valid configuration
        System.out.println("1. Testing valid configuration:");
        EmbeddingConfiguration validConfig = EmbeddingConfiguration.defaultConfig();
        List<String> validMessages = validator.validate(validConfig);
        System.out.println("   Messages: " + validMessages);
        System.out.println("   Is Valid: " + validator.isValid(validConfig) + "\n");

        // Test 2: Invalid model name
        System.out.println("2. Testing invalid model name:");
        EmbeddingConfiguration invalidModelConfig = new EmbeddingConfiguration(
            "", 1536, 100, 3, 30000L, null, null, true, 3600
        );
        List<String> invalidModelMessages = validator.validate(invalidModelConfig);
        System.out.println("   Messages: " + invalidModelMessages);
        System.out.println("   Is Valid: " + validator.isValid(invalidModelConfig) + "\n");

        // Test 3: Invalid dimensions
        System.out.println("3. Testing invalid dimensions:");
        EmbeddingConfiguration invalidDimsConfig = new EmbeddingConfiguration(
            "test-model", -100, 100, 3, 30000L, null, null, true, 3600
        );
        List<String> invalidDimsMessages = validator.validate(invalidDimsConfig);
        System.out.println("   Messages: " + invalidDimsMessages);
        System.out.println("   Is Valid: " + validator.isValid(invalidDimsConfig) + "\n");

        // Test 4: Testing with null configuration
        System.out.println("4. Testing null configuration:");
        List<String> nullMessages = validator.validate(null);
        System.out.println("   Messages: " + nullMessages);
        System.out.println("   Is Valid: " + validator.isValid(null) + "\n");

        // Test 5: Testing validation with exception throwing
        System.out.println("5. Testing validation with exception throwing:");
        try {
            validator.validateOrThrow(invalidModelConfig);
        } catch (IllegalArgumentException e) {
            System.out.println("   Caught exception: " + e.getMessage());
        }
    }
}