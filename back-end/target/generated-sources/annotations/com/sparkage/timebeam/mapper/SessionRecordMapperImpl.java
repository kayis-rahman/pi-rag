package com.sparkage.timebeam.mapper;

import com.sparkage.timebeam.dto.SessionRecordDto;
import com.sparkage.timebeam.model.SessionRecord;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2025-12-01T10:58:42+0000",
    comments = "version: 1.5.5.Final, compiler: Eclipse JDT (IDE) 3.44.0.v20251118-1623, environment: Java 25.0.1 (Oracle Corporation)"
)
@Component
public class SessionRecordMapperImpl implements SessionRecordMapper {

    @Override
    public SessionRecordDto toDto(SessionRecord entity) {
        if ( entity == null ) {
            return null;
        }

        SessionRecordDto sessionRecordDto = new SessionRecordDto();

        sessionRecordDto.setId( entity.getId() );
        sessionRecordDto.setUserId( entity.getUserId() );
        sessionRecordDto.setStartedAt( entity.getStartedAt() );
        sessionRecordDto.setDurationSeconds( entity.getDurationSeconds() );
        sessionRecordDto.setKind( kindToString( entity.getKind() ) );

        return sessionRecordDto;
    }

    @Override
    public SessionRecord toEntity(SessionRecordDto dto) {
        if ( dto == null ) {
            return null;
        }

        SessionRecord sessionRecord = new SessionRecord();

        sessionRecord.setId( dto.getId() );
        sessionRecord.setUserId( dto.getUserId() );
        sessionRecord.setStartedAt( dto.getStartedAt() );
        sessionRecord.setDurationSeconds( dto.getDurationSeconds() );
        sessionRecord.setKind( stringToKind( dto.getKind() ) );

        return sessionRecord;
    }
}
