package com.sparkage.timebeam.infrastructure.persistence;

import com.sparkage.timebeam.domain.model.User;
import com.sparkage.timebeam.presentation.dto.UserDto;
import java.util.UUID;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2025-12-22T12:36:56+0000",
    comments = "version: 1.5.5.Final, compiler: Eclipse JDT (IDE) 3.44.0.v20251118-1623, environment: Java 25.0.1 (Oracle Corporation)"
)
@Component
public class UserMapperImpl implements UserMapper {

    @Override
    public UserDto toDto(User domainUser) {
        if ( domainUser == null ) {
            return null;
        }

        UserDto userDto = new UserDto();

        userDto.setId( domainUser.getId() );
        userDto.setEmail( domainUser.getEmail() );
        userDto.setDisplayName( domainUser.getDisplayName() );

        return userDto;
    }

    @Override
    public User toDomain(com.sparkage.timebeam.infrastructure.persistence.User entity) {
        if ( entity == null ) {
            return null;
        }

        UUID id = null;
        String email = null;
        String displayName = null;
        boolean admin = false;

        id = entity.getId();
        email = entity.getEmail();
        displayName = entity.getDisplayName();
        admin = entity.isAdmin();

        User user = new User( id, email, displayName, admin );

        return user;
    }

    @Override
    public com.sparkage.timebeam.infrastructure.persistence.User toEntity(User domainUser) {
        if ( domainUser == null ) {
            return null;
        }

        com.sparkage.timebeam.infrastructure.persistence.User user = new com.sparkage.timebeam.infrastructure.persistence.User();

        user.setId( domainUser.getId() );
        user.setEmail( domainUser.getEmail() );
        user.setDisplayName( domainUser.getDisplayName() );
        user.setAdmin( domainUser.isAdmin() );

        return user;
    }
}
