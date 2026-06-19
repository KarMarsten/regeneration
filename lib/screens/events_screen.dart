import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event_entry.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<EventEntry> _events = [];
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
    setState(() => _loading = true);
    final all = await DatabaseService.instance.getAllEvents();
    if (mounted) {
      setState(() {
        _events = all;
        _loading = false;
      });
    }
  }

  Future<void> _showAddDialog({EventEntry? existing}) async {
    final settings = context.read<SettingsProvider>();
    EventType selectedType = existing?.type ?? EventType.newMed;
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final notesCtrl =
        TextEditingController(text: existing?.notes ?? '');
    final tempCtrl = TextEditingController(
        text: existing?.temperature?.toStringAsFixed(1) ?? '');
    final zipCtrl = TextEditingController(
        text: existing?.zipcode ?? settings.zipcode);
    DateTime selectedDate = existing?.date ?? DateTime.now();
    bool fetchingTemp = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Log Event' : 'Edit Event',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setModal(() => selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                ),
              ),
              const SizedBox(height: 12),

              // Event type
              DropdownButtonFormField<EventType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: EventType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        Icon(t.icon, size: 18, color: t.color),
                        const SizedBox(width: 8),
                        Text(t.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setModal(() => selectedType = v);
                },
              ),
              const SizedBox(height: 12),

              // Name / description
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: _nameLabelFor(selectedType),
                  prefixIcon: Icon(selectedType.icon),
                ),
              ),
              const SizedBox(height: 12),

              // Temperature (shown for temperature type or optionally)
              if (selectedType == EventType.temperature) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tempCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Temperature (°F)',
                          prefixIcon: Icon(Icons.thermostat_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: zipCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Zip Code',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: fetchingTemp
                      ? null
                      : () async {
                          final zip = zipCtrl.text.trim();
                          if (zip.isEmpty) return;
                          setModal(() => fetchingTemp = true);
                          final temp = await WeatherService.instance
                              .fetchTemperature(zip);
                          setModal(() {
                            fetchingTemp = false;
                            if (temp != null) {
                              tempCtrl.text = temp.toStringAsFixed(1);
                            }
                          });
                        },
                  icon: fetchingTemp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_outlined),
                  label: const Text('Fetch Current Temp'),
                ),
                const SizedBox(height: 12),
              ],

              // Notes
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  if (existing != null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        await DatabaseService.instance
                            .deleteEvent(existing.id!);
                        if (mounted) Navigator.pop(ctx);
                        _load();
                      },
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final event = EventEntry(
                        id: existing?.id,
                        date: selectedDate,
                        type: selectedType,
                        name: name,
                        temperature: double.tryParse(tempCtrl.text),
                        zipcode: zipCtrl.text.trim().isEmpty
                            ? null
                            : zipCtrl.text.trim(),
                        notes: notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                      );
                      if (existing == null) {
                        await DatabaseService.instance.insertEvent(event);
                      } else {
                        await DatabaseService.instance.updateEvent(event);
                      }
                      if (mounted) Navigator.pop(ctx);
                      _load();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _nameLabelFor(EventType type) {
    switch (type) {
      case EventType.newMed:
      case EventType.stoppedMed:
        return 'Medication Name';
      case EventType.stress:
        return 'Describe the Stressor';
      case EventType.cycleStart:
        return 'Cycle Start Notes';
      case EventType.cycleEnd:
        return 'Cycle End Notes';
      case EventType.temperature:
        return 'Location / Notes';
      case EventType.other:
        return 'Description';
    }
  }

  // Group events by month for display
  Map<String, List<EventEntry>> get _grouped {
    final map = <String, List<EventEntry>>{};
    final sorted = List<EventEntry>.from(_events)
      ..sort((a, b) => b.date.compareTo(a.date));
    for (final e in sorted) {
      final key = DateFormat('MMMM yyyy').format(e.date);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final grouped = _grouped;
    final keys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Events')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_note_outlined,
                          size: 64,
                          color: cs.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text('No events yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: cs.onSurface.withOpacity(0.4))),
                      const SizedBox(height: 8),
                      Text(
                        'Log medications, stressful moments,\ncycle dates, and more.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.4)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: keys.length,
                  itemBuilder: (ctx, monthIdx) {
                    final monthKey = keys[monthIdx];
                    final monthEvents = grouped[monthKey]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            monthKey,
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5),
                          ),
                        ),
                        ...monthEvents.map((e) => _buildEventTile(e)),
                      ],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'events_fab',
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Log Event'),
      ),
    );
  }

  Widget _buildEventTile(EventEntry event) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d');
    String subtitle = DateFormat('EEEE, MMM d, yyyy').format(event.date);
    if (event.temperature != null) {
      subtitle += '  •  ${event.temperature!.toStringAsFixed(1)}°F';
      if (event.zipcode != null) subtitle += ' (${event.zipcode})';
    }
    if (event.notes != null) subtitle += '  •  ${event.notes}';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: event.type.color.withOpacity(0.15),
        child: Icon(event.type.icon, color: event.type.color, size: 20),
      ),
      title: Text(event.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            label: Text(event.type.label),
            labelStyle:
                TextStyle(fontSize: 11, color: event.type.color),
            backgroundColor: event.type.color.withOpacity(0.1),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            side: BorderSide(color: event.type.color.withOpacity(0.3)),
          ),
          Text(subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6))),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showAddDialog(existing: event),
    );
  }
}
