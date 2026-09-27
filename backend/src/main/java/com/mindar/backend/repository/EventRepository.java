package com.mindar.backend.repository;

import com.mindar.backend.model.Event;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface EventRepository extends JpaRepository<Event, Long> {

    List<Event> findByUserIdAndEventDateBetweenOrderByEventDateAscCreatedAtAsc(
            Long userId, LocalDate start, LocalDate end);

    List<Event> findByUserIdAndEventDateOrderByCreatedAtAsc(Long userId, LocalDate date);

    long countByUserIdAndEventDateBetween(Long userId, LocalDate start, LocalDate end);
}
