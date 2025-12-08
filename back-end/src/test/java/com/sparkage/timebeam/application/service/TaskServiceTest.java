package com.sparkage.timebeam.application.service;

import com.sparkage.timebeam.infrastructure.external.ResourceNotFoundException;
import com.sparkage.timebeam.infrastructure.persistence.Task;
import com.sparkage.timebeam.infrastructure.persistence.TaskMapper;
import com.sparkage.timebeam.infrastructure.persistence.TaskRepository;
import com.sparkage.timebeam.presentation.dto.TaskCreateRequest;
import com.sparkage.timebeam.presentation.dto.TaskDto;
import com.sparkage.timebeam.presentation.dto.TaskUpdateRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TaskServiceTest {

    @Mock
    private TaskRepository taskRepository;

    @Mock
    private TaskMapper taskMapper;

    @InjectMocks
    private TaskService taskService;

    private Task testTask;
    private TaskDto testTaskDto;
    private TaskCreateRequest testCreateRequest;
    private TaskUpdateRequest testUpdateRequest;

    @BeforeEach
    void setUp() {
        // Setup test data
        UUID taskId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        testTask = new Task();
        testTask.setId(taskId);
        testTask.setUserId(userId);
        testTask.setTitle("Test Task");
        testTask.setDescription("Test Description");
        testTask.setStatus(Task.Status.todo);
        testTask.setCreatedAt(Instant.now());
        testTask.setUpdatedAt(Instant.now());

        testTaskDto = new TaskDto();
        testTaskDto.setId(taskId);
        testTaskDto.setUserId(userId);
        testTaskDto.setTitle("Test Task");
        testTaskDto.setDescription("Test Description");
        testTaskDto.setStatus("todo");
        testTaskDto.setCreatedAt(Instant.now());
        testTaskDto.setUpdatedAt(Instant.now());

        testCreateRequest = new TaskCreateRequest();
        testCreateRequest.setTitle("New Task");
        testCreateRequest.setDescription("New Description");

        testUpdateRequest = new TaskUpdateRequest();
        testUpdateRequest.setTitle("Updated Task");
        testUpdateRequest.setDescription("Updated Description");
        testUpdateRequest.setStatus("completed");
    }

    @Test
    void create_shouldReturnCreatedTask() {
        // Arrange
        UUID userId = UUID.randomUUID();
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> {
            Task savedTask = invocation.getArgument(0);
            savedTask.setId(UUID.randomUUID());
            return savedTask;
        });
        when(taskMapper.toDto(any(Task.class))).thenAnswer(invocation -> {
            Task task = invocation.getArgument(0);
            TaskDto dto = new TaskDto();
            dto.setId(task.getId());
            dto.setUserId(task.getUserId());
            dto.setTitle(task.getTitle());
            dto.setDescription(task.getDescription());
            dto.setStatus(task.getStatus().name().toLowerCase());
            dto.setCreatedAt(task.getCreatedAt());
            dto.setUpdatedAt(task.getUpdatedAt());
            return dto;
        });

        // Act
        TaskDto result = taskService.create(testCreateRequest, userId);

        // Assert
        assertNotNull(result);
        assertEquals(testCreateRequest.getTitle(), result.getTitle());
        assertEquals(testCreateRequest.getDescription(), result.getDescription());
        assertEquals(userId, result.getUserId());
        assertEquals("todo", result.getStatus());
        assertNotNull(result.getId());
        assertNotNull(result.getCreatedAt());
        assertNotNull(result.getUpdatedAt());

        verify(taskRepository, times(1)).save(any(Task.class));
        verify(taskMapper, times(1)).toDto(any(Task.class));
    }

    @Test
    void getById_shouldReturnTaskWhenExists() {
        // Arrange
        UUID taskId = testTask.getId();
        UUID userId = testTask.getUserId();
        when(taskRepository.findById(taskId)).thenReturn(Optional.of(testTask));
        when(taskMapper.toDto(testTask)).thenReturn(testTaskDto);

        // Act
        TaskDto result = taskService.getById(taskId, userId);

        // Assert
        assertNotNull(result);
        assertEquals(testTaskDto.getId(), result.getId());
        assertEquals(testTaskDto.getTitle(), result.getTitle());

        verify(taskRepository, times(1)).findById(taskId);
        verify(taskMapper, times(1)).toDto(testTask);
    }

    @Test
    void getById_shouldThrowExceptionWhenNotFound() {
        // Arrange
        UUID nonExistentId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        when(taskRepository.findById(nonExistentId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(ResourceNotFoundException.class, () -> {
            taskService.getById(nonExistentId, userId);
        });

        verify(taskRepository, times(1)).findById(nonExistentId);
        verifyNoMoreInteractions(taskMapper);
    }

    @Test
    void listForUser_shouldReturnTaskList() {
        // Arrange
        UUID userId = testTask.getUserId();
        List<Task> taskList = List.of(testTask);
        List<TaskDto> taskDtoList = List.of(testTaskDto);

        when(taskRepository.findByUserIdOrderByCreatedAtDesc(userId)).thenReturn(taskList);
        when(taskMapper.toDto(testTask)).thenReturn(testTaskDto);

        // Act
        List<TaskDto> result = taskService.listForUser(userId);

        // Assert
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(taskDtoList, result);

        verify(taskRepository, times(1)).findByUserIdOrderByCreatedAtDesc(userId);
        verify(taskMapper, times(1)).toDto(testTask);
    }

    @Test
    void update_shouldReturnUpdatedTask() {
        // Arrange
        UUID taskId = testTask.getId();
        UUID userId = testTask.getUserId();
        when(taskRepository.findById(taskId)).thenReturn(Optional.of(testTask));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> {
            Task savedTask = invocation.getArgument(0);
            return savedTask;
        });
        when(taskMapper.toDto(any(Task.class))).thenAnswer(invocation -> {
            Task task = invocation.getArgument(0);
            TaskDto dto = new TaskDto();
            dto.setId(task.getId());
            dto.setUserId(task.getUserId());
            dto.setTitle(task.getTitle());
            dto.setDescription(task.getDescription());
            dto.setStatus(task.getStatus().name().toLowerCase());
            dto.setCreatedAt(task.getCreatedAt());
            dto.setUpdatedAt(task.getUpdatedAt());
            return dto;
        });

        // Act
        TaskDto result = taskService.update(taskId, testUpdateRequest, userId);

        // Assert
        assertNotNull(result);
        assertEquals(testTask.getId(), result.getId());
        assertEquals(testUpdateRequest.getTitle(), result.getTitle());
        assertEquals(testUpdateRequest.getDescription(), result.getDescription());
        assertEquals(testUpdateRequest.getStatus(), result.getStatus());
        assertNotNull(result.getUpdatedAt());

        verify(taskRepository, times(1)).findById(taskId);
        verify(taskRepository, times(1)).save(any(Task.class));
        verify(taskMapper, times(1)).toDto(any(Task.class));
    }

    @Test
    void update_shouldThrowExceptionWhenTaskNotFound() {
        // Arrange
        UUID nonExistentId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        when(taskRepository.findById(nonExistentId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(ResourceNotFoundException.class, () -> {
            taskService.update(nonExistentId, testUpdateRequest, userId);
        });

        verify(taskRepository, times(1)).findById(nonExistentId);
        verifyNoMoreInteractions(taskRepository);
        verifyNoMoreInteractions(taskMapper);
    }

    @Test
    void delete_shouldDeleteTaskSuccessfully() {
        // Arrange
        UUID taskId = testTask.getId();
        UUID userId = testTask.getUserId();
        when(taskRepository.findById(taskId)).thenReturn(Optional.of(testTask));
        doNothing().when(taskRepository).deleteById(taskId);

        // Act
        taskService.delete(taskId, userId);

        // Assert
        verify(taskRepository, times(1)).findById(taskId);
        verify(taskRepository, times(1)).deleteById(taskId);
    }

    @Test
    void delete_shouldThrowExceptionWhenTaskNotFound() {
        // Arrange
        UUID nonExistentId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        when(taskRepository.findById(nonExistentId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(ResourceNotFoundException.class, () -> {
            taskService.delete(nonExistentId, userId);
        });

        verify(taskRepository, times(1)).findById(nonExistentId);
        verifyNoMoreInteractions(taskRepository);
    }

    @Test
    void update_shouldMarkTaskAsCompleted() {
        // Arrange
        UUID taskId = testTask.getId();
        UUID userId = testTask.getUserId();
        testTask.setStatus(Task.Status.todo);

        TaskUpdateRequest completeRequest = new TaskUpdateRequest();
        completeRequest.setStatus("completed");

        when(taskRepository.findById(taskId)).thenReturn(Optional.of(testTask));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> {
            Task savedTask = invocation.getArgument(0);
            return savedTask;
        });
        when(taskMapper.toDto(any(Task.class))).thenAnswer(invocation -> {
            Task task = invocation.getArgument(0);
            TaskDto dto = new TaskDto();
            dto.setId(task.getId());
            dto.setUserId(task.getUserId());
            dto.setTitle(task.getTitle());
            dto.setDescription(task.getDescription());
            dto.setStatus(task.getStatus().name().toLowerCase());
            dto.setCreatedAt(task.getCreatedAt());
            dto.setUpdatedAt(task.getUpdatedAt());
            return dto;
        });

        // Act
        TaskDto result = taskService.update(taskId, completeRequest, userId);

        // Assert
        assertNotNull(result);
        assertEquals("completed", result.getStatus());
        assertNotNull(result.getUpdatedAt());

        verify(taskRepository, times(1)).findById(taskId);
        verify(taskRepository, times(1)).save(any(Task.class));
        verify(taskMapper, times(1)).toDto(any(Task.class));
    }

    @Test
    void update_shouldThrowExceptionWhenTaskNotFoundForCompletion() {
        // Arrange
        UUID nonExistentId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        TaskUpdateRequest completeRequest = new TaskUpdateRequest();
        completeRequest.setStatus("completed");

        when(taskRepository.findById(nonExistentId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(ResourceNotFoundException.class, () -> {
            taskService.update(nonExistentId, completeRequest, userId);
        });

        verify(taskRepository, times(1)).findById(nonExistentId);
        verifyNoMoreInteractions(taskRepository);
        verifyNoMoreInteractions(taskMapper);
    }
}
