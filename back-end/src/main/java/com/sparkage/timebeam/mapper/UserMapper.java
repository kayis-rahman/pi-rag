package com.sparkage.timebeam.mapper;

import com.sparkage.timebeam.dto.UserDto;
import com.sparkage.timebeam.model.User;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface UserMapper {
    UserDto toDto(User entity);
    User toEntity(UserDto dto);
}
