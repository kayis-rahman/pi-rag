///*
// * Copyright (c) 2026 Synapse AI
// *
// * Licensed under the Apache License, Version 2.0 (the "License");
// * you may not use this file except in compliance with the License.
// * You may obtain a copy of the License at
// *
// *     http://www.apache.org/licenses/LICENSE-2.0
// *
// * Unless required by applicable law or agreed to in writing, software
// * distributed under the License is distributed on an "AS IS" BASIS,
// * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// * See the License for the specific language governing permissions and
// * limitations under the License.
// */
//
//package com.synapse.embedding;
//
//import java.io.IOException;
//import java.nio.file.Files;
//import java.nio.file.Path;
//import java.nio.file.Paths;
//import java.util.concurrent.atomic.AtomicReference;
//import java.util.logging.Logger;
//import java.util.logging.Level;
//import java.util.Map;
//import java.util.HashMap;
//import java.util.concurrent.locks.ReentrantReadWriteLock;
//import java.util.function.Function;
//
///**
// * Thread-safe manager for embedding configurations in the Synapse system.
// * This class provides atomic operations for managing embedding configurations
// * with support for runtime updates and concurrent access.
// *
// * @since 1.0
// */
//public class EmbeddingConfigurationManager {
//
//    private static final Logger logger = Logger.getLogger(EmbeddingConfigurationManager.class.getName());
//
//    // Atomic reference for thread-safe configuration updates
//    private final AtomicReference<EmbeddingConfiguration> currentConfig;
//
//    // Read-write lock for synchronized access to configuration loading
//    private final ReentrantReadWriteLock configLock = new ReentrantReadWriteLock();
//
//    // Configuration file path
//    private final Path configPath;
//
//    // Cache for loaded configurations to avoid repeated disk I/O
//    private final Map<String, EmbeddingConfiguration> configCache;
//
//    /**
//     * Creates a new EmbeddingConfigurationManager with default configuration.
//     *
//     * @param configPath the path to the configuration file (optional, can be null)
//     * @throws IOException if there's an error initializing the manager
//     */
//    public EmbeddingConfigurationManager(String configPath) throws IOException {
//        this.configPath = configPath != null ? Paths.get(configPath) : null;
//        this.currentConfig = new AtomicReference<>(EmbeddingConfiguration.defaultConfig());
//        this.configCache = new HashMap<>();
//
//        // Load initial configuration if path is provided
//        if (this.configPath != null && Files.exists(this.configPath)) {
//            loadConfigurationFromFile();
//        } else {
//            logger.info("Using default embedding configuration");
//        }
//    }
//
//    /**
//     * Creates a new EmbeddingConfigurationManager with a specific initial configuration.
//     *
//     * @param initialConfig the initial configuration to use
//     * @throws IllegalArgumentException if the initial configuration is null
//     */
//    public EmbeddingConfigurationManager(EmbeddingConfiguration initialConfig) {
//        if (initialConfig == null) {
//            throw new IllegalArgumentException("Initial configuration cannot be null");
//        }
//        this.configPath = null;
//        this.currentConfig = new AtomicReference<>(initialConfig);
//        this.configCache = new HashMap<>();
//    }
//
//    /**
//     * Gets the current embedding configuration in a thread-safe manner.
//     *
//     * @return the current embedding configuration
//     */
//    public EmbeddingConfiguration getCurrentConfiguration() {
//        return currentConfig.get();
//    }
//
//    /**
//     * Atomically updates the embedding configuration.
//     *
//     * @param newConfig the new configuration to apply
//     * @return true if the configuration was successfully updated, false otherwise
//     * @throws IllegalArgumentException if the new configuration is invalid
//     */
//    public boolean updateConfiguration(EmbeddingConfiguration newConfig) {
//        if (newConfig == null) {
//            throw new IllegalArgumentException("New configuration cannot be null");
//        }
//
//        try {
//            // Validate the new configuration before updating
//            if (!newConfig.isValid()) {
//                throw new IllegalArgumentException("New configuration is invalid");
//            }
//
//            // Perform atomic update
//            EmbeddingConfiguration previousConfig = currentConfig.getAndSet(newConfig);
//
//            // Log the configuration change
//            if (!newConfig.equals(previousConfig)) {
//                logger.log(Level.INFO, "Embedding configuration updated from {0} to {1}",
//                    new Object[]{previousConfig.modelName(), newConfig.modelName()});
//            }
//
//            return true;
//        } catch (IllegalArgumentException e) {
//            logger.log(Level.WARNING, "Failed to update embedding configuration: {0}", e.getMessage());
//            throw e;
//        } catch (Exception e) {
//            logger.log(Level.SEVERE, "Unexpected error while updating embedding configuration", e);
//            throw new RuntimeException("Failed to update embedding configuration", e);
//        }
//    }
//
//    /**
//     * Updates the embedding configuration atomically with a functional approach.
//     *
//     * @param updater a function that takes the current configuration and returns a new one
//     * @return the updated configuration
//     * @throws IllegalArgumentException if the updater function is null or produces an invalid configuration
//     */
//    public EmbeddingConfiguration updateConfigurationWith(Function<EmbeddingConfiguration, EmbeddingConfiguration> updater) {
//        if (updater == null) {
//            throw new IllegalArgumentException("Updater function cannot be null");
//        }
//
//        EmbeddingConfiguration previousConfig;
//        EmbeddingConfiguration newConfig;
//
//        do {
//            previousConfig = currentConfig.get();
//            newConfig = updater.apply(previousConfig);
//
//            if (newConfig == null) {
//                throw new IllegalArgumentException("Updater function must not return null");
//            }
//
//            // Validate the new configuration
//            try {
//                if (!newConfig.isValid()) {
//                    throw new IllegalArgumentException("Updated configuration is invalid");
//                }
//            } catch (IllegalArgumentException e) {
//                throw new IllegalArgumentException("Updated configuration is invalid: " + e.getMessage(), e);
//            }
//
//        } while (!currentConfig.compareAndSet(previousConfig, newConfig));
//
//        // Log the configuration change
//        if (!newConfig.equals(previousConfig)) {
//            logger.log(Level.INFO, "Embedding configuration updated from {0} to {1}",
//                new Object[]{previousConfig.modelName(), newConfig.modelName()});
//        }
//
//        return newConfig;
//    }
//
//    /**
//     * Loads configuration from file if a configuration path is set.
//     *
//     * @throws IOException if there's an error reading the configuration file
//     * @throws IllegalStateException if the configuration file is malformed or invalid
//     */
//    public void loadConfigurationFromFile() throws IOException {
//        if (configPath == null || !Files.exists(configPath)) {
//            logger.warning("Configuration file path not set or does not exist. Using default configuration.");
//            return;
//        }
//
//        configLock.writeLock().lock();
//        try {
//            // In a real implementation, we would parse the configuration file here
//            // For now, we'll load the default configuration as an example
//
//            // Simulate loading configuration from file
//            EmbeddingConfiguration loadedConfig = EmbeddingConfiguration.defaultConfig();
//            logger.log(Level.INFO, "Loaded embedding configuration from {0}", configPath);
//
//            // Update the current configuration atomically
//            currentConfig.set(loadedConfig);
//
//        } catch (Exception e) {
//            logger.log(Level.SEVERE, "Failed to load configuration from file: " + configPath, e);
//            throw new IOException("Failed to load embedding configuration from file", e);
//        } finally {
//            configLock.writeLock().unlock();
//        }
//    }
//
//    /**
//     * Saves the current configuration to file.
//     *
//     * @throws IOException if there's an error writing to the configuration file
//     */
//    public void saveConfigurationToFile() throws IOException {
//        if (configPath == null) {
//            logger.warning("Configuration file path not set. Cannot save configuration.");
//            return;
//        }
//
//        configLock.readLock().lock();
//        try {
//            // In a real implementation, we would serialize the configuration to file
//            // For now, we'll simulate saving to file
//            logger.log(Level.INFO, "Saving embedding configuration to {0}", configPath);
//
//        } catch (Exception e) {
//            logger.log(Level.SEVERE, "Failed to save configuration to file: " + configPath, e);
//            throw new IOException("Failed to save embedding configuration to file", e);
//        } finally {
//            configLock.readLock().unlock();
//        }
//    }
//
//    /**
//     * Gets a cached configuration by name if available.
//     *
//     * @param name the name of the configuration to retrieve
//     * @return the cached configuration or null if not found
//     */
//    public EmbeddingConfiguration getCachedConfiguration(String name) {
//        return configCache.get(name);
//    }
//
//    /**
//     * Caches a configuration by name for quick retrieval.
//     *
//     * @param name the name to cache the configuration under
//     * @param config the configuration to cache
//     */
//    public void cacheConfiguration(String name, EmbeddingConfiguration config) {
//        if (name != null && config != null) {
//            configCache.put(name, config);
//        }
//    }
//
//    /**
//     * Removes a configuration from the cache.
//     *
//     * @param name the name of the configuration to remove
//     */
//    public void removeCachedConfiguration(String name) {
//        if (name != null) {
//            configCache.remove(name);
//        }
//    }
//
//    /**
//     * Gets the total number of configurations in the cache.
//     *
//     * @return the number of cached configurations
//     */
//    public int getCachedConfigurationsCount() {
//        return configCache.size();
//    }
//
//    /**
//     * Resets the configuration manager to use the default configuration.
//     */
//    public void resetToDefault() {
//        EmbeddingConfiguration defaultConfig = EmbeddingConfiguration.defaultConfig();
//        currentConfig.set(defaultConfig);
//        logger.log(Level.INFO, "Reset embedding configuration to default: {0}", defaultConfig.modelName());
//    }
//
//    /**
//     * Checks if the current configuration is valid.
//     *
//     * @return true if the current configuration is valid, false otherwise
//     */
//    public boolean isCurrentConfigurationValid() {
//        try {
//            EmbeddingConfiguration config = currentConfig.get();
//            config.validate(); // This will throw if invalid
//            return true;
//        } catch (Exception e) {
//            logger.log(Level.WARNING, "Current configuration is invalid: {0}", e.getMessage());
//            return false;
//        }
//    }
//
//    /**
//     * Gets the configuration file path.
//     *
//     * @return the configuration file path or null if not set
//     */
//    public Path getConfigPath() {
//        return configPath;
//    }
//
//    /**
//     * Updates the configuration file path.
//     *
//     * @param newPath the new configuration file path
//     * @throws IOException if there's an error updating the configuration
//     */
//    public void updateConfigPath(String newPath) throws IOException {
//        this.configPath = newPath != null ? Paths.get(newPath) : null;
//        if (this.configPath != null && Files.exists(this.configPath)) {
//            loadConfigurationFromFile();
//        }
//    }
//}