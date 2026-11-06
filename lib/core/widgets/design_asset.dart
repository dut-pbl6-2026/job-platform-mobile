import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Original Figma vectors rendered at their exported intrinsic dimensions.
class DesignAsset extends StatelessWidget {
  const DesignAsset(
    this.name, {
    super.key,
    this.color,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String name;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;

  String get _assetPath {
    final cleanName = name.endsWith('.svg')
        ? name.substring(0, name.length - 4)
        : name;
    return 'assets/figma/$cleanName.svg';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        _assetPath,
        width: width,
        height: height,
        fit: fit,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color!, BlendMode.srcIn),
        excludeFromSemantics: true,
      ),
    );
  }
}
