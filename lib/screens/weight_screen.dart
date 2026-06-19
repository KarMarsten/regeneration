import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weight_entry.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../widgets/weight_chart_widget.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  List<WeightEntry> _entries = [];
  bool _loading = true;
  int _rangeDays = 90; // 30, 90, 180, 0=all
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
    final all = await DatabaseService.instance.getAllWeights();
    setState(() {
      _entries = all;
      _loading = false;
    });
  }

  List<WeightEntry> get _filteredEntries {
    if (_rangeDays == 0) return _entries;
    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
    return _entries.where((e) => e.date.isAfter(cutoff)).toList();
  }

  Future<void> _showAddDialog({WeightEntry? existing}) async {
    final settings = context.read<SettingsProvider>();
    final weightCtrl = TextEditingController(
        text: existing != null
            ? existing.inUnit(settings.weightUnit).toStringAsFixed(1)
            : '');
    final notesCtrl =
        TextEditingController(text: existing?.notes ?? '');
    DateTime selectedDate = existing?.date ?? DateTime.now();
    String unit = existing?.unit ?? settings.weightUnit;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Log Weight' : 'Edit Weight',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // Date picker row
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Weight ($unit)',
                        prefixIcon: const Icon(Icons.monitor_weight_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'lbs', label: Text('lbs')),
                      ButtonSegment(value: 'kg', label: Text('kg')),
                    ],
                    selected: {unit},
                    onSelectionChanged: (val) =>
                        setModal(() => unit = val.first),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
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
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      label: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        await DatabaseService.instance
                            .deleteWeight(existing.id!);
                        if (mounted) Navigator.pop(ctx);
                        _load();
                      },
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      final w = double.tryParse(weightCtrl.text);
                      if (w == null || w <= 0) return;
                      final entry = WeightEntry(
                        id: existing?.id,
                        date: selectedDate,
                        weight: w,
                        unit: unit,
                        notes: notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                      );
                      if (existing == null) {
                        await DatabaseService.instance.insertWeight(entry);
                      } else {
                        await DatabaseService.instance.updateWeight(entry);
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final unit = settings.weightUnit;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filtered = _filteredEntries;

    // Stats
    double? startW, endW, minW, maxW, avgW;
    if (filtered.isNotEmpty) {
      final sorted = List<WeightEntry>.from(filtered)
        ..sort((a, b) => a.date.compareTo(b.date));
      final vals = sorted.map((e) => e.inUnit(unit)).toList();
      startW = vals.first;
      endW = vals.last;
      minW = vals.reduce((a, b) => a < b ? a : b);
      maxW = vals.reduce((a, b) => a > b ? a : b);
      avgW = vals.reduce((a, b) => a + b) / vals.length;
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Weight Log'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range_outlined),
            onSelected: (v) => setState(() => _rangeDays = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
              const PopupMenuItem(value: 180, child: Text('Last 6 months')),
              const PopupMenuItem(value: 0, child: Text('All time')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monitor_weight_outlined,
                          size: 64,
                          color: cs.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No weight entries yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.4)),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add first entry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    // Chart
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: WeightChartWidget(
                              entries: filtered, unit: unit),
                        ),
                      ),
                    ),

                    // Stats row
                    if (startW != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            _statChip(context, 'Start',
                                '${startW.toStringAsFixed(1)} $unit'),
                            const SizedBox(width: 6),
                            _statChip(context, 'Now',
                                '${endW!.toStringAsFixed(1)} $unit'),
                            const SizedBox(width: 6),
                            _statChip(
                              context,
                              'Change',
                              '${(endW - startW) >= 0 ? '+' : ''}${(endW - startW).toStringAsFixed(1)} $unit',
                              color: (endW - startW) <= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            _statChip(context, 'Avg',
                                '${avgW!.toStringAsFixed(1)} $unit'),
                          ],
                        ),
                      ),

                    // List header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Entries (${filtered.length})',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.6)),
                      ),
                    ),

                    // Entries list
                    ...filtered.reversed.map((entry) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                cs.primaryContainer,
                            child: Icon(Icons.monitor_weight_outlined,
                                color: cs.primary, size: 20),
                          ),
                          title: Text(
                            '${entry.inUnit(unit).toStringAsFixed(1)} $unit',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            DateFormat('EEEE, MMM d, yyyy')
                                .format(entry.date) +
                                (entry.notes != null
                                    ? '  •  ${entry.notes}'
                                    : ''),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showAddDialog(existing: entry),
                        )),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'weight_fab',
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _statChip(BuildContext context, String label, String value,
      {Color? color}) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color ?? cs.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
