import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event_type.dart';
import '../models/mind_event.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/event_type_dialog.dart';
import '../widgets/voice_input_dialog.dart';
import 'login_screen.dart';

enum CalendarViewMode { day, week, month }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _api = ApiService();
  CalendarViewMode _mode = CalendarViewMode.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<DateTime, List<MindEvent>> _eventsByDay = {};
  List<MindEvent> _selectedDayEvents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedDay);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _loadMonth(DateTime anyDayInMonth) async {
    setState(() => _loading = true);
    final start = DateTime(anyDayInMonth.year, anyDayInMonth.month, 1);
    final end = DateTime(anyDayInMonth.year, anyDayInMonth.month + 1, 0);
    try {
      final events = await _api.getEventsForRange(start, end);
      final grouped = <DateTime, List<MindEvent>>{};
      for (final e in events) {
        final key = _dateOnly(e.eventDate);
        grouped.putIfAbsent(key, () => []).add(e);
      }
      setState(() {
        _eventsByDay = grouped;
        _selectedDayEvents = grouped[_dateOnly(_selectedDay)] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<MindEvent> _eventsForDay(DateTime day) =>
      _eventsByDay[_dateOnly(day)] ?? [];

  Future<void> _onDaySelected(DateTime selected, DateTime focused) async {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
      _selectedDayEvents = _eventsForDay(selected);
    });
    final chosenType = await showEventTypeDialog(context, selected);
    if (chosenType == null || !mounted) return;

    final transcript = await showVoiceInputDialog(context, chosenType);
    if (transcript == null || transcript.trim().isEmpty || !mounted) return;

    try {
      await _api.createEvent(
          type: chosenType, date: selected, transcript: transcript);
      await _loadMonth(_focusedDay);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not save that thought. Please try again.')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  int _countOf(EventType type) => _eventsByDay.values
      .expand((l) => l)
      .where((e) => e.eventType == type)
      .length;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 760;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildSummaryBar(),
              const SizedBox(height: 16),
              Expanded(
                child: isWide
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildCalendarCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildNotesPanel()),
                  ],
                )
                    : Column(
                  children: [
                    _buildCalendarCard(),
                    const SizedBox(height: 16),
                    Expanded(child: _buildNotesPanel()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );

    return Row(
      children: [
        Image.asset('assets/mindar_icon.png', width: 50, height: 50),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Make room for ', style: titleStyle),
            Text(
              'what matters ',
              style: titleStyle?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
            onPressed: _logout, icon: const Icon(Icons.logout, size: 20)),
      ],
    );
  }



  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
          color: AppColors.navy, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('THIS VIEW',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            letterSpacing: 1)),
                    const SizedBox(width: 8),
                    Text('${_eventsByDay.values.expand((l) => l).length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8), const Text('thoughts captured',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                  ],
                ),

                Row(
                  children: [
                    _legendDot(AppColors.learning, 'Learning',
                        _countOf(EventType.learningConcept)),
                    const SizedBox(width: 16),
                    _legendDot(AppColors.meeting, 'Meetings',
                        _countOf(EventType.meeting)),
                    const SizedBox(width: 16),
                    _legendDot(AppColors.todo, 'To-dos',
                        _countOf(EventType.todo)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _onDaySelected(_selectedDay, _focusedDay),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(''),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, int count) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(width: 4),
        Text('$count',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _viewToggle(), // Aligned to the start
              const Spacer(),
              TextButton(
                  onPressed: () =>
                      _onDaySelected(DateTime.now(), DateTime.now()),
                  child: const Text('Today')),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final prev =
                  DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                  setState(() => _focusedDay = prev);
                  _loadMonth(prev);
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final next =
                  DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                  setState(() => _focusedDay = next);
                  _loadMonth(next);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          TableCalendar<MindEvent>(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: switch (_mode) {
              CalendarViewMode.month => CalendarFormat.month,
              CalendarViewMode.week => CalendarFormat.week,
              CalendarViewMode.day =>
              CalendarFormat.week, // custom day strip below
            },
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: _eventsForDay,
            onDaySelected: _onDaySelected,
            onPageChanged: (focused) {
              _focusedDay = focused;
              _loadMonth(focused);
            },
            headerVisible: false,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.5),
                  shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
              markerDecoration: const BoxDecoration(
                  color: AppColors.navy, shape: BoxShape.circle),
              markersMaxCount: 3,
            ),
          ),
          if (_mode == CalendarViewMode.day) _buildDayAgenda(),
        ],
      ),
    );
  }

  Widget _buildDayAgenda() {
    final dayEvents = _eventsForDay(_selectedDay);
    if (dayEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No thoughts captured for this day yet.',
            style: TextStyle(color: AppColors.subtleGrey)),
      );
    }
    return Column(
      children: dayEvents.map((e) => _eventTile(e)).toList(),
    );
  }

  Widget _viewToggle() {
    return SegmentedButton<CalendarViewMode>(
      showSelectedIcon: false, // Smaller footprint
      style: const ButtonStyle(
        visualDensity: VisualDensity.comfortable,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: const [
        ButtonSegment(
          value: CalendarViewMode.day,
          label: Text('Day', style: TextStyle(fontSize: 12)),
        ),
        ButtonSegment(
          value: CalendarViewMode.week,
          label: Text('Week', style: TextStyle(fontSize: 12)),
        ),
        ButtonSegment(
          value: CalendarViewMode.month,
          label: Text('Month', style: TextStyle(fontSize: 12)),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (s) => setState(() => _mode = s.first),
    );
  }
  
  Widget _buildNotesPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('YOUR NOTES',
              style: TextStyle(
                  fontSize: 11, letterSpacing: 1, color: AppColors.subtleGrey)),
          Text(_formatFullDate(_selectedDay),
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const Divider(height: 24),
          Expanded(
            child: _selectedDayEvents.isEmpty
                ? const Center(
                child: Text(
                    'Nothing here yet.\nTap "New thought" to record one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.subtleGrey)))
                : ListView.builder(
              itemCount: _selectedDayEvents.length,
              itemBuilder: (_, i) => _eventTile(_selectedDayEvents[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(MindEvent e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: e.eventType.color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(e.eventType.icon, color: e.eventType.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.eventType.label.toUpperCase()}',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.5,
                        color: e.eventType.color,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(e.transcript,
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime d) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}