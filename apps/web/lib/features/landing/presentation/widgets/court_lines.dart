import 'package:material_ui/material_ui.dart';

/// Faint half-court markings (baseline, key, free-throw circle, three-point
/// arc) drawn behind the hero; decoration only.
class CourtLines extends StatelessWidget {
  const CourtLines({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(painter: _CourtPainter(color), size: Size.infinite),
  );
}

class _CourtPainter extends CustomPainter {
  _CourtPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final w = size.width;
    final h = size.height;
    final baseY = h * 0.98;
    final cx = w / 2;

    // Baseline.
    canvas.drawLine(Offset(0, baseY), Offset(w, baseY), paint);

    // The key (paint) and the free-throw circle.
    final keyWidth = w * 0.34;
    final keyHeight = h * 0.40;
    final key = Rect.fromLTWH(
      cx - keyWidth / 2,
      baseY - keyHeight,
      keyWidth,
      keyHeight,
    );
    canvas.drawRect(key, paint);
    canvas.drawCircle(Offset(cx, key.top), keyWidth / 2, paint);

    // Three-point arc around the basket, with its straight corner lines.
    final basket = Offset(cx, baseY - h * 0.08);
    final radius = w * 0.47;
    canvas.drawArc(
      Rect.fromCircle(center: basket, radius: radius),
      3.3,
      2.82,
      false,
      paint,
    );
    canvas.drawCircle(basket, w * 0.025, paint);
  }

  @override
  bool shouldRepaint(_CourtPainter old) => old.color != color;
}
