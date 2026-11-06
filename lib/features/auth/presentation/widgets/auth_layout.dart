import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_content.dart';
import '../../../../core/widgets/design_asset.dart';

/// Shared white canvas and decorative assets from the Figma auth family.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(
          right: -58,
          top: -58,
          child: DesignAsset('auth-accent-top'),
        ),
        const Positioned(
          left: -55,
          bottom: 65,
          child: DesignAsset('auth-accent-bottom'),
        ),
        SafeArea(
          child: SingleChildScrollView(
            child: AppContent(
              child: Padding(
                padding: const EdgeInsets.only(top: 35, bottom: 24),
                child: child,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) => const Stack(
    alignment: Alignment.center,
    children: [
      DesignAsset('auth-logo'),
      Text(
        'J',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ],
  );
}

class AuthField extends StatelessWidget {
  const AuthField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF141A24),
        ),
      ),
      const SizedBox(height: 6),
      Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.copyWith(
            titleMedium: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            fillColor: Colors.white,
            isDense: true,
            constraints: const BoxConstraints(minHeight: 52),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        child: child,
      ),
    ],
  );
}
