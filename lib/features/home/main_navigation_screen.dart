import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../applications/presentation/application_history_screen.dart';
import '../jobs/presentation/job_list_screen.dart';
import '../profile/presentation/profile_screen.dart';
import 'home_screen.dart';

/// Main Bottom Navigation Scaffold per SRS MOB-01-07
/// Provides unified navigation across: Home, Jobs, Applications, and Profile
class MainNavigationScreen extends StatefulWidget {
  final StatefulNavigationShell? navigationShell;
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.navigationShell,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell?.currentIndex ?? widget.initialIndex;
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    JobListScreen(),
    ApplicationHistoryScreen(),
    ProfileScreen(),
  ];

  void _onDestinationSelected(int index) {
    if (widget.navigationShell != null) {
      widget.navigationShell!.goBranch(
        index,
        initialLocation: index == widget.navigationShell!.currentIndex,
      );
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navigationShell?.currentIndex ?? _currentIndex;

    return Scaffold(
      body:
          widget.navigationShell ??
          IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded, color: AppColors.primary),
            label: 'Việc làm',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_edu_outlined),
            selectedIcon: Icon(
              Icons.history_edu_rounded,
              color: AppColors.primary,
            ),
            label: 'Ứng tuyển',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
