import 'dart:math';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/symptom_entry.dart';
import '../models/weight_entry.dart';
import '../models/event_entry.dart';

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  static const _tardisBlue = PdfColor.fromInt(0xFF003b6f);
  static const _lavender = PdfColor.fromInt(0xFFBB8FCE);
  static const _lightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const _darkText = PdfColor.fromInt(0xFF1A1A2E);
  static const _mutedText = PdfColor.fromInt(0xFF666688);
  static const _accentGreen = PdfColor.fromInt(0xFF4CAF50);
  static const _accentRed = PdfColor.fromInt(0xFFE57373);
  static const _accentOrange = PdfColor.fromInt(0xFFFF9800);

  Future<pw.Document> generateReport({
    required String patientName,
    required DateTime startDate,
    required DateTime endDate,
    required List<SymptomEntry> symptoms,
    required List<WeightEntry> weights,
    required List<EventEntry> events,
    required String weightUnit,
  }) async {
    final pdf = pw.Document(
      title: 'Regeneration Health Report',
      author: 'Regeneration App',
    );

    final observations = _generateObservations(
      symptoms: symptoms,
      weights: weights,
      events: events,
      weightUnit: weightUnit,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader(patientName, startDate, endDate, ctx),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          _weightSection(weights, weightUnit),
          pw.SizedBox(height: 20),
          _symptomSection(symptoms, startDate, endDate),
          pw.SizedBox(height: 20),
          _eventsSection(events),
          pw.SizedBox(height: 20),
          _observationsSection(observations),
        ],
      ),
    );

    return pdf;
  }

  // ── Header & Footer ────────────────────────────────────────────────────────

  pw.Widget _buildHeader(String name, DateTime start, DateTime end,
      pw.Context ctx) {
    final fmt = DateFormat('MMM d, yyyy');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'REGENERATION',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _tardisBlue,
                  ),
                ),
                pw.Text(
                  'Health Report',
                  style: pw.TextStyle(fontSize: 12, color: _lavender),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (name.isNotEmpty)
                  pw.Text(
                    name,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                pw.Text(
                  '${fmt.format(start)} – ${fmt.format(end)}',
                  style: pw.TextStyle(fontSize: 10, color: _mutedText),
                ),
                pw.Text(
                  'Generated ${fmt.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 9, color: _mutedText),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(color: _tardisBlue, thickness: 2),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Divider(color: _mutedText, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Regeneration App — Confidential Health Record',
                style: pw.TextStyle(fontSize: 8, color: _mutedText)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: _mutedText)),
          ],
        ),
      ],
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────

  pw.Widget _sectionHeader(String title) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _tardisBlue,
              letterSpacing: 1.5,
            ),
          ),
          pw.Divider(color: _lavender, thickness: 1),
          pw.SizedBox(height: 6),
        ],
      );

  // ── Weight Section ─────────────────────────────────────────────────────────

  pw.Widget _weightSection(List<WeightEntry> weights, String unit) {
    if (weights.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionHeader('Weight Log'),
          pw.Text('No weight entries recorded in this period.',
              style: pw.TextStyle(color: _mutedText, fontSize: 10)),
        ],
      );
    }

    final converted = weights
        .map((w) => MapEntry(w, w.inUnit(unit)))
        .toList();
    final vals = converted.map((e) => e.value).toList();
    final minW = vals.reduce(min);
    final maxW = vals.reduce(max);
    final avgW = vals.reduce((a, b) => a + b) / vals.length;
    final firstW = converted.first.value;
    final lastW = converted.last.value;
    final delta = lastW - firstW;
    final deltaStr =
        '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} $unit';

    final fmt = DateFormat('MMM d, yyyy');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('Weight Log'),
        pw.Row(
          children: [
            _statBox('Starting', '${firstW.toStringAsFixed(1)} $unit'),
            pw.SizedBox(width: 8),
            _statBox('Ending', '${lastW.toStringAsFixed(1)} $unit'),
            pw.SizedBox(width: 8),
            _statBox('Change', deltaStr,
                color: delta < 0 ? _accentGreen : _accentRed),
            pw.SizedBox(width: 8),
            _statBox('Min', '${minW.toStringAsFixed(1)} $unit'),
            pw.SizedBox(width: 8),
            _statBox('Max', '${maxW.toStringAsFixed(1)} $unit'),
            pw.SizedBox(width: 8),
            _statBox('Avg', '${avgW.toStringAsFixed(1)} $unit'),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: null,
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(4),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _tardisBlue),
              children: [
                _tableHeader('Date'),
                _tableHeader('Weight'),
                _tableHeader('Notes'),
              ],
            ),
            ...weights.asMap().entries.map((entry) {
              final i = entry.key;
              final w = entry.value;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                    color: i.isEven ? _lightGray : PdfColors.white),
                children: [
                  _tableCell(fmt.format(w.date)),
                  _tableCell('${w.inUnit(unit).toStringAsFixed(1)} $unit'),
                  _tableCell(w.notes ?? ''),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // ── Symptom Section ────────────────────────────────────────────────────────

  pw.Widget _symptomSection(
      List<SymptomEntry> symptoms, DateTime start, DateTime end) {
    if (symptoms.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionHeader('Symptom Summary'),
          pw.Text('No symptom entries recorded in this period.',
              style: pw.TextStyle(color: _mutedText, fontSize: 10)),
        ],
      );
    }

    final totalDays = symptoms.length;

    double avg(List<int> vals) =>
        vals.isEmpty ? 0 : vals.reduce((a, b) => a + b) / vals.length;

    final hotAvg = avg(symptoms.map((s) => s.hotFlashes).toList());
    final nauseaAvg = avg(symptoms.map((s) => s.nausea).toList());
    final sleepAvg = avg(symptoms.map((s) => s.sleeplessness).toList());
    final exhaustAvg = avg(symptoms.map((s) => s.exhaustion).toList());
    final bloatAvg = avg(symptoms.map((s) => s.bloat).toList());
    final cycleDays =
        symptoms.where((s) => s.cycle).length;
    final appetiteInc = symptoms.where((s) => s.appetite > 0).length;
    final appetiteDec = symptoms.where((s) => s.appetite < 0).length;

    List<int> peakHotFlashWeek = _peakWeek(symptoms, (s) => s.hotFlashes);
    List<int> peakExhaustWeek = _peakWeek(symptoms, (s) => s.exhaustion);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('Symptom Summary'),
        pw.Text(
          'Tracked $totalDays days  •  '
          'Avg severity (1–5 scale)',
          style: pw.TextStyle(fontSize: 9, color: _mutedText),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: null,
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _tardisBlue),
              children: [
                _tableHeader('Symptom'),
                _tableHeader('Avg Severity'),
                _tableHeader('Trend Bar'),
              ],
            ),
            _symptomRow('Hot Flashes', hotAvg, 0),
            _symptomRow('Nausea', nauseaAvg, 1),
            _symptomRow('Sleeplessness', sleepAvg, 0),
            _symptomRow('Exhaustion', exhaustAvg, 1),
            _symptomRow('Bloating', bloatAvg, 0),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.white),
              children: [
                _tableCell('Cycle Days'),
                _tableCell('$cycleDays days'),
                _tableCell(''),
              ],
            ),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _lightGray),
              children: [
                _tableCell('Appetite ↑'),
                _tableCell('$appetiteInc days'),
                _tableCell(''),
              ],
            ),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.white),
              children: [
                _tableCell('Appetite ↓'),
                _tableCell('$appetiteDec days'),
                _tableCell(''),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Events Section ─────────────────────────────────────────────────────────

  pw.Widget _eventsSection(List<EventEntry> events) {
    if (events.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionHeader('Key Events Timeline'),
          pw.Text('No events recorded in this period.',
              style: pw.TextStyle(color: _mutedText, fontSize: 10)),
        ],
      );
    }

    final fmt = DateFormat('MMM d, yyyy');
    final sorted = List<EventEntry>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('Key Events Timeline'),
        pw.Table(
          border: null,
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(3),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _tardisBlue),
              children: [
                _tableHeader('Date'),
                _tableHeader('Type'),
                _tableHeader('Name / Description'),
                _tableHeader('Notes'),
              ],
            ),
            ...sorted.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              String extraInfo = '';
              if (e.temperature != null) {
                extraInfo = '${e.temperature!.toStringAsFixed(1)}°F';
                if (e.zipcode != null) extraInfo += ' (${e.zipcode})';
              }
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                    color: i.isEven ? _lightGray : PdfColors.white),
                children: [
                  _tableCell(fmt.format(e.date)),
                  _tableCell(e.type.label),
                  _tableCell(e.name),
                  _tableCell(extraInfo.isNotEmpty
                      ? extraInfo
                      : (e.notes ?? '')),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // ── Observations Section ───────────────────────────────────────────────────

  pw.Widget _observationsSection(List<String> observations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('Key Observations & Trends'),
        if (observations.isEmpty)
          pw.Text('Insufficient data for trend analysis.',
              style: pw.TextStyle(color: _mutedText, fontSize: 10))
        else
          ...observations.map(
            (obs) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 6,
                    height: 6,
                    margin: const pw.EdgeInsets.only(top: 3, right: 8),
                    decoration: const pw.BoxDecoration(
                      color: _lavender,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(obs,
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _lightGray,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _lavender, width: 1),
          ),
          child: pw.Text(
            'This report was generated by the Regeneration app. Please share '
            'with your healthcare provider for personalized medical advice. '
            'Data reflects self-reported symptoms and should be reviewed in '
            'context with your full medical history.',
            style: pw.TextStyle(
                fontSize: 8, color: _mutedText, fontStyle: pw.FontStyle.italic),
          ),
        ),
      ],
    );
  }

  // ── Auto-generated Observations ────────────────────────────────────────────

  List<String> _generateObservations({
    required List<SymptomEntry> symptoms,
    required List<WeightEntry> weights,
    required List<EventEntry> events,
    required String weightUnit,
  }) {
    final obs = <String>[];
    final fmt = DateFormat('MMM d');

    if (symptoms.isNotEmpty) {
      // Most severe symptom
      final avgs = {
        'hot flashes': _avg(symptoms.map((s) => s.hotFlashes).toList()),
        'nausea': _avg(symptoms.map((s) => s.nausea).toList()),
        'sleeplessness': _avg(symptoms.map((s) => s.sleeplessness).toList()),
        'exhaustion': _avg(symptoms.map((s) => s.exhaustion).toList()),
        'bloating': _avg(symptoms.map((s) => s.bloat).toList()),
      };
      final worstEntry =
          avgs.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (worstEntry.value > 0) {
        obs.add(
            'Most prevalent symptom: ${worstEntry.key} (avg severity ${worstEntry.value.toStringAsFixed(1)}/5 over ${symptoms.length} tracked days).');
      }

      // Hot flash trend
      if (symptoms.length >= 14) {
        final firstHalf =
            symptoms.sublist(0, symptoms.length ~/ 2).map((s) => s.hotFlashes);
        final secondHalf =
            symptoms.sublist(symptoms.length ~/ 2).map((s) => s.hotFlashes);
        final firstAvg = _avg(firstHalf.toList());
        final secondAvg = _avg(secondHalf.toList());
        if ((secondAvg - firstAvg).abs() > 0.5) {
          final trend = secondAvg > firstAvg ? 'increased' : 'decreased';
          obs.add(
              'Hot flash severity $trend over the period (${firstAvg.toStringAsFixed(1)} → ${secondAvg.toStringAsFixed(1)}/5).');
        }
      }

      // Sleep & exhaustion correlation
      final sleepAvg = _avg(symptoms.map((s) => s.sleeplessness).toList());
      final exhaustAvg = _avg(symptoms.map((s) => s.exhaustion).toList());
      if (sleepAvg >= 3 && exhaustAvg >= 3) {
        obs.add(
            'Both sleeplessness (avg ${sleepAvg.toStringAsFixed(1)}/5) and exhaustion (avg ${exhaustAvg.toStringAsFixed(1)}/5) are elevated — may indicate disrupted sleep cycle.');
      }

      // Cycle tracking
      final cycleDays = symptoms.where((s) => s.cycle).toList();
      if (cycleDays.isNotEmpty) {
        obs.add(
            'Cycle noted on ${cycleDays.length} day(s) in this period (${fmt.format(cycleDays.first.date)} – ${fmt.format(cycleDays.last.date)}).');
      }

      // Appetite changes
      final appetiteInc = symptoms.where((s) => s.appetite > 0).length;
      final appetiteDec = symptoms.where((s) => s.appetite < 0).length;
      if (appetiteInc > symptoms.length * 0.3) {
        obs.add(
            'Increased appetite reported on ${appetiteInc} of ${symptoms.length} days (${(appetiteInc / symptoms.length * 100).round()}%).');
      }
      if (appetiteDec > symptoms.length * 0.3) {
        obs.add(
            'Decreased appetite reported on ${appetiteDec} of ${symptoms.length} days (${(appetiteDec / symptoms.length * 100).round()}%).');
      }
    }

    // Weight observations
    if (weights.length >= 2) {
      final first = weights.first.inUnit(weightUnit);
      final last = weights.last.inUnit(weightUnit);
      final delta = last - first;
      final trend =
          delta > 0.5 ? 'increased' : (delta < -0.5 ? 'decreased' : 'stable');
      obs.add(
          'Weight ${trend}: ${first.toStringAsFixed(1)} → ${last.toStringAsFixed(1)} $weightUnit (${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} $weightUnit).');
    }

    // Medication events
    final newMeds =
        events.where((e) => e.type == EventType.newMed).toList();
    final stoppedMeds =
        events.where((e) => e.type == EventType.stoppedMed).toList();
    for (final m in newMeds) {
      obs.add(
          'New medication started ${fmt.format(m.date)}: ${m.name}.');
    }
    for (final m in stoppedMeds) {
      obs.add('Medication stopped ${fmt.format(m.date)}: ${m.name}.');
    }

    // Stress events
    final stressEvents =
        events.where((e) => e.type == EventType.stress).toList();
    if (stressEvents.isNotEmpty) {
      obs.add(
          '${stressEvents.length} stressful event(s) noted: ${stressEvents.map((e) => e.name).join('; ')}.');
    }

    // Temperature range
    final tempEvents = events
        .where((e) => e.temperature != null)
        .map((e) => e.temperature!)
        .toList();
    if (tempEvents.length >= 2) {
      final minT = tempEvents.reduce(min);
      final maxT = tempEvents.reduce(max);
      obs.add(
          'Local temperature ranged from ${minT.toStringAsFixed(0)}°F to ${maxT.toStringAsFixed(0)}°F during this period.');
    }

    return obs;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  double _avg(List<int> vals) =>
      vals.isEmpty ? 0 : vals.reduce((a, b) => a + b) / vals.length;

  List<int> _peakWeek(List<SymptomEntry> symptoms, int Function(SymptomEntry) fn) {
    // returns indices of the peak week (simplified)
    return [];
  }

  pw.Widget _statBox(String label, String value,
      {PdfColor? color}) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: pw.BoxDecoration(
            color: _lightGray,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              pw.Text(value,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: color ?? _darkText,
                  )),
              pw.Text(label,
                  style: pw.TextStyle(fontSize: 8, color: _mutedText)),
            ],
          ),
        ),
      );

  pw.Widget _tableHeader(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white),
        ),
      );

  pw.Widget _tableCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
      );

  pw.TableRow _symptomRow(String name, double avg, int rowIndex) {
    final barWidth = (avg / 5.0).clamp(0.0, 1.0);
    return pw.TableRow(
      decoration: pw.BoxDecoration(
          color: rowIndex.isEven ? _lightGray : PdfColors.white),
      children: [
        _tableCell(name),
        _tableCell(avg > 0 ? avg.toStringAsFixed(1) : 'None'),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: pw.Row(
            children: [
              if (barWidth > 0)
                pw.Container(
                  height: 8,
                  width: 120 * barWidth,
                  decoration: pw.BoxDecoration(
                    color: avg >= 4
                        ? _accentRed
                        : avg >= 2
                            ? _accentOrange
                            : _lavender,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
              if (barWidth < 1.0)
                pw.Container(
                  height: 8,
                  width: 120 * (1 - barWidth),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFE0E0E0),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
