import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    required this.visible,
    required this.child,
    super.key,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x990D1110),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
          ),
      ],
    );
  }
}
