import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tardis_painter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  int _page = 0;
  static const _totalPages = 6;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final settings = context.read<SettingsProvider>();
    FocusScope.of(context).unfocus();

    if (_page == 1 && _nameCtrl.text.trim().isNotEmpty) {
      await settings.setPatientName(_nameCtrl.text.trim());
    }
    if (_page == 2 && _zipCtrl.text.trim().isNotEmpty) {
      await settings.setZipcode(_zipCtrl.text.trim());
    }

    if (_page < _totalPages - 1) {
      setState(() => _page++);
      _pageCtrl.animateToPage(
        _page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setup_complete', true);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();
    final isLast = _page == _totalPages - 1;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Progress dots
                    Row(
                      children: List.generate(_totalPages, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: active ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? cs.primary
                                : cs.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    if (_page < _totalPages - 1)
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                              color: cs.onSurface.withOpacity(0.4),
                              fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Page content ─────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomePage(),
                    _NamePage(controller: _nameCtrl),
                    _ZipPage(controller: _zipCtrl),
                    _WeightPage(
                      unit: settings.weightUnit,
                      onChanged: (u) => settings.setWeightUnit(u),
                    ),
                    _ThemePage(
                      current: settings.colorTheme,
                      onChanged: (t) => settings.setColorTheme(t),
                    ),
                    _AllSetPage(
                        name: settings.patientName.isNotEmpty
                            ? settings.patientName
                            : 'there'),
                  ],
                ),
              ),

              // ── Continue button ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isLast ? 'Begin your journey' : 'Continue',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page 0: Welcome ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TardisWidget(size: 90),
          const SizedBox(height: 32),
          Text(
            'Regeneration',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your daily companion for tracking\nhow you feel — privately and calmly.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _FeaturePill(
              icon: Icons.favorite_outline, label: 'Daily symptom check-ins'),
          const SizedBox(height: 10),
          _FeaturePill(
              icon: Icons.monitor_weight_outlined, label: 'Weight tracking'),
          const SizedBox(height: 10),
          _FeaturePill(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Printable doctor reports'),
          const SizedBox(height: 10),
          _FeaturePill(
              icon: Icons.lock_outline, label: 'Private — stays on your device'),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: cs.onSurface.withOpacity(0.75), fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Page 1: Name ─────────────────────────────────────────────────────────────

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  const _NamePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_outline, size: 48, color: cs.primary),
          const SizedBox(height: 24),
          Text('What shall we\ncall you?',
              style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 10),
          Text(
            'Your name appears on doctor reports. You can change it anytime in Settings.',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.55), height: 1.5),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            autofocus: false,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'Your first name…',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            onSubmitted: (_) {},
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Zip ──────────────────────────────────────────────────────────────

class _ZipPage extends StatelessWidget {
  final TextEditingController controller;
  const _ZipPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, size: 48, color: cs.primary),
          const SizedBox(height: 24),
          Text('Where are\nyou located?',
              style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 10),
          Text(
            'Optional — your zip code lets us auto-log local temperature when you do your daily check-in. Useful for spotting weather patterns in your symptoms.',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.55), height: 1.5),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 5,
            style: const TextStyle(fontSize: 18, letterSpacing: 4),
            decoration: const InputDecoration(
              hintText: '00000',
              prefixIcon: Icon(Icons.pin_drop_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You can skip this — it can be added in Settings later.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: Weight unit ──────────────────────────────────────────────────────

class _WeightPage extends StatelessWidget {
  final String unit;
  final ValueChanged<String> onChanged;
  const _WeightPage({required this.unit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.monitor_weight_outlined, size: 48, color: cs.primary),
          const SizedBox(height: 24),
          Text('How do you\ntrack your weight?',
              style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 10),
          Text(
            'You can switch units anytime and log individual entries in either — this just sets your default.',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.55), height: 1.5),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _BigChoice(
                  label: 'Pounds',
                  sublabel: 'lbs',
                  selected: unit == 'lbs',
                  onTap: () => onChanged('lbs'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _BigChoice(
                  label: 'Kilograms',
                  sublabel: 'kg',
                  selected: unit == 'kg',
                  onTap: () => onChanged('kg'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigChoice extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _BigChoice(
      {required this.label,
      required this.sublabel,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : cs.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected
                    ? Colors.white.withOpacity(0.8)
                    : cs.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 4: Theme ─────────────────────────────────────────────────────────────

class _ThemePage extends StatelessWidget {
  final AppColorTheme current;
  final ValueChanged<AppColorTheme> onChanged;
  const _ThemePage({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.palette_outlined, size: 48, color: cs.primary),
          const SizedBox(height: 24),
          Text('Choose your look',
              style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 10),
          Text(
            'All themes are designed to be calming. You can change this anytime.',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.55), height: 1.5),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: AppColorTheme.values.map((t) {
              final selected = current == t;
              return GestureDetector(
                onTap: () => onChanged(t),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: t.swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? cs.onSurface : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: t.swatch.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2)
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 24)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 64,
                      child: Text(
                        t.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.55),
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
    );
  }
}

// ── Page 5: All set ───────────────────────────────────────────────────────────

class _AllSetPage extends StatelessWidget {
  final String name;
  const _AllSetPage({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TardisWidget(size: 80),
          const SizedBox(height: 28),
          Text(
            "You're all set, $name!",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Every day, Regeneration will ask you a few gentle questions. Your answers stay on this device — private, safe, and yours.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          _SummaryRow(
              icon: Icons.today_outlined,
              text: 'Open the app each day for your check-in'),
          const SizedBox(height: 14),
          _SummaryRow(
              icon: Icons.event_note_outlined,
              text: 'Log medications, stress, and cycle events'),
          const SizedBox(height: 14),
          _SummaryRow(
              icon: Icons.summarize_outlined,
              text: 'Generate a PDF report to share with your doctor'),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SummaryRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.75))),
        ),
      ],
    );
  }
}
