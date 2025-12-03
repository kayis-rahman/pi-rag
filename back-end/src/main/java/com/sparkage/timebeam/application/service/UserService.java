package com.sparkage.timebeam.application.service;

import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.sparkage.timebeam.domain.model.User;
import com.sparkage.timebeam.domain.repository.UserRepository;
import com.sparkage.timebeam.infrastructure.persistence.UserMapper;
import com.sparkage.timebeam.presentation.dto.UserDto;

@Service
public class UserService {
    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    public UserService(UserRepository userRepository, UserMapper userMapper) {
        this.userRepository = userRepository;
        this.userMapper = userMapper;
    }

    public UserDto createUser(String email, String displayName) {
        log.debug("createUser called email={}, displayName={}", email, displayName);
        User user = new User(UUID.randomUUID(), email, displayName, false);
        userRepository.save(user);
        log.info("user created id={}, email={}", user.getId(), maskEmail(user.getEmail()));
        return userMapper.toDto(user);
    }

    public Optional<User> findByEmail(String email) {
        log.debug("findByEmail called for email={}", email);
        return userRepository.findByEmail(email);
    }

    public Optional<UserDto> findDtoById(UUID id) {
        log.debug("findDtoById called id={}", id);
        return userRepository.findById(id).map(userMapper::toDto);
    }

    private String maskEmail(String email) {
        if (email == null) return "null";
        int at = email.indexOf('@');
        if (at <= 1) return "****" + (at > 0 ? email.substring(at) : "");
        return email.charAt(0) + "****" + email.substring(at);
    }
}
