package com.sparkage.timebeam.domain.repository;

import com.sparkage.timebeam.domain.model.User;

import java.util.Optional;
import java.util.UUID;

/**
 * Domain repository interface for User entities.
 * Defines the contract for user data access operations.
 */
public interface UserRepository {
    Optional<User> findById(UUID id);
    Optional<User> findByEmail(String email);
    User save(User user);
    void deleteById(UUID id);
    boolean existsByEmail(String email);
}
