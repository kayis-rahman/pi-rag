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

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for EmbeddingConfigurationValidator using Java 25 pattern matching features.
 */
class EmbeddingConfigurationValidatorTest {

    private EmbeddingConfigurationValidator validator;

    @BeforeEach
    void setUp() {
        validator = new EmbeddingConfigurationValidator();
    }

    @Test
    void testValidateNullConfiguration() {
        List<String> messages = validator.validate(null);
        assertEquals(1, messages.size());
        assertTrue(messages.get(0).contains("cannot be null"));
    }

    @Test
    void testValidateValidConfiguration() {
        EmbeddingConfiguration config = EmbeddingConfiguration.defaultConfig();
        List<String> messages = validator.validate(config);
        assertTrue(messages.isEmpty());
    }

    @Test
    void testValidateInvalidModelName() {
        EmbeddingConfiguration config = new EmbeddingConfiguration(
            "", 1536, 100, 3, 30000L, null, null, true, 3600
        );
        List<String> messages = validator.validate(config);
        assertFalse(messages.isEmpty());
        assertTrue(messages.stream().anyMatch(msg -> msg.contains("empty")));
    }

    @Test
    void testValidateInvalidDimensions() {
        EmbeddingConfiguration config = new EmbeddingConfiguration(
            "test-model", -100, 100, 3, 30000L, null, null, true, 3600
        );
        List<String> messages = validator.validate(config);
        assertFalse(messages.isEmpty());
        assertTrue(messages.stream().anyMatch(msg -> msg.contains("positive")));
    }

    @Test
    void testValidateInvalidBatchSize() {
        EmbeddingConfiguration config = new EmbeddingConfiguration(
            "test-model", 1536, -50, 3, 30000L, null, null, true, 3600
        );
        List<String> messages = validator.validate(config);
        assertFalse(messages.isEmpty());
        assertTrue(messages.stream().anyMatch(msg -> msg.contains("positive")));
    }

    @Test
    void testValidateInvalidMaxRetries() {
        EmbeddingConfiguration config = new EmbeddingConfiguration(
            "test-model", 1536, 100, -1, 30000L, null, null, true, 3600
        );
        List<String> messages = validator.validate(config);
        assertFalse(messages.isEmpty());
        assertTrue(messages.stream().anyMatch(msg -> msg.contains("non-negative")));
    }

    @Test
    void testValidateInvalidTimeout() {
        EmbeddingConfiguration config = new EmbeddingConfiguration(
            "test-model", 1536, 100, 3, -1000L, null, null, true, 3600
        );
        List<String> messages = validator.validate(config);
        assertFalse(messages.isEmpty());
        assertTrue(messages.stream().anyMatch(msg -> msg.contains("positive")));
    }

    @Test
    void testValidateValidCustomConfiguration() {
        EmbeddingConfiguration config = new EmbeddingConfiguration(
            "custom-model", 2048, 50, 5, 60000L, "api-key-123", "http://localhost:8080", true, 7200
        );
        List<String> messages = validator.validate(config);
        assertTrue(messages.isEmpty());
    }

    @Test
    void testIsValidMethod() {
        EmbeddingConfiguration validConfig = EmbeddingConfiguration.defaultConfig();
        assertTrue(validator.isValid(validConfig));

        EmbeddingConfiguration invalidConfig = new EmbeddingConfiguration(
            "", 1536, 100, 3, 30000L, null, null, true, 3600
        );
        assertFalse(validator.isValid(invalidConfig));
    }

    @Test
    void testValidateOrThrowValidConfiguration() {
        EmbeddingConfiguration config = EmbeddingConfiguration.defaultConfig();
        assertDoesNotThrow(() -> validator.validateOrThrow(config));
    }

    @Test
    void testValidateOrThrowInvalidConfiguration() {
        EmbeddingConfiguration config = new EmbeddingConfiguration(
            "", 1536, 100, 3, 30000L, null, null, true, 3600
        );
        assertThrows(IllegalArgumentException.class, () -> validator.validateOrThrow(config));
    }
}