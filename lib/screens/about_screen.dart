import 'package:flutter/material.dart';
import '../widgets/tardis_painter.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('About'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // ── Identity ───────────────────────────────────────────────────
            const TardisWidget(size: 90),
            const SizedBox(height: 20),
            Text(
              'Regeneration',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Menopause & Weight Tracker',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version 1.0.0',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 36),

            // ── Purpose ────────────────────────────────────────────────────
            _Section(
              icon: Icons.favorite_outline,
              title: 'Why Regeneration?',
              body:
                  'Menopause is a journey that\'s different for everyone — and too often we go through it alone, without the data to have informed conversations with our doctors. Regeneration gives you a calm, private space to track how you feel each day and turn those observations into something useful.',
            ),

            const SizedBox(height: 20),

            // ── Privacy ────────────────────────────────────────────────────
            _Section(
              icon: Icons.lock_outline,
              title: 'Private by design',
              body:
                  'All of your data — symptoms, weights, events, and notes — stays on this device. Nothing is uploaded, shared, or stored in the cloud. Your health information is yours alone.',
            ),

            const SizedBox(height: 20),

            // ── Features ───────────────────────────────────────────────────
            _Section(
              icon: Icons.auto_awesome_outlined,
              title: 'What you can track',
              body: null,
              child: Column(
                children: const [
                  _FeatureRow(
                      icon: Icons.sunny_snowing,
                      label: 'Hot flashes, nausea, bloating, and more'),
                  _FeatureRow(
                      icon: Icons.bedtime_outlined,
                      label: 'Sleep quality and energy levels'),
                  _FeatureRow(
                      icon: Icons.water_drop_outlined,
                      label: 'Cycle tracking'),
                  _FeatureRow(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Weight in lbs or kg'),
                  _FeatureRow(
                      icon: Icons.medication_outlined,
                      label: 'Medication starts and stops'),
                  _FeatureRow(
                      icon: Icons.thermostat_outlined,
                      label: 'Local temperature auto-logged by zip code'),
                  _FeatureRow(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'Printable PDF report for your doctor'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Doctor Who ─────────────────────────────────────────────────
            _Section(
              icon: Icons.explore_outlined,
              title: 'The TARDIS connection',
              body:
                  'The name "Regeneration" and the TARDIS theme are a nod to Doctor Who — because regeneration is exactly what this phase of life can be. A transformation, not an ending.',
            ),

            const SizedBox(height: 20),

            // ── Disclaimer ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 18,
                      color: cs.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Regeneration is a personal tracking tool, not a medical device. Always consult your healthcare provider for medical advice.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'Made with care for women\'s health 💙',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.35)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final Widget? child;

  const _Section({
    required this.icon,
    required this.title,
    this.body,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: 10),
            Text(
              body!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.65),
                height: 1.55,
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 10),
            child!,
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
