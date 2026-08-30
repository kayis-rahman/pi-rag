package com.sparkage.synapse.infrastructure.persistence;

import org.mapstruct.Mapper;
import org.springframework.stereotype.Component;

import com.sparkage.synapse.domain.model.User;
import com.sparkage.synapse.presentation.dto.UserDto;

@Mapper(componentModel = "spring")
@Component
public interface UserMapper {
    UserDto toDto(User domainUser);
    User toDomain(com.sparkage.synapse.infrastructure.persistence.User entity);
    com.sparkage.synapse.infrastructure.persistence.User toEntity(User domainUser);
}
