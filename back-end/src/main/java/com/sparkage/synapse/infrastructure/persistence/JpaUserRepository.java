package com.sparkage.synapse.infrastructure.persistence;

import java.util.Optional;
import java.util.UUID;

import org.springframework.stereotype.Repository;

import com.sparkage.synapse.domain.model.User;
import com.sparkage.synapse.domain.repository.UserRepository;

@Repository
public class JpaUserRepository implements UserRepository {
    private final UserJpaRepository jpaRepository;
    private final UserMapper mapper;

    public JpaUserRepository(UserJpaRepository jpaRepository, UserMapper mapper) {
        this.jpaRepository = jpaRepository;
        this.mapper = mapper;
    }

    @Override
    public Optional<User> findById(UUID id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<User> findByEmail(String email) {
        return jpaRepository.findByEmail(email).map(mapper::toDomain);
    }

    @Override
    public User save(User user) {
        com.sparkage.synapse.infrastructure.persistence.User entity = mapper.toEntity(user);
        entity = jpaRepository.save(entity);
        return mapper.toDomain(entity);
    }

    @Override
    public void deleteById(UUID id) {
        jpaRepository.deleteById(id);
    }

    @Override
    public boolean existsByEmail(String email) {
        return jpaRepository.existsByEmail(email);
    }
}
