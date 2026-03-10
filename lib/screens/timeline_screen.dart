import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shadow-Timeline Heatmap', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: AppColors.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('24-Hour Sensor Activity: FlashlightPro', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 150,
              child: CustomPaint(
                painter: HeatmapPainter(),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Red marks indicate 'Shadow Access' (sensor accessed while app was in background without visible UI).",
              style: TextStyle(color: AppColors.alertRed, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class HeatmapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final int maxBars = 24;
    final double barTotalWidth = size.width / maxBars;
    final double barWidth = barTotalWidth * 0.6;
    final double gapWidth = barTotalWidth * 0.4;
    
    final List<int> shadowPings = [3, 4, 14, 19, 20];
    
    final Paint normalPaint = Paint()..color = Colors.grey[800]!;
    final Paint shadowPaint = Paint()..color = AppColors.alertRed;

    for (int i = 0; i < maxBars; i++) {
      final bool isShadow = shadowPings.contains(i);
      final double height = isShadow ? size.height * 0.8 : size.height * 0.3;
      final Paint paint = isShadow ? shadowPaint : normalPaint;
      
      final double x = i * barTotalWidth + (gapWidth / 2);
      final double y = size.height - height;
      
      final rect = Rect.fromLTWH(x, y, barWidth, height);
      canvas.drawRect(rect, paint);
    }
    
    // Draw baseline
    final baselinePaint = Paint()
      ..color = AppColors.lightGray
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height), 
      Offset(size.width, size.height), 
      baselinePaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
