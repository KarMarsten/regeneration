import 'package:flutter/material.dart';

/// A custom painter that draws a simplified TARDIS (Police Box).
class TardisPainter extends CustomPainter {
  final Color bodyColor;
  final Color windowColor;
  final Color signColor;

  const TardisPainter({
    this.bodyColor = const Color(0xFF003B6F),
    this.windowColor = const Color(0xFFD4E8FF),
    this.signColor = const Color(0xFF004D99),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()..color = bodyColor;
    final windowPaint = Paint()..color = windowColor;
    final signPaint = Paint()..color = signColor;
    final darkPaint = Paint()..color = bodyColor.withOpacity(0.6);
    final whitePaint = Paint()..color = Colors.white;
    final linePaint = Paint()
      ..color = bodyColor.withOpacity(0.4)
      ..strokeWidth = w * 0.012
      ..style = PaintingStyle.stroke;

    // ── Lantern base ────────────────────────────────────────────────────────
    final lanternRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.0, w * 0.24, h * 0.12),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(lanternRect, bodyPaint);

    // Lantern glass globe
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.04), width: w * 0.16, height: h * 0.06),
      Paint()..color = const Color(0xFFE8F4FF),
    );

    // ── Main body ───────────────────────────────────────────────────────────
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.10, w, h * 0.90),
      const Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // ── "POLICE BOX" sign strip ─────────────────────────────────────────────
    final signRect = Rect.fromLTWH(0, h * 0.10, w, h * 0.10);
    canvas.drawRect(signRect, signPaint);

    // Sign text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'POLICE  BOX',
        style: TextStyle(
          color: Colors.white,
          fontSize: h * 0.055,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: w);
    textPainter.paint(
      canvas,
      Offset(
        (w - textPainter.width) / 2,
        h * 0.10 + (h * 0.10 - textPainter.height) / 2,
      ),
    );

    // ── Panel dividers ──────────────────────────────────────────────────────
    // Vertical center split
    canvas.drawLine(
        Offset(w * 0.5, h * 0.20), Offset(w * 0.5, h), linePaint);
    // Horizontal mid split
    canvas.drawLine(
        Offset(0, h * 0.60), Offset(w, h * 0.60), linePaint);

    // ── Windows (top section, 2x2 per side) ─────────────────────────────────
    _drawWindow(canvas, w * 0.08, h * 0.22, w * 0.17, h * 0.16, windowPaint, linePaint);
    _drawWindow(canvas, w * 0.28, h * 0.22, w * 0.17, h * 0.16, windowPaint, linePaint);
    _drawWindow(canvas, w * 0.55, h * 0.22, w * 0.17, h * 0.16, windowPaint, linePaint);
    _drawWindow(canvas, w * 0.75, h * 0.22, w * 0.17, h * 0.16, windowPaint, linePaint);

    // ── Lower panel decorative frames ────────────────────────────────────────
    _drawFrame(canvas, w * 0.05, h * 0.64, w * 0.40, h * 0.28, darkPaint);
    _drawFrame(canvas, w * 0.55, h * 0.64, w * 0.40, h * 0.28, darkPaint);

    // ── Door handles ─────────────────────────────────────────────────────────
    canvas.drawCircle(
        Offset(w * 0.44, h * 0.78), w * 0.025, whitePaint);
    canvas.drawCircle(
        Offset(w * 0.56, h * 0.78), w * 0.025, whitePaint);
  }

  void _drawWindow(Canvas canvas, double x, double y, double ww, double wh,
      Paint fill, Paint line) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, ww, wh),
      Radius.circular(ww * 0.1),
    );
    canvas.drawRRect(rect, fill);
    // Cross divider on window
    canvas.drawLine(Offset(x + ww / 2, y), Offset(x + ww / 2, y + wh), line);
    canvas.drawLine(Offset(x, y + wh / 2), Offset(x + ww, y + wh / 2), line);
  }

  void _drawFrame(Canvas canvas, double x, double y, double ww, double wh,
      Paint paint) {
    final strokePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, ww, wh),
        const Radius.circular(3),
      ),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(TardisPainter oldDelegate) =>
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.windowColor != windowColor;
}

/// A widget that renders the TARDIS at a given size.
class TardisWidget extends StatelessWidget {
  final double size;

  const TardisWidget({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.25),
      painter: const TardisPainter(),
    );
  }
}
