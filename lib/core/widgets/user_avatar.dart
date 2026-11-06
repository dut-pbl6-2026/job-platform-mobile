import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Session imagery remains dynamic; the design's example photo is not a user.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.name, this.imageUrl, this.radius = 23});

  final String? name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.primaryLight,
    child: ClipOval(
      child: imageUrl?.isNotEmpty == true
          ? Image.network(
              imageUrl!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initial(),
            )
          : _initial(),
    ),
  );

  Widget _initial() => Text(
    name?.isNotEmpty == true ? name!.characters.first.toUpperCase() : 'U',
    style: TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      fontSize: radius * .8,
    ),
  );
}
