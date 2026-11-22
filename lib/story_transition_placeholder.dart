import 'package:flutter/material.dart';

class StoryTransitionPlaceholder extends StatelessWidget {
  const StoryTransitionPlaceholder({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.15,
          colors: [Color(0xFF183027), Color(0xFF080D0B), Color(0xFF050706)],
          stops: [0, 0.65, 1],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF00FF88),
              size: 28,
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'جارٍ الانتقال للمشهد التالي...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
