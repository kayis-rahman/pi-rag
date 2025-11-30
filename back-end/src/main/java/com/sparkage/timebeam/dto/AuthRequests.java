package com.sparkage.timebeam.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public class AuthRequests {
    public static class Register {
        @Email
        @NotBlank
        private String email;
        @NotBlank
        private String displayName;

        public Register() {}
        public Register(String email, String displayName) { this.email = email; this.displayName = displayName; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getDisplayName() { return displayName; }
        public void setDisplayName(String displayName) { this.displayName = displayName; }
    }

    public static class Login {
        @Email
        @NotBlank
        private String email;

        public Login() {}
        public Login(String email) { this.email = email; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }
}
