import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/symptom_entry.dart';
import '../models/weight_entry.dart';
import '../models/event_entry.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';
import '../widgets/tardis_painter.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime _selectedDate = DateTime.now();
  SymptomEntry _entry = SymptomEntry(date: DateTime.now());
  final _notesCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _eventNameCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  bool _loggedWeight = false;
  String _weightUnit = 'lbs';
  bool _logEvent = false;
  EventType _eventType = EventType.stress;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _weightCtrl.dispose();
    _eventNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    setState(() => _loading = true);
    final settings = context.read<SettingsProvider>();
    final existing =
        await DatabaseService.instance.getSymptomByDate(_selectedDate);
    setState(() {
      _entry = existing ?? SymptomEntry(date: _selectedDate);
      _notesCtrl.text = _entry.notes ?? '';
      _saved = existing != null;
      _weightUnit = settings.weightUnit;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return; // prevent double-tap
    setState(() => _saving = true);

    try {
      final settings = context.read<SettingsProvider>();

      // Save symptoms (upsert — safe to call repeatedly)
      final toSave = _entry.copyWith(
        date: _selectedDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await DatabaseService.instance.upsertSymptom(toSave);

      // Save weight — only if the flag is still set (reset after first save)
      if (_loggedWeight && _weightCtrl.text.isNotEmpty) {
        final w = double.tryParse(_weightCtrl.text);
        if (w != null && w > 0) {
          await DatabaseService.instance.insertWeight(WeightEntry(
            date: _selectedDate,
            weight: w,
            unit: _weightUnit,
          ));
        }
      }

      // Save event — fall back to type label if user left name blank
      if (_logEvent) {
        final eventName = _eventNameCtrl.text.trim().isNotEmpty
            ? _eventNameCtrl.text.trim()
            : _eventType.label;
        await DatabaseService.instance.insertEvent(EventEntry(
          date: _selectedDate,
          type: _eventType,
          name: eventName,
        ));
      }

      // Auto-log temperature (high/low for the day + current).
      // Delete any existing temp event for this date first so we never
      // accumulate stale single-temp entries alongside the new high/low one.
      if (settings.zipcode.isNotEmpty) {
        await DatabaseService.instance
            .deleteTemperatureEventsForDate(_selectedDate);
        final weather =
            await WeatherService.instance.fetchWeather(settings.zipcode);
        if (weather != null) {
          await DatabaseService.instance.insertEvent(EventEntry(
            date: _selectedDate,
            type: EventType.temperature,
            name: 'Auto-logged temperature',
            temperature: weather.current,
            tempHigh: weather.high,
            tempLow: weather.low,
            zipcode: settings.zipcode,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _saved = true;
          _saving = false;
          // Reset one-time flags so a second tap doesn't re-insert
          _loggedWeight = false;
          _logEvent = false;
        });
        _weightCtrl.clear();
        _eventNameCtrl.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All saved — take good care of yourself today ✨'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _changeDate(int delta) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: delta)));
    _loadEntry();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: const Text('Daily Check-In'),
          actions: [
            if (_saved)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Chip(
                  avatar: Icon(Icons.check_circle, color: cs.primary, size: 16),
                  label: const Text('Saved'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'About',
              onPressed: () => Navigator.of(context).pushNamed('/about'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: _DateNavigator(
              date: _selectedDate,
              isToday: _isToday,
              onPrev: () => _changeDate(-1),
              onNext: _isToday ? null : () => _changeDate(1),
              onPick: () async {
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
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  // ── Greeting header ───────────────────────────────────────
                  if (_isToday) _buildGreeting(theme, cs),

                  // ── Q1: Overall feeling ───────────────────────────────────
                  _QuestionCard(
                    question: 'How are you feeling today?',
                    subtitle: 'Take a breath and check in with yourself.',
                    icon: Icons.favorite_outline,
                    child: _OverallFeelPicker(
                      value: _entry.totalSeverity,
                    ),
                  ),

                  // ── Q2: Hot flashes ───────────────────────────────────────
                  _QuestionCard(
                    question: 'Any hot flashes?',
                    subtitle: '0 = none at all  •  5 = intense',
                    icon: Icons.local_fire_department_outlined,
                    child: _CalmSlider(
                      value: _entry.hotFlashes,
                      onChanged: (v) => setState(
                          () => _entry = _entry.copyWith(hotFlashes: v)),
                    ),
                  ),

                  // ── Q3: Sleep ─────────────────────────────────────────────
                  _QuestionCard(
                    question: 'Did you sleep well last night?',
                    subtitle: '0 = slept beautifully  •  5 = barely slept',
                    icon: Icons.bedtime_outlined,
                    child: _CalmSlider(
                      value: _entry.sleeplessness,
                      onChanged: (v) => setState(
                          () => _entry = _entry.copyWith(sleeplessness: v)),
                    ),
                  ),

                  // ── Q4: Energy ────────────────────────────────────────────
                  _QuestionCard(
                    question: 'How\'s your energy?',
                    subtitle: '0 = feeling great  •  5 = completely drained',
                    icon: Icons.battery_charging_full_outlined,
                    child: _CalmSlider(
                      value: _entry.exhaustion,
                      onChanged: (v) => setState(
                          () => _entry = _entry.copyWith(exhaustion: v)),
                    ),
                  ),

                  // ── Q5: Nausea & Bloating ─────────────────────────────────
                  _QuestionCard(
                    question: 'Any nausea or bloating?',
                    subtitle: 'Rate each from 0 (none) to 5 (significant)',
                    icon: Icons.sick_outlined,
                    child: Column(
                      children: [
                        _LabeledSlider(
                          label: 'Nausea',
                          value: _entry.nausea,
                          onChanged: (v) => setState(
                              () => _entry = _entry.copyWith(nausea: v)),
                        ),
                        const SizedBox(height: 8),
                        _LabeledSlider(
                          label: 'Bloating',
                          value: _entry.bloat,
                          onChanged: (v) => setState(
                              () => _entry = _entry.copyWith(bloat: v)),
                        ),
                      ],
                    ),
                  ),

                  // ── Q6: Cycle ─────────────────────────────────────────────
                  _QuestionCard(
                    question: 'Cycle today?',
                    subtitle: 'Mark if your period started or continued.',
                    icon: Icons.circle_outlined,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ChoiceChip(
                            label: 'Yes',
                            selected: _entry.cycle,
                            color: const Color(0xFFE91E63),
                            onTap: () => setState(
                                () => _entry = _entry.copyWith(cycle: true)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ChoiceChip(
                            label: 'No',
                            selected: !_entry.cycle,
                            color: cs.primary,
                            onTap: () => setState(
                                () => _entry = _entry.copyWith(cycle: false)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Q7: Appetite ──────────────────────────────────────────
                  _QuestionCard(
                    question: 'How\'s your appetite?',
                    subtitle: 'Compared to your usual.',
                    icon: Icons.restaurant_outlined,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ChoiceChip(
                            label: '↓ Less',
                            selected: _entry.appetite == -1,
                            color: const Color(0xFF5B8FA8),
                            onTap: () => setState(
                                () => _entry = _entry.copyWith(appetite: -1)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ChoiceChip(
                            label: 'Normal',
                            selected: _entry.appetite == 0,
                            color: cs.primary,
                            onTap: () => setState(
                                () => _entry = _entry.copyWith(appetite: 0)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ChoiceChip(
                            label: '↑ More',
                            selected: _entry.appetite == 1,
                            color: const Color(0xFF7BA68B),
                            onTap: () => setState(
                                () => _entry = _entry.copyWith(appetite: 1)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Q8: Weight ────────────────────────────────────────────
                  _QuestionCard(
                    question: 'Did you weigh in today?',
                    subtitle: 'Only log it if you checked — no pressure.',
                    icon: Icons.monitor_weight_outlined,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ChoiceChip(
                                label: 'Yes',
                                selected: _loggedWeight,
                                color: cs.primary,
                                onTap: () =>
                                    setState(() => _loggedWeight = true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ChoiceChip(
                                label: 'Not today',
                                selected: !_loggedWeight,
                                color: cs.secondary,
                                onTap: () =>
                                    setState(() => _loggedWeight = false),
                              ),
                            ),
                          ],
                        ),
                        if (_loggedWeight) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _weightCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d.]')),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Enter weight',
                                    suffixText: _weightUnit,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SegmentedButton<String>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                      value: 'lbs', label: Text('lbs')),
                                  ButtonSegment(
                                      value: 'kg', label: Text('kg')),
                                ],
                                selected: {_weightUnit},
                                onSelectionChanged: (v) =>
                                    setState(() => _weightUnit = v.first),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Q9: Events ────────────────────────────────────────────
                  _QuestionCard(
                    question: 'Anything interesting happen recently?',
                    subtitle:
                        'A new medication, something stressful, or something worth noting.',
                    icon: Icons.event_note_outlined,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ChoiceChip(
                                label: 'Yes, log it',
                                selected: _logEvent,
                                color: cs.primary,
                                onTap: () =>
                                    setState(() => _logEvent = true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ChoiceChip(
                                label: 'Nothing today',
                                selected: !_logEvent,
                                color: cs.secondary,
                                onTap: () =>
                                    setState(() => _logEvent = false),
                              ),
                            ),
                          ],
                        ),
                        if (_logEvent) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<EventType>(
                            value: _eventType,
                            decoration: const InputDecoration(
                              labelText: 'What kind of event?',
                            ),
                            items: EventType.values
                                .where((t) =>
                                    t != EventType.temperature &&
                                    t != EventType.other)
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Row(
                                        children: [
                                          Icon(t.icon,
                                              size: 16, color: t.color),
                                          const SizedBox(width: 8),
                                          Text(t.label),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null)
                                setState(() => _eventType = v);
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _eventNameCtrl,
                            decoration: InputDecoration(
                              hintText: _eventType == EventType.newMed ||
                                      _eventType == EventType.stoppedMed
                                  ? 'Medication name…'
                                  : 'Describe it briefly…',
                              prefixIcon:
                                  Icon(_eventType.icon, color: _eventType.color),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Notes ─────────────────────────────────────────────────
                  _QuestionCard(
                    question: 'Anything else on your mind?',
                    subtitle: 'A private note, just for you.',
                    icon: Icons.notes_outlined,
                    child: TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Write freely…',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'today_fab',
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_rounded),
          label: Text(_saving ? 'Saving…' : 'Save my check-in'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildGreeting(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const TardisWidget(size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting 🌸',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMMM d').format(_selectedDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.55)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date navigator ────────────────────────────────────────────────────────────

class _DateNavigator extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  const _DateNavigator({
    required this.date,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          GestureDetector(
            onTap: onPick,
            child: Text(
              isToday
                  ? 'Today'
                  : DateFormat('EEE, MMM d').format(date),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isToday ? cs.primary : cs.onSurface,
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

// ── Question card wrapper ─────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final String question;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _QuestionCard({
    required this.question,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 2, bottom: 12),
              child: Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5)),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Overall feel picker (emoji scale) ────────────────────────────────────────

class _OverallFeelPicker extends StatelessWidget {
  final double value; // computed from symptom totals

  const _OverallFeelPicker({required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Display only — reflects total symptom burden
    final emojis = ['🌟', '😊', '😐', '😔', '😣', '😰'];
    final labels = [
      'Wonderful', 'Pretty good', 'Okay', 'A bit rough', 'Hard day', 'Very difficult'
    ];
    final subtitles = [
      'Symptoms are low — savour it.',
      'Feeling pretty good today.',
      'Hanging in there — that counts.',
      'It\'s a tough one. Be gentle with yourself.',
      'A hard day. Rest when you can.',
      'Really struggling today. You\'re not alone.',
    ];
    final idx = (value / 5).clamp(0, 5).round();
    return Row(
      children: [
        Text(emojis[idx],
            style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(labels[idx],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.bold)),
              Text(
                subtitles[idx],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Calm severity slider ──────────────────────────────────────────────────────

class _CalmSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _CalmSlider({required this.value, required this.onChanged});

  Color _color(BuildContext context) {
    switch (value) {
      case 0:
        return const Color(0xFF4CAF50);
      case 1:
        return const Color(0xFF8BC34A);
      case 2:
        return const Color(0xFFCDDC39);
      case 3:
        return const Color(0xFFFFEB3B);
      case 4:
        return const Color(0xFFFF9800);
      case 5:
        return const Color(0xFFE53935);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  static const _labels = ['None', 'Mild', 'Moderate', 'Noticeable', 'Severe', 'Extreme'];

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: cs.surfaceContainerHighest,
            overlayColor: color.withOpacity(0.15),
            trackHeight: 5,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 5,
            divisions: 5,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return Text(
              '$i',
              style: TextStyle(
                fontSize: 11,
                fontWeight: i == value ? FontWeight.bold : FontWeight.normal,
                color: i == value ? color : cs.onSurface.withOpacity(0.35),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            _labels[value],
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ── Labeled slider (for nausea/bloat pair) ───────────────────────────────────

class _LabeledSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _LabeledSlider(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurface.withOpacity(0.7))),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: cs.primary,
              thumbColor: cs.primary,
              inactiveTrackColor: cs.surfaceContainerHighest,
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        SizedBox(
          width: 20,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: cs.primary),
          ),
        ),
      ],
    );
  }
}

// ── Choice chip ───────────────────────────────────────────────────────────────

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.25),
            width: selected ? 0 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
