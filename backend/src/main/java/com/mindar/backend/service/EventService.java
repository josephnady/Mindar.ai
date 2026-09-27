package com.mindar.backend.service;

import com.mindar.backend.dto.EventDtos.*;
import com.mindar.backend.model.Event;
import com.mindar.backend.model.EventType;
import com.mindar.backend.model.User;
import com.mindar.backend.repository.EventRepository;
import com.mindar.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class EventService {

    private final EventRepository eventRepository;
    private final UserRepository userRepository;

    public EventResponse create(Long userId, CreateEventRequest req) {
        User user = userRepository.getReferenceById(userId);

        String derivedTitle = req.title() != null && !req.title().isBlank()
                ? req.title()
                : deriveTitle(req.transcript());

        Event event = Event.builder()
                .user(user)
                .eventType(req.eventType())
                .eventDate(req.eventDate())
                .title(derivedTitle)
                .transcript(req.transcript())
                .build();

        return toResponse(eventRepository.save(event));
    }

    public List<EventResponse> getForRange(Long userId, LocalDate start, LocalDate end) {
        return eventRepository
                .findByUserIdAndEventDateBetweenOrderByEventDateAscCreatedAtAsc(userId, start, end)
                .stream().map(this::toResponse).toList();
    }

    public List<EventResponse> getForDay(Long userId, LocalDate day) {
        return eventRepository.findByUserIdAndEventDateOrderByCreatedAtAsc(userId, day)
                .stream().map(this::toResponse).toList();
    }

    public EventResponse update(Long userId, Long eventId, UpdateEventRequest req) {
        Event event = getOwned(userId, eventId);

        if (req.title() != null) event.setTitle(req.title());
        if (req.transcript() != null) event.setTranscript(req.transcript());
        if (req.completed() != null) event.setCompleted(req.completed());

        return toResponse(eventRepository.save(event));
    }

    public void delete(Long userId, Long eventId) {
        Event event = getOwned(userId, eventId);
        eventRepository.delete(event);
    }

    private Event getOwned(Long userId, Long eventId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Event not found"));
        if (!event.getUser().getId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You do not own this event");
        }
        return event;
    }

    private String deriveTitle(String transcript) {
        String trimmed = transcript.trim();
        int cutoff = Math.min(60, trimmed.length());
        String snippet = trimmed.substring(0, cutoff);
        return cutoff < trimmed.length() ? snippet + "..." : snippet;
    }

    private EventResponse toResponse(Event e) {
        return new EventResponse(
                e.getId(), e.getEventType(), e.getEventDate(), e.getTitle(),
                e.getTranscript(), e.getCompleted(), e.getCreatedAt(), e.getUpdatedAt()
        );
    }
}
