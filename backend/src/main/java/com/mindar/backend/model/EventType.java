package com.mindar.backend.model;

/**
 * The kinds of "thoughts" a user can capture against a calendar day.
 * Extendable later (e.g. IDEA, REMINDER) without breaking the API contract
 * since the client renders this as a plain string.
 */
public enum EventType {
    LEARNING_CONCEPT,
    MEETING,
    TODO
}
