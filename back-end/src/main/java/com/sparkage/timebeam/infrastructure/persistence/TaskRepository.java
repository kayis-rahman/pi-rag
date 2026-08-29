package com.sparkage.timebeam.infrastructure.persistence;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface TaskRepository extends JpaRepository<Task, UUID> {

    List<Task> findByUserIdOrderByCreatedAtDesc(UUID userId);

    List<Task> findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc(UUID userId);

    @Query("SELECT t FROM Task t WHERE t.userId = :userId AND t.status IN ('todo', 'in_progress') ORDER BY t.createdAt DESC")
    List<Task> findActiveTasksByUserId(@Param("userId") UUID userId);

    @Query("SELECT t FROM Task t WHERE t.userId = :userId AND t.status IN ('todo', 'in_progress') AND t.deletedAt IS NULL ORDER BY t.createdAt DESC")
    List<Task> findActiveNonDeletedTasksByUserId(@Param("userId") UUID userId);

    List<Task> findByUserIdAndStatus(UUID userId, Task.Status status);

    List<Task> findByUserIdAndStatusAndDeletedAtIsNull(UUID userId, Task.Status status);

    List<Task> findByUserIdAndDeletedAtIsNotNullOrderByDeletedAtDesc(UUID userId);

    long countByUserId(UUID userId);

    long countByUserIdAndStatus(UUID userId, Task.Status status);
}
