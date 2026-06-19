import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/symptom_entry.dart';
import '../models/weight_entry.dart';
import '../models/event_entry.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/report_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _startDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _generating = false;
  int _rangeDays = 30;

  void _setRange(int days) {
    setState(() {
      _rangeDays = days;
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days));
    });
  }

  Future<void> _generate() async {
    final settings = context.read<SettingsProvider>();
    setState(() => _generating = true);

    try {
      final symptoms = await DatabaseService.instance
          .getSymptomsBetween(_startDate, _endDate);
      final weights = await DatabaseService.instance
          .getWeightsBetween(_startDate, _endDate);
      final events = await DatabaseService.instance
          .getEventsBetween(_startDate, _endDate);

      final pdf = await ReportService.instance.generateReport(
        patientName: settings.patientName,
        startDate: _startDate,
        endDate: _endDate,
        symptoms: symptoms,
        weights: weights,
        events: events,
        weightUnit: settings.weightUnit,
      );

      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'Regeneration_Report_${DateFormat('yyyy-MM-dd').format(_startDate)}_to_${DateFormat('yyyy-MM-dd').format(_endDate)}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = DateFormat('MMM d, yyyy');
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Doctor Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Generate Health Report',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Creates a printable PDF with symptom trends, weight data, key events, and observations for your doctor.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date range quick select
          Text(
            'Date Range',
            style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in {
                30: 'Last 30 days',
                60: 'Last 60 days',
                90: 'Last 3 months',
                180: 'Last 6 months',
              }.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: _rangeDays == entry.key,
                  onSelected: (_) => _setRange(entry.key),
                ),
              FilterChip(
                label: const Text('Custom'),
                selected: false,
                onSelected: (_) async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange:
                        DateTimeRange(start: _startDate, end: _endDate),
                  );
                  if (range != null) {
                    setState(() {
                      _startDate = range.start;
                      _endDate = range.end;
                      _rangeDays = -1;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Selected range display
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.date_range_outlined,
                      color: cs.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${fmt.format(_startDate)} – ${fmt.format(_endDate)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer),
                      ),
                      Text(
                        '${_endDate.difference(_startDate).inDays + 1} days',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onPrimaryContainer.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Patient name
          Text(
            'Report Details',
            style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(settings.patientName.isEmpty
                        ? 'Set your name in Settings'
                        : settings.patientName),
                    subtitle: const Text('Patient name on report'),
                    dense: true,
                  ),
                  ListTile(
                    leading: const Icon(Icons.monitor_weight_outlined),
                    title: Text(
                        'Weight unit: ${settings.weightUnit.toUpperCase()}'),
                    subtitle: const Text('Change in Settings'),
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // What's included
          Text(
            'Report includes',
            style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _includedTile(context, Icons.monitor_weight_outlined,
                    'Weight Log', 'All entries with trend chart data'),
                _includedTile(context, Icons.sick_outlined,
                    'Symptom Summary',
                    'Avg severity per symptom with trend bars'),
                _includedTile(context, Icons.event_note_outlined,
                    'Key Events Timeline',
                    'Medications, stress, cycle dates, temperatures'),
                _includedTile(context, Icons.insights_outlined,
                    'Auto Observations',
                    'Trend analysis and clinical notes'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Generate button
          FilledButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.print_outlined),
            label: Text(_generating ? 'Generating…' : 'Generate & Print PDF'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The PDF opens in your system print dialog — you can print, save, or share it as a PDF file.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _includedTile(
      BuildContext context, IconData icon, String title, String sub) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary, size: 20),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(sub,
          style: TextStyle(
              fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
      dense: true,
    );
  }
}
