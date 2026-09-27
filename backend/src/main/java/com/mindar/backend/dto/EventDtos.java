package com.mindar.backend.dto;

import com.mindar.backend.model.EventType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.time.LocalDate;

public class EventDtos {

    /** Sent once the voice recording has been transcribed on-device. */
    public record CreateEventRequest(
            @NotNull EventType eventType,
            @NotNull LocalDate eventDate,
            String title,
            @NotBlank String transcript
    ) {}

    public record UpdateEventRequest(
            String title,
            String transcript,
            Boolean completed
    ) {}

    public record EventResponse(
            Long id,
            EventType eventType,
            LocalDate eventDate,
            String title,
            String transcript,
            Boolean completed,
            Instant createdAt,
            Instant updatedAt
    ) {}

    /** Lightweight summary used to render dots/counters on calendar cells. */
    public record DayCount(
            LocalDate date,
            long learningConcept,
            long meeting,
            long todo
    ) {}
}
