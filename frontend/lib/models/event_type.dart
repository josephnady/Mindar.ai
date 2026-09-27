import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Mirrors backend `EventType` enum. Keep values in sync with the API.
enum EventType { learningConcept, meeting, todo }

extension EventTypeX on EventType {
  String get apiValue => switch (this) {
        EventType.learningConcept => 'LEARNING_CONCEPT',
        EventType.meeting => 'MEETING',
        EventType.todo => 'TODO',
      };

  String get label => switch (this) {
        EventType.learningConcept => 'Learning concept',
        EventType.meeting => 'Meeting',
        EventType.todo => 'To-do',
      };

  IconData get icon => switch (this) {
        EventType.learningConcept => Icons.menu_book_outlined,
        EventType.meeting => Icons.groups_outlined,
        EventType.todo => Icons.check_circle_outline,
      };

  Color get color => switch (this) {
        EventType.learningConcept => AppColors.learning,
        EventType.meeting => AppColors.meeting,
        EventType.todo => AppColors.todo,
      };

  static EventType fromApiValue(String value) => switch (value) {
        'LEARNING_CONCEPT' => EventType.learningConcept,
        'MEETING' => EventType.meeting,
        'TODO' => EventType.todo,
        _ => throw ArgumentError('Unknown event type: $value'),
      };
}
