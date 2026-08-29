package com.sparkage.timebeam.infrastructure.persistence;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserPreferencesRepository extends JpaRepository<UserPreferences, UUID> {

    // Find preferences by user ID
    Optional<UserPreferences> findByUserId(UUID userId);

    // Check if preferences exist for user
    boolean existsByUserId(UUID userId);

    // Delete preferences by user ID
    void deleteByUserId(UUID userId);
}
