package com.sparkage.synapse.infrastructure.persistence;

import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "users")
public class User {
    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String displayName;

    @Column(name = "is_admin", nullable = false)
    private boolean admin;

    public User() {}

    public User(UUID id, String email, String displayName, boolean admin) {
        this.id = id;
        this.email = email;
        this.displayName = displayName;
        this.admin = admin;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }

    public boolean isAdmin() { return admin; }
    public void setAdmin(boolean admin) { this.admin = admin; }
}
