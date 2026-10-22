import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/auth_session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_asset.dart';
import '../../core/widgets/user_avatar.dart';
import '../connections/presentation/connections_screen.dart';
import '../cv/presentation/create_cv_screen.dart';
import '../jobs/presentation/job_list_screen.dart';
import '../profile/presentation/profile_screen.dart';
import 'home_screen.dart';

/// Persistent five-destination shell from Figma 2073:864.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.navigationShell,
    this.initialIndex = 0,
    this.homeScreen,
  });

  final StatefulNavigationShell? navigationShell;
  final int initialIndex;
  final Widget? homeScreen;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final Set<int> _visited = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell?.currentIndex ?? widget.initialIndex;
    _visited.add(_currentIndex);
  }

  void _select(int index) {
    final shell = widget.navigationShell;
    if (shell != null) {
      shell.goBranch(index, initialLocation: index == shell.currentIndex);
    } else {
      setState(() {
        _currentIndex = index;
        _visited.add(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell?.currentIndex ?? _currentIndex;
    final screens = [
      widget.homeScreen ?? const HomeScreen(),
      const JobListScreen(),
      const CreateCvScreen(),
      const ConnectionsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body:
          widget.navigationShell ??
          IndexedStack(
            index: index,
            children: [
              for (var i = 0; i < screens.length; i++)
                _visited.contains(i) ? screens[i] : const SizedBox.shrink(),
            ],
          ),
      bottomNavigationBar: JobBottomNavigation(
        selectedIndex: index,
        onSelected: _select,
      ),
    );
  }
}

/// The selected item protrudes above the bar; tap and semantic bounds stay 74 px.
class JobBottomNavigation extends StatelessWidget {
  const JobBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _labels = [
    'Trang chủ',
    'Việc làm',
    'Tạo CV',
    'NTD kết nối',
    'Hồ sơ',
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.none, // Cho phép phần tử con nhô lên trên thanh bar
      child: SafeArea(
        top: false,
        child: Container(
          height: AppDimensions.navigationHeight,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: Color(0xFFE8F0FA))),
          ),
          child: Row(
            // Ép chiều cao mỗi tab luôn bằng đúng chiều cao thanh điều hướng (74px)
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _labels.length; i++)
                Expanded(
                  child: Semantics(
                    label: _labels[i],
                    button: true,
                    selected: i == selectedIndex,
                    child: InkWell(
                      onTap: () => onSelected(i),
                      // Tắt splash/highlight vuông gây mất thẩm mỹ khi icon nhô lên ngoài bar
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          // Giữ bounding box của Stack luôn lấp đầy vùng 74px của tab
                          const SizedBox.expand(),
                          if (i == selectedIndex)
                            Positioned(
                              top: -20,
                              child: IgnorePointer(
                                child: Image.asset(
                                  'assets/figma/nav-selected.png',
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          Positioned(
                            top: i == selectedIndex ? -5 : 10,
                            child: SizedBox(
                              width: 23,
                              height: 23,
                              child: Center(child: _buildIcon(i, user)),
                            ),
                          ),
                          Positioned(
                            top: 39,
                            left: 2,
                            right: 2,
                            child: Text(
                              _labels[i],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                color: i == selectedIndex
                                    ? AppColors.primary
                                    : AppColors.darkSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(int index, dynamic user) {
    final isSelected = index == selectedIndex;
    final iconColor = isSelected ? AppColors.primary : AppColors.darkSurface;

    return switch (index) {
      0 => DesignAsset('nav-home', width: 23, height: 23, color: iconColor),
      1 => DesignAsset('nav-jobs', width: 23, height: 23, color: iconColor),
      2 => DesignAsset(
        'nav-cv', // Thay ký tự vuông '▣' bằng asset hoặc Icon chuẩn
        width: 23,
        height: 23,
        color: iconColor,
      ),
      3 => DesignAsset(
        'nav-connections',
        width: 23,
        height: 23,
        color: iconColor,
      ),
      _ => UserAvatar(
        name: user?.name,
        imageUrl: user?.avatarUrl,
        radius: 11.5,
      ),
    };
  }
}
