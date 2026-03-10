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
import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for the sealed configuration types.
 */
class EmbeddingConfigurationTypeTest {

    @Test
    void testDevelopmentConfiguration() {
        DevelopmentConfiguration devConfig = new DevelopmentConfiguration();
        assertNotNull(devConfig.getConfiguration());
        assertEquals("development", devConfig.getEnvironmentType());

        // Test with custom parameters
        DevelopmentConfiguration customDevConfig = new DevelopmentConfiguration(
            "custom-model", 1024, 25, 2, 10000L,
            "api-key", "http://localhost:8080", true, 1800
        );
        assertEquals("custom-model", customDevConfig.getConfiguration().modelName());
        assertEquals(1024, customDevConfig.getConfiguration().dimensions());
    }

    @Test
    void testProductionConfiguration() {
        ProductionConfiguration prodConfig = new ProductionConfiguration();
        assertNotNull(prodConfig.getConfiguration());
        assertEquals("production", prodConfig.getEnvironmentType());

        // Test with custom parameters
        ProductionConfiguration customProdConfig = new ProductionConfiguration(
            "custom-model", 1024, 25, 2, 10000L,
            "api-key", "http://localhost:8080", true, 1800
        );
        assertEquals("custom-model", customProdConfig.getConfiguration().modelName());
        assertEquals(1024, customProdConfig.getConfiguration().dimensions());
    }

    @Test
    void testStagingConfiguration() {
        StagingConfiguration stagingConfig = new StagingConfiguration();
        assertNotNull(stagingConfig.getConfiguration());
        assertEquals("staging", stagingConfig.getEnvironmentType());

        // Test with custom parameters
        StagingConfiguration customStagingConfig = new StagingConfiguration(
            "custom-model", 1024, 25, 2, 10000L,
            "api-key", "http://localhost:8080", true, 1800
        );
        assertEquals("custom-model", customStagingConfig.getConfiguration().modelName());
        assertEquals(1024, customStagingConfig.getConfiguration().dimensions());
    }

    @Test
    void testSealedInterfaceUsage() {
        // Test that all configurations implement the sealed interface
        EmbeddingConfigurationType devConfig = new DevelopmentConfiguration();
        EmbeddingConfigurationType prodConfig = new ProductionConfiguration();
        EmbeddingConfigurationType stagingConfig = new StagingConfiguration();

        assertTrue(devConfig instanceof DevelopmentConfiguration);
        assertTrue(prodConfig instanceof ProductionConfiguration);
        assertTrue(stagingConfig instanceof StagingConfiguration);

        assertEquals("development", devConfig.getEnvironmentType());
        assertEquals("production", prodConfig.getEnvironmentType());
        assertEquals("staging", stagingConfig.getEnvironmentType());
    }

    @Test
    void testConfigurationValues() {
        DevelopmentConfiguration devConfig = new DevelopmentConfiguration();
        ProductionConfiguration prodConfig = new ProductionConfiguration();
        StagingConfiguration stagingConfig = new StagingConfiguration();

        // Verify development config
        assertEquals("text-embedding-3-small", devConfig.getConfiguration().modelName());
        assertEquals(1536, devConfig.getConfiguration().dimensions());
        assertEquals(50, devConfig.getConfiguration().batchSize());
        assertEquals(5, devConfig.getConfiguration().maxRetries());

        // Verify production config
        assertEquals("text-embedding-3-large", prodConfig.getConfiguration().modelName());
        assertEquals(3072, prodConfig.getConfiguration().dimensions());
        assertEquals(200, prodConfig.getConfiguration().batchSize());
        assertEquals(3, prodConfig.getConfiguration().maxRetries());

        // Verify staging config
        assertEquals("text-embedding-3-large", stagingConfig.getConfiguration().modelName());
        assertEquals(3072, stagingConfig.getConfiguration().dimensions());
        assertEquals(150, stagingConfig.getConfiguration().batchSize());
        assertEquals(5, stagingConfig.getConfiguration().maxRetries());
    }
}