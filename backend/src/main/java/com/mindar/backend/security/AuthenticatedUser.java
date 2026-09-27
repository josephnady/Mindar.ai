package com.mindar.backend.security;

/** Lightweight principal placed in the SecurityContext after a JWT is validated. */
public record AuthenticatedUser(Long userId, String email) {
}
