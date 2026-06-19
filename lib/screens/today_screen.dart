import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/symptom_entry.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';
import '../models/event_entry.dart';
import '../widgets/severity_slider.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime _selectedDate = DateTime.now();
  SymptomEntry _entry = SymptomEntry(date: DateTime.now());
  final _notesController = TextEditingController();
  bool _loading = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    setState(() => _loading = true);
    final existing =
        await DatabaseService.instance.getSymptomByDate(_selectedDate);
    setState(() {
      _entry = existing ??
          SymptomEntry(
            date: _selectedDate,
            hotFlashes: 0,
            nausea: 0,
            sleeplessness: 0,
            exhaustion: 0,
            bloat: 0,
          );
      _notesController.text = _entry.notes ?? '';
      _saved = existing != null;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final toSave = _entry.copyWith(
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await DatabaseService.instance.upsertSymptom(toSave);

    // Auto-log temperature if zipcode is set
    final settings = context.read<SettingsProvider>();
    if (settings.zipcode.isNotEmpty) {
      final temp =
          await WeatherService.instance.fetchTemperature(settings.zipcode);
      if (temp != null && mounted) {
        final event = EventEntry(
          date: _selectedDate,
          type: EventType.temperature,
          name: 'Auto-logged temperature',
          temperature: temp,
          zipcode: settings.zipcode,
        );
        await DatabaseService.instance.insertEvent(event);
      }
    }

    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved for today ✓'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _changeDate(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
    _loadEntry();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = DateFormat('EEEE, MMM d');

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Daily Tracker'),
        actions: [
          if (_saved)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: Icon(Icons.check_circle, color: cs.primary, size: 16),
                label: const Text('Saved'),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Date navigator ──────────────────────────────────────────
                Container(
                  color: cs.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeDate(-1),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _loadEntry();
                          }
                        },
                        child: Column(
                          children: [
                            Text(
                              fmt.format(_selectedDate),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isToday)
                              Text(
                                'Today',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: cs.primary),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed:
                            _isToday ? null : () => _changeDate(1),
                      ),
                    ],
                  ),
                ),

                // ── Symptom sliders ─────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    children: [
                      SeveritySlider(
                        label: 'Hot Flashes',
                        icon: Icons.local_fire_department_outlined,
                        value: _entry.hotFlashes,
                        onChanged: (v) =>
                            setState(() => _entry = _entry.copyWith(hotFlashes: v)),
                      ),
                      SeveritySlider(
                        label: 'Nausea',
                        icon: Icons.sick_outlined,
                        value: _entry.nausea,
                        onChanged: (v) =>
                            setState(() => _entry = _entry.copyWith(nausea: v)),
                      ),
                      SeveritySlider(
                        label: 'Sleeplessness',
                        icon: Icons.bedtime_outlined,
                        value: _entry.sleeplessness,
                        onChanged: (v) => setState(
                            () => _entry = _entry.copyWith(sleeplessness: v)),
                      ),
                      SeveritySlider(
                        label: 'Exhaustion',
                        icon: Icons.battery_1_bar_outlined,
                        value: _entry.exhaustion,
                        onChanged: (v) =>
                            setState(() => _entry = _entry.copyWith(exhaustion: v)),
                      ),
                      SeveritySlider(
                        label: 'Bloating',
                        icon: Icons.bubble_chart_outlined,
                        value: _entry.bloat,
                        onChanged: (v) =>
                            setState(() => _entry = _entry.copyWith(bloat: v)),
                      ),

                      // ── Cycle toggle ───────────────────────────────────────
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: SwitchListTile(
                          secondary: Icon(Icons.circle_outlined,
                              color: _entry.cycle
                                  ? const Color(0xFFE91E63)
                                  : cs.onSurface.withOpacity(0.4)),
                          title: const Text('Cycle / Period'),
                          subtitle: Text(
                            _entry.cycle ? 'Yes — marked for today' : 'No',
                            style: theme.textTheme.bodySmall,
                          ),
                          value: _entry.cycle,
                          activeColor: const Color(0xFFE91E63),
                          onChanged: (v) =>
                              setState(() => _entry = _entry.copyWith(cycle: v)),
                        ),
                      ),

                      // ── Appetite ───────────────────────────────────────────
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.restaurant_outlined,
                                      size: 20, color: cs.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Appetite',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SegmentedButton<int>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: -1,
                                    label: Text('Decreased'),
                                    icon: Icon(Icons.trending_down),
                                  ),
                                  ButtonSegment(
                                    value: 0,
                                    label: Text('Normal'),
                                    icon: Icon(Icons.remove),
                                  ),
                                  ButtonSegment(
                                    value: 1,
                                    label: Text('Increased'),
                                    icon: Icon(Icons.trending_up),
                                  ),
                                ],
                                selected: {_entry.appetite},
                                onSelectionChanged: (val) => setState(
                                    () => _entry = _entry.copyWith(
                                        appetite: val.first)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Notes ──────────────────────────────────────────────
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Any additional notes for today…',
                              prefixIcon: Icon(Icons.note_outlined),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save Entry'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
