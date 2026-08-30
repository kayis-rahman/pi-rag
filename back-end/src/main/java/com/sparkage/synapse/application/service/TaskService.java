package com.sparkage.synapse.application.service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.sparkage.synapse.infrastructure.external.ResourceNotFoundException;
import com.sparkage.synapse.infrastructure.persistence.SessionRecord;
import com.sparkage.synapse.infrastructure.persistence.SessionRecordRepository;
import com.sparkage.synapse.infrastructure.persistence.Task;
import com.sparkage.synapse.infrastructure.persistence.TaskMapper;
import com.sparkage.synapse.infrastructure.persistence.TaskRepository;
import com.sparkage.synapse.presentation.dto.TaskCreateRequest;
import com.sparkage.synapse.presentation.dto.TaskDto;
import com.sparkage.synapse.presentation.dto.TaskProgressResponseDto;
import com.sparkage.synapse.presentation.dto.TaskUpdateRequest;

@Service
public class TaskService {
    private static final Logger log = LoggerFactory.getLogger(TaskService.class);

    private final TaskRepository repository;
    private final TaskMapper mapper;
    private final SessionRecordRepository sessionRecordRepository;

    public TaskService(TaskRepository repository, TaskMapper mapper, SessionRecordRepository sessionRecordRepository) {
        this.repository = repository;
        this.mapper = mapper;
        this.sessionRecordRepository = sessionRecordRepository;
    }

    public TaskDto create(TaskCreateRequest request, UUID userId) {
        log.debug("TaskService.create called for userId={}, title={}", userId, request.getTitle());

        Instant now = Instant.now();
        Task entity = new Task();
        entity.setId(UUID.randomUUID());
        entity.setUserId(userId);
        entity.setTitle(request.getTitle());
        entity.setDescription(request.getDescription());
        entity.setStatus(Task.Status.todo);
        entity.setCreatedAt(now);
        entity.setUpdatedAt(now);

        Task saved = repository.save(entity);
        log.info("Task created id={}, userId={}, title={}", saved.getId(), saved.getUserId(), saved.getTitle());
        return mapper.toDto(saved);
    }

    public List<TaskDto> listForUser(UUID userId) {
        log.debug("listForUser called userId={}", userId);
        return repository.findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc(userId).stream()
            .map(mapper::toDto)
            .collect(Collectors.toList());
    }

    public List<TaskDto> listActiveTasksForUser(UUID userId) {
        log.debug("listActiveTasksForUser called userId={}", userId);
        return repository.findActiveNonDeletedTasksByUserId(userId).stream()
            .map(mapper::toDto)
            .collect(Collectors.toList());
    }

    public TaskDto getById(UUID id, UUID userId) {
        log.debug("getById called id={}, userId={}", id, userId);
        Task task = repository.findById(id)
            .orElseThrow(() -> ResourceNotFoundException.taskNotFound(id.toString()));

        if (!task.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Task does not belong to user");
        }

        return mapper.toDto(task);
    }

    public TaskDto update(UUID id, TaskUpdateRequest request, UUID userId) {
        log.debug("update called id={}, userId={}", id, userId);

        Task existing = repository.findById(id)
            .orElseThrow(() -> ResourceNotFoundException.taskNotFound(id.toString()));

        if (!existing.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Task does not belong to user");
        }

        if (request.getTitle() != null) {
            existing.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            existing.setDescription(request.getDescription());
        }
        if (request.getStatus() != null) {
            existing.setStatus(Task.Status.valueOf(request.getStatus()));
        }
        existing.setUpdatedAt(Instant.now());

        Task saved = repository.save(existing);
        log.info("Task updated id={}, userId={}, status={}", saved.getId(), saved.getUserId(), saved.getStatus());
        return mapper.toDto(saved);
    }

    public void delete(UUID id, UUID userId) {
        log.debug("delete called id={}, userId={}", id, userId);

        Task task = repository.findById(id)
            .orElseThrow(() -> ResourceNotFoundException.taskNotFound(id.toString()));

        if (!task.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Task does not belong to user");
        }

        task.softDelete();
        repository.save(task);
        log.info("Task soft-deleted id={}, userId={}", id, userId);
    }

    public TaskDto softDelete(UUID id, UUID userId) {
        log.debug("softDelete called id={}, userId={}", id, userId);

        Task task = repository.findById(id)
            .orElseThrow(() -> ResourceNotFoundException.taskNotFound(id.toString()));

        if (!task.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Task does not belong to user");
        }

        task.softDelete();
        Task saved = repository.save(task);
        log.info("Task soft-deleted id={}, userId={}", saved.getId(), userId);
        return mapper.toDto(saved);
    }

    public TaskDto restore(UUID id, UUID userId) {
        log.debug("restore called id={}, userId={}", id, userId);

        Task task = repository.findById(id)
            .orElseThrow(() -> ResourceNotFoundException.taskNotFound(id.toString()));

        if (!task.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Task does not belong to user");
        }

        task.restore();
        Task saved = repository.save(task);
        log.info("Task restored id={}, userId={}", saved.getId(), userId);
        return mapper.toDto(saved);
    }

    public List<TaskDto> listDeletedTasks(UUID userId) {
        log.debug("listDeletedTasks called userId={}", userId);
        return repository.findByUserIdAndDeletedAtIsNotNullOrderByDeletedAtDesc(userId).stream()
            .map(mapper::toDto)
            .collect(Collectors.toList());
    }

    @Transactional
    public TaskProgressResponseDto getTaskProgress(UUID taskId, UUID userId) {
        log.debug("getTaskProgress called taskId={}, userId={}", taskId, userId);

        getById(taskId, userId);

        List<SessionRecord> sessions = sessionRecordRepository.findByTaskIdAndKindAndCompletedTrue(taskId, SessionRecord.Kind.WORK);
        int completedSessions = sessions.size();
        long totalTimeSpentSeconds = sessions.stream().mapToLong(SessionRecord::getDurationSeconds).sum();
        double progressPercentage = (completedSessions / 4.0) * 100.0;

        return new TaskProgressResponseDto(completedSessions, totalTimeSpentSeconds, Math.min(progressPercentage, 100.0));
    }

    // Analytics methods
    public long countTasksForUser(UUID userId) {
        return repository.countByUserId(userId);
    }

    public long countTasksForUserByStatus(UUID userId, Task.Status status) {
        return repository.countByUserIdAndStatus(userId, status);
    }
}