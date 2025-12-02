package com.sparkage.timebeam.infrastructure.persistence;

import com.sparkage.timebeam.presentation.dto.UserDto;
import com.sparkage.timebeam.domain.model.User;
import org.mapstruct.Mapper;
import org.springframework.stereotype.Component;

@Mapper(componentModel = "spring")
@Component
public interface UserMapper {
    UserDto toDto(User domainUser);
    User toDomain(com.sparkage.timebeam.infrastructure.persistence.User entity);
    com.sparkage.timebeam.infrastructure.persistence.User toEntity(User domainUser);
}
