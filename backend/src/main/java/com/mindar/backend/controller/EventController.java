package com.mindar.backend.controller;

import com.mindar.backend.dto.EventDtos.*;
import com.mindar.backend.security.AuthenticatedUser;
import com.mindar.backend.service.EventService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    @PostMapping
    public ResponseEntity<EventResponse> create(@AuthenticationPrincipal AuthenticatedUser user,
                                                 @Valid @RequestBody CreateEventRequest request) {
        return ResponseEntity.ok(eventService.create(user.userId(), request));
    }

    /** Used to populate the month/week grid in one call, e.g. ?start=2026-09-01&end=2026-09-30 */
    @GetMapping
    public ResponseEntity<List<EventResponse>> getRange(
            @AuthenticationPrincipal AuthenticatedUser user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end) {
        return ResponseEntity.ok(eventService.getForRange(user.userId(), start, end));
    }

    @GetMapping("/day/{date}")
    public ResponseEntity<List<EventResponse>> getDay(
            @AuthenticationPrincipal AuthenticatedUser user,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(eventService.getForDay(user.userId(), date));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<EventResponse> update(
            @AuthenticationPrincipal AuthenticatedUser user,
            @PathVariable Long id,
            @RequestBody UpdateEventRequest request) {
        return ResponseEntity.ok(eventService.update(user.userId(), id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable Long id) {
        eventService.delete(user.userId(), id);
        return ResponseEntity.noContent().build();
    }
}
