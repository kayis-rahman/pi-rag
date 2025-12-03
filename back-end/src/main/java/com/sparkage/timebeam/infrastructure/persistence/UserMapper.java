package com.sparkage.timebeam.infrastructure.persistence;

import org.mapstruct.Mapper;
import org.springframework.stereotype.Component;

import com.sparkage.timebeam.domain.model.User;
import com.sparkage.timebeam.presentation.dto.UserDto;

@Mapper(componentModel = "spring")
@Component
public interface UserMapper {
    UserDto toDto(User domainUser);
    User toDomain(com.sparkage.timebeam.infrastructure.persistence.User entity);
    com.sparkage.timebeam.infrastructure.persistence.User toEntity(User domainUser);
}
