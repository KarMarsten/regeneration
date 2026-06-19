import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tardis_painter.dart';

const _sampleText = 'Today I felt hopeful…';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _zipCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _nameCtrl = TextEditingController(text: s.patientName);
    _zipCtrl = TextEditingController(text: s.zipcode);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Settings')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── App identity ─────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                const TardisWidget(size: 70),
                const SizedBox(height: 10),
                Text(
                  'Regeneration',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                Text(
                  'Menopause & Weight Tracker',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.5)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.3)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Profile ──────────────────────────────────────────────────────
          _sectionLabel(context, 'Profile'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'Appears on doctor reports',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onSubmitted: (v) =>
                        settings.setPatientName(v.trim()),
                    onEditingComplete: () =>
                        settings.setPatientName(_nameCtrl.text.trim()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _zipCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: const InputDecoration(
                      labelText: 'Home Zip Code',
                      hintText: 'Used for auto temperature logging',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      counterText: '',
                    ),
                    onSubmitted: (v) =>
                        settings.setZipcode(v.trim()),
                    onEditingComplete: () =>
                        settings.setZipcode(_zipCtrl.text.trim()),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () {
                        settings.setPatientName(_nameCtrl.text.trim());
                        settings.setZipcode(_zipCtrl.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile saved'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Weight Unit ──────────────────────────────────────────────────
          _sectionLabel(context, 'Weight Unit'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.monitor_weight_outlined, color: cs.primary),
                  const SizedBox(width: 12),
                  const Text('Preferred unit'),
                  const Spacer(),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'lbs', label: Text('lbs')),
                      ButtonSegment(value: 'kg', label: Text('kg')),
                    ],
                    selected: {settings.weightUnit},
                    onSelectionChanged: (v) =>
                        settings.setWeightUnit(v.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Color Theme ──────────────────────────────────────────────────
          _sectionLabel(context, 'Color Theme'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current: ${settings.colorTheme.label}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppColorTheme.values.map((t) {
                      final selected = settings.colorTheme == t;
                      return GestureDetector(
                        onTap: () => settings.setColorTheme(t),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: t.swatch,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? cs.onSurface
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: t.swatch.withOpacity(0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 22)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 60,
                              child: Text(
                                t.label,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selected
                                      ? cs.primary
                                      : cs.onSurface.withOpacity(0.6),
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Journal Font ─────────────────────────────────────────────────
          _sectionLabel(context, 'Journal Font'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Font used in your journal entries.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.55)),
                  ),
                  const SizedBox(height: 14),
                  ...kJournalFonts.map(((String, String) f) {
                    final (fontFamily, displayName) = f;
                    final selected = settings.journalFont == fontFamily;
                    return GestureDetector(
                      onTap: () => settings.setJournalFont(fontFamily),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primaryContainer
                              : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? cs.primary
                                : cs.outlineVariant.withOpacity(0.4),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _sampleText,
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontFamilyFallback: const ['.SF Pro Text'],
                                  fontSize: 15,
                                  color: selected
                                      ? cs.primary
                                      : cs.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                            Text(
                              displayName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: selected
                                    ? cs.primary
                                    : cs.onSurface.withOpacity(0.4),
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.check_circle,
                                  size: 16, color: cs.primary),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── About ────────────────────────────────────────────────────────
          _sectionLabel(context, 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: cs.primary),
                  title: const Text('About Regeneration'),
                  subtitle: const Text('Version 1.0.0 · Privacy · Purpose'),
                  trailing: Icon(Icons.chevron_right,
                      color: cs.onSurface.withOpacity(0.3)),
                  onTap: () => Navigator.of(context).pushNamed('/about'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      Icon(Icons.security_outlined, color: cs.primary),
                  title: const Text('Private by design'),
                  subtitle: const Text(
                      'All data stays on your device — nothing is uploaded or shared.'),
                  dense: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
        ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5),
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
