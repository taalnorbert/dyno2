import 'package:flutter/material.dart';
import 'dart:math';

class SpeedMeter extends StatefulWidget {
  const SpeedMeter({super.key});

  @override
  State<SpeedMeter> createState() => _SpeedMeterState();
}

class _SpeedMeterState extends State<SpeedMeter> with SingleTickerProviderStateMixin {
  late Animation<double> anim;
  late AnimationController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: 1500));
    anim = Tween<double>(begin: 0, end: 72).animate(ctrl);
    ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).width,
          child: AnimatedBuilder(
            builder: (context, child) {
              return CustomPaint(
                painter: MeterPainter(anim.value),
              );
            },
            animation: ctrl,
          ),
        ),
      ),
    );
  }
}

class MeterPainter extends CustomPainter {
  final double speed;
  final bool isKmh;

  MeterPainter(this.speed, {this.isKmh = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final centerY = h / 2;

    final center = Offset(centerX, centerY);
    final rect = Rect.fromCenter(center: center, width: w * 0.7, height: h * 0.7);
    final largeRect = Rect.fromCenter(center: center, width: w * 0.75, height: h * 0.75);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.grey;

    final thickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.grey.shade900;
    final startAngle = angleToRadian(135);
    final sweepAngle = angleToRadian(270);

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    canvas.drawArc(largeRect, startAngle, sweepAngle, false, thickPaint);

    final percent = (speed / 200).clamp(0, 1);
    final speedAngle = sweepAngle * percent;

    canvas.drawArc(largeRect, startAngle, speedAngle, false, thickPaint..color = Colors.pink);

    final radius = w / 2;

    for (num angle = 135; angle <= 405; angle += 4.5) {
      final start = angleToOffset(center, angle, radius * 0.7);
      final end = angleToOffset(center, angle, radius * 0.65);
      canvas.drawLine(start, end, paint);
    }

    final highlights = List.generate(11, (index) => 135 + (27 * index));
    for (int i = 0; i < highlights.length; i++) {
      var angle = highlights[i];
      final start = angleToOffset(center, angle, radius * 0.7);
      final end = angleToOffset(center, angle, radius * 0.575);
      canvas.drawLine(start, end, paint);

      final tp = TextPainter(
          text: TextSpan(text: "${i * 20}", style: TextStyle(color: Colors.white)),
          textDirection: TextDirection.ltr);
      tp.layout();
      final textOffset = angleToOffset(center, angle, radius * 0.5);
      final centered = Offset(textOffset.dx - tp.width / 2, textOffset.dy - tp.height / 2);
      tp.paint(canvas, centered);
    }

    // Sebességérték és mértékegység megjelenítése
    final speedText = isKmh ? speed.toInt() : (speed * 0.621371).toInt();
    final unitText = isKmh ? "km/h" : "mph";

    final tp = TextPainter(
        text: TextSpan(
            text: "$speedText",
            style: TextStyle(fontSize: 60, color: Colors.white),
            children: [
              TextSpan(
                text: "\n$unitText",
                style: TextStyle(fontSize: 25, color: Colors.white),
              )
            ]),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    final centered = Offset(center.dx - tp.width / 2, center.dy - tp.height / 2);
    tp.paint(canvas, centered);
  }

  Offset angleToOffset(Offset center, num angle, double distance) {
    final radian = angleToRadian(angle);
    final x = center.dx + distance * cos(radian);
    final y = center.dy + distance * sin(radian);
    return Offset(x, y);
  }

  double angleToRadian(num angle) {
    return angle * pi / 180;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}