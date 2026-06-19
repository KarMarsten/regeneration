import 'package:flutter/material.dart';

class SeveritySlider extends StatelessWidget {
  final String label;
  final int value; // 0–5
  final ValueChanged<int> onChanged;
  final IconData icon;

  const SeveritySlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  String get _severityLabel {
    switch (value) {
      case 0:
        return 'None';
      case 1:
        return 'Mild';
      case 2:
        return 'Moderate';
      case 3:
        return 'Noticeable';
      case 4:
        return 'Severe';
      case 5:
        return 'Extreme';
      default:
        return '';
    }
  }

  Color _severityColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (value) {
      case 0:
        return cs.onSurface.withOpacity(0.3);
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
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final severityColor = _severityColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: severityColor, width: 1),
                  ),
                  child: Text(
                    _severityLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: severityColor,
                thumbColor: severityColor,
                inactiveTrackColor: cs.surfaceContainerHighest,
                overlayColor: severityColor.withOpacity(0.15),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
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
              children: List.generate(
                6,
                (i) => Text(
                  '$i',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: i == value
                        ? severityColor
                        : cs.onSurface.withOpacity(0.4),
                    fontWeight:
                        i == value ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
