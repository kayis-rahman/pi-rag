package com.sparkage.timebeam.infrastructure.persistence;

import jakarta.persistence.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * Repository for User Sync Preferences
 */
@Repository
public interface UserSyncPreferencesRepository extends JpaRepository<UserSyncPreferences, UUID> {
    /**
     * Find user preferences by user ID
     */
    Optional<UserSyncPreferences> findByUserId(@Param("userId") UUID userId);
}
