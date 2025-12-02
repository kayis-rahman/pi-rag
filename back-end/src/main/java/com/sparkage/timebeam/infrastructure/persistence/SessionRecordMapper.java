package com.sparkage.timebeam.infrastructure.persistence;

import com.sparkage.timebeam.presentation.dto.SessionRecordDto;
import com.sparkage.timebeam.infrastructure.persistence.SessionRecord;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface SessionRecordMapper {
    SessionRecordDto toDto(SessionRecord entity);
    SessionRecord toEntity(SessionRecordDto dto);

    // MapStruct will use these helper methods when converting between String and enum
    default SessionRecord.Kind stringToKind(String kind) {
        if (kind == null) return null;
        // Normalize: convert camelCase to underscore (shortBreak -> short_Break), replace non-alnum with underscore
        String withUnderscores = kind.replaceAll("([a-z])([A-Z])", "$1_$2").replaceAll("[^A-Za-z0-9]", "_");
        String normalized = withUnderscores.toUpperCase();
        try {
            return SessionRecord.Kind.valueOf(normalized);
        } catch (IllegalArgumentException e) {
            // try uppercased raw string as a fallback (e.g., "SHORT_BREAK" or "SHORTBREAK")
            try {
                return SessionRecord.Kind.valueOf(kind.toUpperCase());
            } catch (Exception ex) {
                // As a last resort, return null so callers can handle invalid kinds
                return null;
            }
        }
    }

    default String kindToString(SessionRecord.Kind kind) {
        if (kind == null) return null;
        // convert enum constant (SHORT_BREAK) to camelCase style used by the client (shortBreak)
        String lower = kind.name().toLowerCase();
        // SHORT_BREAK -> short_break -> shortBreak
        String[] parts = lower.split("_");
        if (parts.length == 1) return parts[0];
        StringBuilder sb = new StringBuilder(parts[0]);
        for (int i = 1; i < parts.length; i++) {
            sb.append(parts[i].substring(0,1).toUpperCase()).append(parts[i].substring(1));
        }
        return sb.toString();
    }
}
