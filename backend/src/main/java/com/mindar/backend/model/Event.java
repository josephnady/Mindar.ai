package com.mindar.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

/**
 * A single captured "thought": the transcribed text of a voice note,
 * tagged with an EventType and pinned to the calendar day it was created for.
 */
@Entity
@Table(name = "event", indexes = {
        @Index(name = "idx_event_user_date", columnList = "user_id,eventDate")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EventType eventType;

    /** The day this thought is filed under (selected by the user before recording). */
    @Column(nullable = false)
    private LocalDate eventDate;

    /** Optional short title, auto-derived from the transcript if not supplied. */
    @Column
    private String title;

    /** Full transcribed text from the voice recording. */
    @Lob
    @Column(nullable = false)
    private String transcript;

    /** Only relevant for TODO type; ignored otherwise. */
    @Column
    private Boolean completed;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
        if (this.eventType == EventType.TODO && this.completed == null) {
            this.completed = false;
        }
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = Instant.now();
    }
}
