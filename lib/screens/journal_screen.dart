import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../models/event_entry.dart';
import '../models/symptom_entry.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';

// ── Temperature label helper ──────────────────────────────────────────────────

/// Returns "High: 82° Low: 65°F" when high/low are available,
/// falling back to "Current: X°F" for legacy entries that only stored current.
String _tempLabel(EventEntry e) {
  if (e.tempHigh != null && e.tempLow != null) {
    return 'High: ${e.tempHigh!.toStringAsFixed(0)}°  '
        'Low: ${e.tempLow!.toStringAsFixed(0)}°F';
  }
  if (e.temperature != null) {
    return 'Current: ${e.temperature!.toStringAsFixed(0)}°F';
  }
  return '—';
}

// ── Combined day model ────────────────────────────────────────────────────────

class _DayLog {
  final DateTime date;
  final JournalEntry? journal;
  final List<EventEntry> events;
  final String? checkInNote; // from SymptomEntry.notes (Today screen)

  _DayLog({
    required this.date,
    this.journal,
    required this.events,
    this.checkInNote,
  });

  String get dateKey => DateFormat('yyyy-MM-dd').format(date);

  EventEntry? get tempEvent =>
      events.where((e) => e.type == EventType.temperature).firstOrNull;

  List<EventEntry> get visibleEvents =>
      events.where((e) => e.type != EventType.temperature).toList();

  bool get hasContent =>
      (journal?.content.isNotEmpty ?? false) ||
      (checkInNote?.isNotEmpty ?? false) ||
      events.isNotEmpty;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<_DayLog> _days = [];
  bool _loading = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = DatabaseService.instance.onChange.listen((_) => _load());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final journals = await DatabaseService.instance.getAllJournals();
    final events = await DatabaseService.instance.getAllEvents();
    final symptoms = await DatabaseService.instance.getAllSymptoms();

    final map = <String, _DayLog>{};

    void merge(String k, {DateTime? date, JournalEntry? journal,
        EventEntry? event, String? checkInNote}) {
      final existing = map[k];
      map[k] = _DayLog(
        date: date ?? existing!.date,
        journal: journal ?? existing?.journal,
        events: event != null
            ? [...(existing?.events ?? []), event]
            : existing?.events ?? [],
        checkInNote: checkInNote ?? existing?.checkInNote,
      );
    }

    for (final j in journals) {
      merge(j.dateKey, date: j.date, journal: j);
    }
    for (final e in events) {
      merge(e.dateKey, date: map[e.dateKey]?.date ?? e.date, event: e);
    }
    for (final s in symptoms) {
      if (s.notes != null && s.notes!.isNotEmpty) {
        merge(s.dateKey, date: map[s.dateKey]?.date ?? s.date,
            checkInNote: s.notes);
      }
    }

    final days = map.values.where((d) => d.hasContent).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (mounted) setState(() { _days = days; _loading = false; });
  }

  void _openDay(_DayLog? day, DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _JournalPageScreen(
          date: date,
          journal: day?.journal,
          initialEvents: day?.events ?? [],
          checkInNote: day?.checkInNote,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _days.isEmpty
              ? _EmptyState(onAdd: () => _openDay(null, DateTime.now()))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                  itemCount: _days.length,
                  itemBuilder: (_, i) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DiaryEntry(
                        day: _days[i],
                        font: settings.journalFont,
                        onTap: () => _openDay(_days[i], _days[i].date),
                      ),
                      if (i < _days.length - 1)
                        _DiaryDivider(),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'journal_fab',
        onPressed: () {
          final todayKey =
              DateFormat('yyyy-MM-dd').format(DateTime.now());
          final todayLog =
              _days.where((d) => d.dateKey == todayKey).firstOrNull;
          _openDay(todayLog, DateTime.now());
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text("Today's entry"),
      ),
    );
  }
}

// ── Diary entry (list row — NO cards, flat typography) ────────────────────────

class _DiaryEntry extends StatelessWidget {
  final _DayLog day;
  final String font;
  final VoidCallback onTap;

  const _DiaryEntry({
    required this.day,
    required this.font,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    final isToday = day.dateKey ==
        DateFormat('yyyy-MM-dd').format(now);

    final preview = day.journal?.content ?? '';
    final previewText =
        preview.length > 200 ? '${preview.substring(0, 200)}…' : preview;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date header ─────────────────────────────────────────────
            Text(
              DateFormat('EEEE').format(day.date),
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: font,
                  fontFamilyFallback: const ['.SF Pro Text'],
                color: cs.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              DateFormat('MMMM d, yyyy').format(day.date),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.5),
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 12),

            // ── Temperature ─────────────────────────────────────────────
            if (day.tempEvent != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.thermostat_outlined,
                        size: 14,
                        color: cs.onSurface.withOpacity(0.45)),
                    const SizedBox(width: 5),
                    Text(
                      _tempLabel(day.tempEvent!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Events ─────────────────────────────────────────────────
            if (day.visibleEvents.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: day.visibleEvents
                    .map((e) => _InlineEventTag(event: e))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            // ── Check-in note (from Today screen) ───────────────────────
            if (day.checkInNote != null && day.checkInNote!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.today_outlined,
                      size: 13,
                      color: cs.onSurface.withOpacity(0.3)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      day.checkInNote!.length > 160
                          ? '${day.checkInNote!.substring(0, 160)}…'
                          : day.checkInNote!,
                      style: TextStyle(
                        fontFamily: font,
                  fontFamilyFallback: const ['.SF Pro Text'],
                        fontSize: 14,
                        height: 1.55,
                        color: cs.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              if (previewText.isNotEmpty) const SizedBox(height: 6),
            ],

            // ── Journal note preview ─────────────────────────────────────
            if (previewText.isNotEmpty)
              Text(
                previewText,
                style: TextStyle(
                  fontFamily: font,
                  fontFamilyFallback: const ['.SF Pro Text'],
                  fontSize: 15,
                  height: 1.65,
                  color: cs.onSurface.withOpacity(0.75),
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (day.checkInNote == null || day.checkInNote!.isEmpty)
              Text(
                isToday
                    ? 'Tap to write today\'s entry…'
                    : 'No note for this day.',
                style: TextStyle(
                  fontFamily: font,
                  fontFamilyFallback: const ['.SF Pro Text'],
                  fontSize: 14,
                  color: cs.onSurface.withOpacity(0.3),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineEventTag extends StatelessWidget {
  final EventEntry event;
  const _InlineEventTag({required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(event.type.icon, size: 13, color: event.type.color),
        const SizedBox(width: 4),
        Text(
          event.name,
          style: TextStyle(
            fontSize: 12,
            color: event.type.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Ornament divider between days ─────────────────────────────────────────────

class _DiaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: cs.outlineVariant.withOpacity(0.4),
                  thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '✦',
              style: TextStyle(
                  color: cs.primary.withOpacity(0.35), fontSize: 11),
            ),
          ),
          Expanded(
              child: Divider(
                  color: cs.outlineVariant.withOpacity(0.4),
                  thickness: 1)),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 64, color: cs.primary.withOpacity(0.3)),
            const SizedBox(height: 20),
            Text(
              'Your journal is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              'A private diary of how you feel, what happened, and what mattered.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.35)),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onAdd,
              child: const Text("Write today's entry"),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Journal page (edit screen) ────────────────────────────────────────────────

class _JournalPageScreen extends StatefulWidget {
  final DateTime date;
  final JournalEntry? journal;
  final List<EventEntry> initialEvents;
  final String? checkInNote;

  const _JournalPageScreen({
    required this.date,
    this.journal,
    required this.initialEvents,
    this.checkInNote,
  });

  @override
  State<_JournalPageScreen> createState() => _JournalPageScreenState();
}

class _JournalPageScreenState extends State<_JournalPageScreen> {
  late TextEditingController _noteCtrl;
  late DateTime _date;
  late List<EventEntry> _events;
  int? _journalId;

  // Add-event state
  bool _addingEvent = false;
  EventType _newEventType = EventType.newMed;
  final _newEventNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = widget.date;
    _events = List.from(widget.initialEvents);
    _journalId = widget.journal?.id;
    _noteCtrl = TextEditingController(text: widget.journal?.content ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _newEventNameCtrl.dispose();
    super.dispose();
  }

  // Auto-save the note (called on pop and on explicit save)
  Future<void> _saveNote() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty && _journalId == null) return;
    final entry = JournalEntry(id: _journalId, date: _date, content: text);
    await DatabaseService.instance.upsertJournal(entry);
    // Update the id so subsequent saves are updates, not inserts
    if (_journalId == null) {
      final saved = await DatabaseService.instance.getJournalByDate(_date);
      if (mounted) setState(() => _journalId = saved?.id);
    }
  }

  Future<void> _addEvent() async {
    final name = _newEventNameCtrl.text.trim().isNotEmpty
        ? _newEventNameCtrl.text.trim()
        : _newEventType.label;
    final entry =
        EventEntry(date: _date, type: _newEventType, name: name);
    await DatabaseService.instance.insertEvent(entry);
    // Reload events for this date
    final all = await DatabaseService.instance.getAllEvents();
    final dateKey = DateFormat('yyyy-MM-dd').format(_date);
    if (mounted) {
      setState(() {
        _events = all.where((e) => e.dateKey == dateKey).toList();
        _addingEvent = false;
      });
      _newEventNameCtrl.clear();
    }
  }

  Future<void> _deleteEvent(EventEntry e) async {
    if (e.id == null) return;
    await DatabaseService.instance.deleteEvent(e.id!);
    setState(() => _events.removeWhere((x) => x.id == e.id));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final font = settings.journalFont;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final tempEvent =
        _events.where((e) => e.type == EventType.temperature).firstOrNull;
    final visibleEvents =
        _events.where((e) => e.type != EventType.temperature).toList();

    final now = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(_date) ==
        DateFormat('yyyy-MM-dd').format(now);

    return PopScope(
      canPop: true,
      onPopInvoked: (_) => _saveNote(), // auto-save on back
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: Text(
              isToday ? 'Today' : DateFormat('MMM d').format(_date),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await _saveNote();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saved'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
            children: [

              // ── Date heading ───────────────────────────────────────────
              Text(
                DateFormat('EEEE').format(_date),
                style: TextStyle(
                  fontFamily: font,
                  fontFamilyFallback: const ['.SF Pro Text'],
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                  height: 1.1,
                ),
              ),
              Text(
                DateFormat('MMMM d, yyyy').format(_date),
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurface.withOpacity(0.45),
                    letterSpacing: 0.3),
              ),
              // Date picker link
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && mounted) {
                    await _saveNote(); // save before switching date
                    final dateKey =
                        DateFormat('yyyy-MM-dd').format(picked);
                    final j = await DatabaseService.instance
                        .getJournalByDate(picked);
                    final all = await DatabaseService.instance
                        .getAllEvents();
                    setState(() {
                      _date = picked;
                      _events = all
                          .where((e) => e.dateKey == dateKey)
                          .toList();
                      _journalId = j?.id;
                      _noteCtrl.text = j?.content ?? '';
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Change date',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary.withOpacity(0.5),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Temperature ────────────────────────────────────────────
              if (tempEvent != null) ...[
                _PageRow(
                  icon: Icons.thermostat_outlined,
                  iconColor: Colors.deepOrangeAccent,
                  child: Text(
                    _tempLabel(tempEvent),
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.6)),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // ── Events ─────────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'EVENTS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.35),
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  if (!_addingEvent)
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _addingEvent = true),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding:
                              EdgeInsets.zero),
                    ),
                ],
              ),

              if (visibleEvents.isEmpty && !_addingEvent)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'No events — tap Add to log one.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.3),
                        fontStyle: FontStyle.italic),
                  ),
                ),

              ...visibleEvents.map(
                (e) => Dismissible(
                  key: ValueKey(e.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteEvent(e),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.delete_outline,
                        size: 18,
                        color: cs.error.withOpacity(0.6)),
                  ),
                  child: _PageRow(
                    icon: e.type.icon,
                    iconColor: e.type.color,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500)),
                        Text(e.type.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    cs.onSurface.withOpacity(0.4))),
                      ],
                    ),
                  ),
                ),
              ),

              // Inline add-event form
              if (_addingEvent) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<EventType>(
                        value: _newEventType,
                        decoration: const InputDecoration(
                            labelText: 'Event type', isDense: true),
                        items: EventType.values
                            .where((t) => t != EventType.temperature)
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Row(children: [
                                    Icon(t.icon,
                                        size: 14, color: t.color),
                                    const SizedBox(width: 8),
                                    Text(t.label,
                                        style: const TextStyle(
                                            fontSize: 14)),
                                  ]),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null)
                            setState(() => _newEventType = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newEventNameCtrl,
                        decoration: InputDecoration(
                          hintText:
                              _newEventType == EventType.newMed ||
                                      _newEventType ==
                                          EventType.stoppedMed
                                  ? 'Medication name (optional)…'
                                  : 'Brief description (optional)…',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() {
                              _addingEvent = false;
                              _newEventNameCtrl.clear();
                            }),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _addEvent,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Divider rule ────────────────────────────────────────────
              Row(children: [
                Expanded(
                    child: Divider(
                        color: cs.outlineVariant.withOpacity(0.5))),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('✦',
                      style: TextStyle(
                          color: cs.primary.withOpacity(0.3),
                          fontSize: 10)),
                ),
                Expanded(
                    child: Divider(
                        color: cs.outlineVariant.withOpacity(0.5))),
              ]),

              const SizedBox(height: 16),

              // ── Check-in note (read-only, from Today screen) ────────────
              if (widget.checkInNote != null &&
                  widget.checkInNote!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.today_outlined,
                        size: 13,
                        color: cs.onSurface.withOpacity(0.35)),
                    const SizedBox(width: 6),
                    Text(
                      'FROM TODAY\'S CHECK-IN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.35),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.4)),
                  ),
                  child: Text(
                    widget.checkInNote!,
                    style: TextStyle(
                      fontFamily: font,
                  fontFamilyFallback: const ['.SF Pro Text'],
                      fontSize: 15,
                      height: 1.65,
                      color: cs.onSurface.withOpacity(0.65),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Notes label ─────────────────────────────────────────────
              Text(
                'NOTES',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.35),
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // ── Journal note field ──────────────────────────────────────
              TextField(
                controller: _noteCtrl,
                maxLines: null,
                minLines: 8,
                autofocus: false,
                style: TextStyle(
                  fontFamily: font,
                  fontFamilyFallback: const ['.SF Pro Text'],
                  fontSize: 16,
                  height: 1.8,
                  color: cs.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Write freely…',
                  hintStyle: TextStyle(
                    fontFamily: font,
                  fontFamilyFallback: const ['.SF Pro Text'],
                    color: cs.onSurface.withOpacity(0.25),
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared row widget for journal page items ──────────────────────────────────

class _PageRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _PageRow(
      {required this.icon, required this.iconColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
