package com.sparkage.synapse.domain.model;

import java.util.UUID;

public class User {
    private final UUID id;
    private final String email;
    private final String displayName;
    private final boolean admin;

    public User(UUID id, String email, String displayName, boolean admin) {
        this.id = id;
        this.email = validateEmail(email);
        this.displayName = validateDisplayName(displayName);
        this.admin = admin;
    }

    public UUID getId() { return id; }

    public String getEmail() { return email; }

    public String getDisplayName() { return displayName; }

    public boolean isAdmin() { return admin; }

    // Domain validation methods
    private String validateEmail(String email) {
        if (email == null || email.trim().isEmpty()) {
            throw new IllegalArgumentException("Email cannot be null or empty");
        }
        if (!email.contains("@")) {
            throw new IllegalArgumentException("Invalid email format");
        }
        return email.trim().toLowerCase();
    }

    private String validateDisplayName(String displayName) {
        if (displayName == null || displayName.trim().isEmpty()) {
            throw new IllegalArgumentException("Display name cannot be null or empty");
        }
        return displayName.trim();
    }

    // Domain methods
    public boolean canAccessAdminFeatures() {
        return admin;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;
        User user = (User) obj;
        return id.equals(user.id);
    }

    @Override
    public int hashCode() {
        return id.hashCode();
    }

    @Override
    public String toString() {
        return "User{id=" + id + ", email='" + email + "', displayName='" + displayName + "', admin=" + admin + '}';
    }
}
