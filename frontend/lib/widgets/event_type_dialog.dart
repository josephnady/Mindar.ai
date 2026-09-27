import 'package:flutter/material.dart';
import '../models/event_type.dart';
import '../theme/app_theme.dart';

/// Popup shown when a calendar day is tapped: "What kind of thought is this?"
/// Returns the chosen [EventType], or null if dismissed.
Future<EventType?> showEventTypeDialog(BuildContext context, DateTime day) {
  return showModalBottomSheet<EventType>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What kind of thought is this?',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_formatDay(day), style: const TextStyle(color: AppColors.subtleGrey)),
              const SizedBox(height: 18),
              ...EventType.values.map((type) => _TypeTile(
                    type: type,
                    onTap: () => Navigator.of(ctx).pop(type),
                  )),
            ],
          ),
        ),
      );
    },
  );
}

class _TypeTile extends StatelessWidget {
  final EventType type;
  final VoidCallback onTap;
  const _TypeTile({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: type.color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: type.color, child: Icon(type.icon, color: Colors.white, size: 20)),
        title: Text(type.label, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

String _formatDay(DateTime d) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
