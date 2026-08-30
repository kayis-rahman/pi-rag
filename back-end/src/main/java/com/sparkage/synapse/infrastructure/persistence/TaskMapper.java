package com.sparkage.synapse.infrastructure.persistence;

import org.mapstruct.Mapper;

import com.sparkage.synapse.presentation.dto.TaskDto;

@Mapper(componentModel = "spring")
public interface TaskMapper {

    // MapStruct will use these helper methods when converting between String and enum
    default Task.Status stringToStatus(String status) {
        if (status == null) return null;
        // Normalize: convert camelCase to underscore (inProgress -> in_progress), replace non-alnum with underscore
        String withUnderscores = status.replaceAll("([a-z])([A-Z])", "$1_$2").replaceAll("[^A-Za-z0-9]", "_");
        String normalized = withUnderscores.toLowerCase();
        try {
            return Task.Status.valueOf(normalized);
        } catch (IllegalArgumentException e) {
            // try uppercased raw string as a fallback (e.g., "IN_PROGRESS" or "INPROGRESS")
            try {
                return Task.Status.valueOf(status.toLowerCase());
            } catch (Exception ex) {
                // As a last resort, return null so callers can handle invalid statuses
                return null;
            }
        }
    }

    default String statusToString(Task.Status status) {
        if (status == null) return null;
        // convert enum constant (in_progress) to camelCase style used by the client (inProgress)
        String lower = status.name().toLowerCase();
        // in_progress -> inProgress
        String[] parts = lower.split("_");
        if (parts.length == 1) return parts[0];
        StringBuilder sb = new StringBuilder(parts[0]);
        for (int i = 1; i < parts.length; i++) {
            sb.append(parts[i].substring(0,1).toUpperCase()).append(parts[i].substring(1));
        }
        return sb.toString();
    }

    TaskDto toDto(Task entity);
    Task toEntity(TaskDto dto);
}