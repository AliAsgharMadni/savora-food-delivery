import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Multi-color Google G icon vector painter.
class GoogleGIcon extends StatelessWidget {
  final double size;
  const GoogleGIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeWidth = w * 0.20;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      w - strokeWidth,
      h - strokeWidth,
    );

    Paint arcPaint(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Red top arc
    canvas.drawArc(rect, -2.55, 1.85, false, arcPaint(const Color(0xFFEA4335)));
    // Yellow left arc
    canvas.drawArc(rect, 2.55, 1.18, false, arcPaint(const Color(0xFFFBBC05)));
    // Green bottom arc
    canvas.drawArc(rect, 0.72, 1.83, false, arcPaint(const Color(0xFF34A853)));
    // Blue right arc
    canvas.drawArc(rect, -0.05, 0.77, false, arcPaint(const Color(0xFF4285F4)));

    // Blue horizontal crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.50, h * 0.41, w * 0.48, strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Shared pill button for Google/Apple auth actions.
class SocialAuthPillButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool hasShadow;
  final VoidCallback onTap;

  const SocialAuthPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor = AppColors.surfaceContainerLow,
    this.textColor = AppColors.onSurface,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.24,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
