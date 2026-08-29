package com.sparkage.timebeam.domain.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.sparkage.timebeam.domain.model.Task;

public interface TaskRepository {
    Optional<Task> findById(UUID id);
    List<Task> findByUserId(UUID userId);
    List<Task> findByUserIdAndStatus(UUID userId, Task.Status status);
    List<Task> findActiveTasksByUserId(UUID userId); // TODO and IN_PROGRESS
    Task save(Task task);
    void deleteById(UUID id);
    void deleteByUserId(UUID userId);

    // Analytics queries
    long countByUserId(UUID userId);
    long countByUserIdAndStatus(UUID userId, Task.Status status);
}