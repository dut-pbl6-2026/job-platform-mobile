import 'package:flutter/material.dart';

/// Reading widths specified by the portrait and landscape Figma variants.
class AppContent extends StatelessWidget {
  const AppContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isTablet = constraints.maxWidth >= 600;
      final maxWidth =
          MediaQuery.orientationOf(context) == Orientation.landscape
          ? 800.0
          : 640.0;
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTablet ? maxWidth : constraints.maxWidth,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 0 : 20),
            child: child,
          ),
        ),
      );
    },
  );
}
