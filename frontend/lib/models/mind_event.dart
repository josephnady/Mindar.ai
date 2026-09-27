import 'event_type.dart';

/// A captured voice thought, as returned by GET/POST /api/events.
class MindEvent {
  final int? id;
  final EventType eventType;
  final DateTime eventDate;
  final String title;
  final String transcript;
  final bool? completed;
  final DateTime? createdAt;

  MindEvent({
    this.id,
    required this.eventType,
    required this.eventDate,
    required this.title,
    required this.transcript,
    this.completed,
    this.createdAt,
  });

  factory MindEvent.fromJson(Map<String, dynamic> json) => MindEvent(
        id: json['id'] as int?,
        eventType: EventTypeX.fromApiValue(json['eventType'] as String),
        eventDate: DateTime.parse(json['eventDate'] as String),
        title: json['title'] as String? ?? '',
        transcript: json['transcript'] as String,
        completed: json['completed'] as bool?,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      );

  Map<String, dynamic> toCreateJson() => {
        'eventType': eventType.apiValue,
        'eventDate':
            '${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}',
        'title': title,
        'transcript': transcript,
      };
}
