package com.sparkage.timebeam.infrastructure.persistence;

import com.sparkage.timebeam.presentation.dto.TaskDto;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2025-12-22T14:58:28+0000",
    comments = "version: 1.5.5.Final, compiler: Eclipse JDT (IDE) 3.44.0.v20251118-1623, environment: Java 25.0.1 (Oracle Corporation)"
)
@Component
public class TaskMapperImpl implements TaskMapper {

    @Override
    public TaskDto toDto(Task entity) {
        if ( entity == null ) {
            return null;
        }

        TaskDto taskDto = new TaskDto();

        taskDto.setId( entity.getId() );
        taskDto.setUserId( entity.getUserId() );
        taskDto.setTitle( entity.getTitle() );
        taskDto.setDescription( entity.getDescription() );
        taskDto.setStatus( statusToString( entity.getStatus() ) );
        taskDto.setCreatedAt( entity.getCreatedAt() );
        taskDto.setUpdatedAt( entity.getUpdatedAt() );

        return taskDto;
    }

    @Override
    public Task toEntity(TaskDto dto) {
        if ( dto == null ) {
            return null;
        }

        Task task = new Task();

        task.setId( dto.getId() );
        task.setUserId( dto.getUserId() );
        task.setTitle( dto.getTitle() );
        task.setDescription( dto.getDescription() );
        task.setStatus( stringToStatus( dto.getStatus() ) );
        task.setCreatedAt( dto.getCreatedAt() );
        task.setUpdatedAt( dto.getUpdatedAt() );

        return task;
    }
}
