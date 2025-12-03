package com.sparkage.timebeam.domain.repository;

import java.util.Optional;
import java.util.UUID;

import com.sparkage.timebeam.domain.model.User;

public interface UserRepository {
    Optional<User> findById(UUID id);
    Optional<User> findByEmail(String email);
    User save(User user);
    void deleteById(UUID id);
    boolean existsByEmail(String email);
}
