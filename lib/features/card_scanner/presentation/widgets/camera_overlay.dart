import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cutoutWidth = size.width * 0.85;
    const cutoutHeight = 220.0;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            AppColors.scanOverlay,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(color: Colors.transparent),
              Center(
                child: Container(
                  width: cutoutWidth,
                  height: cutoutHeight,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: SizedBox(
            width: cutoutWidth,
            height: cutoutHeight,
            child: const _CornerPainter(),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.6),
          child: Text(
            'Position your card within the frame',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _CornerPainter extends StatelessWidget {
  const _CornerPainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CornerBorderPainter());
  }
}

class _CornerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.scanCorner
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const corner = 24.0;

    // Top-left
    canvas.drawLine(const Offset(0, corner), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(corner, 0), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - corner, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, corner), paint);

    // Bottom-left
    canvas.drawLine(const Offset(0, 0) + Offset(0, size.height - corner),
        Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(corner, size.height), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - corner, size.height), Offset(size.width, size.height),
        paint);
    canvas.drawLine(Offset(size.width, size.height - corner), Offset(size.width, size.height),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}