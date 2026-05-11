package com.sparkage.timebeam.presentation.controller;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sparkage.timebeam.application.service.TaskService;
import com.sparkage.timebeam.infrastructure.external.UserNotAuthenticatedException;
import com.sparkage.timebeam.presentation.dto.TaskCreateRequest;
import com.sparkage.timebeam.presentation.dto.TaskDto;
import com.sparkage.timebeam.presentation.dto.TaskProgressResponseDto;
import com.sparkage.timebeam.presentation.dto.TaskUpdateRequest;

@RestController
@RequestMapping("/api/tasks")
@PreAuthorize("isAuthenticated()")
public class TaskController {
    private static final Logger log = LoggerFactory.getLogger(TaskController.class);

    private final TaskService taskService;

    public TaskController(TaskService taskService) {
        this.taskService = taskService;
    }

    @PostMapping
    public ResponseEntity<TaskDto> create(@Validated @RequestBody TaskCreateRequest request, Principal principal) {
        log.debug("create task request received: title={}", request.getTitle());
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        TaskDto created = taskService.create(request, uid);
        log.info("task created: id={}, userId={}, title={}", created.getId(), created.getUserId(), created.getTitle());
        return ResponseEntity.status(201).body(created);
    }

    @GetMapping
    public ResponseEntity<List<TaskDto>> listForCurrentUser(Principal principal) {
        log.debug("list tasks for current user called");
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        log.debug("listing tasks for userId={}", uid);
        return ResponseEntity.ok(taskService.listForUser(uid));
    }

    @GetMapping("/active")
    public ResponseEntity<List<TaskDto>> listActiveTasksForCurrentUser(Principal principal) {
        log.debug("list active tasks for current user called");
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        log.debug("listing active tasks for userId={}", uid);
        return ResponseEntity.ok(taskService.listActiveTasksForUser(uid));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TaskDto> getById(@PathVariable("id") UUID id, Principal principal) {
        log.debug("get task by id called: id={}", id);
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        TaskDto task = taskService.getById(id, uid);
        return ResponseEntity.ok(task);
    }

    @PutMapping("/{id}")
    public ResponseEntity<TaskDto> update(@PathVariable("id") UUID id,
                                         @Validated @RequestBody TaskUpdateRequest request,
                                         Principal principal) {
        log.debug("update task called: id={}", id);
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        TaskDto updated = taskService.update(id, request, uid);
        log.info("task updated: id={}, userId={}", updated.getId(), updated.getUserId());
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable("id") UUID id, Principal principal) {
        log.debug("delete task called for id={}", id);
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        taskService.delete(id, uid);
        log.info("task deleted: id={}", id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/soft-delete")
    public ResponseEntity<TaskDto> softDelete(@PathVariable("id") UUID id, Principal principal) {
        log.debug("soft-delete task called for id={}", id);
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        TaskDto dto = taskService.softDelete(id, uid);
        return ResponseEntity.ok(dto);
    }

    @PostMapping("/{id}/restore")
    public ResponseEntity<TaskDto> restore(@PathVariable("id") UUID id, Principal principal) {
        log.debug("restore task called for id={}", id);
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        TaskDto dto = taskService.restore(id, uid);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/deleted")
    public ResponseEntity<List<TaskDto>> listDeleted(Principal principal) {
        log.debug("list deleted tasks for current user called");
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        return ResponseEntity.ok(taskService.listDeletedTasks(uid));
    }

    @GetMapping("/{id}/progress")
    public ResponseEntity<TaskProgressResponseDto> getProgress(@PathVariable("id") UUID id, Principal principal) {
        log.debug("get task progress called for id={}", id);
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        return ResponseEntity.ok(taskService.getTaskProgress(id, uid));
    }

    // Helper to resolve UUID user id from Principal. Returns null on missing/invalid principal.
    private UUID resolveUserId(Principal principal) {
        if (principal == null || principal.getName() == null) {
            log.info("principal missing or has null name");
            return null;
        }
        try {
            return UUID.fromString(principal.getName());
        } catch (Exception ex) {
            log.info("invalid principal name for UUID conversion: {}", principal.getName());
            return null;
        }
    }
}