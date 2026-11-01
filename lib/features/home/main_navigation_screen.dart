import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_theme.dart';
import '../applications/presentation/application_history_screen.dart';
import '../auth/domain/models/user_model.dart';
import '../jobs/presentation/job_list_screen.dart';
import '../jobs/presentation/search_screen.dart';
import '../profile/presentation/profile_screen.dart';
import 'home_screen.dart';

/// Navigation destination descriptor for role-based tabs (MOB-01-07)
class RoleNavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int branchIndex;
  final Widget Function() screenBuilder;

  const RoleNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.branchIndex,
    required this.screenBuilder,
  });
}

/// Main Bottom Navigation Scaffold
/// Dynamically renders role-based navigation tabs according to SRS MOB-01-07:
/// - Candidate (User): Home, Search, Applications, Profile
/// - Recruiter: Home, Search, Jobs, Profile
/// - Admin: Home, Search, Profile (supported mobile scope)
/// - Unknown / Unauthenticated: Fails closed (empty navigation bar)
class MainNavigationScreen extends StatefulWidget {
  final StatefulNavigationShell? navigationShell;
  final Widget? body;
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.navigationShell,
    this.body,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();

  /// Retrieve the list of navigation destinations for a given user role (MOB-01-07).
  static List<RoleNavDestination> getDestinationsForRole(UserRole? role) {
    switch (role) {
      case UserRole.user:
        return const [
          RoleNavDestination(
            label: 'Trang chủ',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            branchIndex: 0,
            screenBuilder: _buildHomeScreen,
          ),
          RoleNavDestination(
            label: 'Tìm kiếm',
            icon: Icons.search_outlined,
            selectedIcon: Icons.search_rounded,
            branchIndex: 1,
            screenBuilder: _buildSearchScreen,
          ),
          RoleNavDestination(
            label: 'Ứng tuyển',
            icon: Icons.history_edu_outlined,
            selectedIcon: Icons.history_edu_rounded,
            branchIndex: 2,
            screenBuilder: _buildApplicationHistoryScreen,
          ),
          RoleNavDestination(
            label: 'Hồ sơ',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            branchIndex: 4,
            screenBuilder: _buildProfileScreen,
          ),
        ];

      case UserRole.recruiter:
        return const [
          RoleNavDestination(
            label: 'Trang chủ',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            branchIndex: 0,
            screenBuilder: _buildHomeScreen,
          ),
          RoleNavDestination(
            label: 'Tìm kiếm',
            icon: Icons.search_outlined,
            selectedIcon: Icons.search_rounded,
            branchIndex: 1,
            screenBuilder: _buildSearchScreen,
          ),
          RoleNavDestination(
            label: 'Tin tuyển dụng',
            icon: Icons.work_outline_rounded,
            selectedIcon: Icons.work_rounded,
            branchIndex: 3,
            screenBuilder: _buildJobListScreen,
          ),
          RoleNavDestination(
            label: 'Hồ sơ',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            branchIndex: 4,
            screenBuilder: _buildProfileScreen,
          ),
        ];

      case UserRole.admin:
        return const [
          RoleNavDestination(
            label: 'Trang chủ',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            branchIndex: 0,
            screenBuilder: _buildHomeScreen,
          ),
          RoleNavDestination(
            label: 'Tìm kiếm',
            icon: Icons.search_outlined,
            selectedIcon: Icons.search_rounded,
            branchIndex: 1,
            screenBuilder: _buildSearchScreen,
          ),
          RoleNavDestination(
            label: 'Hồ sơ',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            branchIndex: 4,
            screenBuilder: _buildProfileScreen,
          ),
        ];

      case null:
        // Unknown or missing role: fail closed
        return const [];
    }
  }

  static Widget _buildHomeScreen() => const HomeScreen();
  static Widget _buildSearchScreen() => const SearchScreen();
  static Widget _buildApplicationHistoryScreen() =>
      const ApplicationHistoryScreen();
  static Widget _buildJobListScreen() => const JobListScreen();
  static Widget _buildProfileScreen() => const ProfileScreen();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _standaloneIndex;

  @override
  void initState() {
    super.initState();
    _standaloneIndex = widget.initialIndex;
    AuthSession.instance.addListener(_onAuthSessionChanged);
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onAuthSessionChanged);
    super.dispose();
  }

  void _onAuthSessionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onDestinationSelected(
    int uiIndex,
    List<RoleNavDestination> destinations,
  ) {
    if (uiIndex < 0 || uiIndex >= destinations.length) return;
    final item = destinations[uiIndex];

    if (widget.navigationShell != null) {
      widget.navigationShell!.goBranch(
        item.branchIndex,
        initialLocation:
            item.branchIndex == widget.navigationShell!.currentIndex,
      );
    } else {
      setState(() => _standaloneIndex = uiIndex);
    }
  }

  int _calculateSelectedIndex(List<RoleNavDestination> destinations) {
    if (destinations.isEmpty) return 0;

    if (widget.navigationShell != null) {
      final currentBranch = widget.navigationShell!.currentIndex;
      final found = destinations.indexWhere(
        (item) => item.branchIndex == currentBranch,
      );
      return found != -1 ? found : 0;
    } else {
      return _standaloneIndex.clamp(0, destinations.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = AuthSession.instance.resolvedRole;
    final destinations = MainNavigationScreen.getDestinationsForRole(
      currentRole,
    );
    final selectedIndex = _calculateSelectedIndex(destinations);

    final showNavBar = destinations.length >= 2;

    return Scaffold(
      body:
          widget.navigationShell ??
          widget.body ??
          (destinations.isNotEmpty
              ? IndexedStack(
                  index: selectedIndex,
                  children: destinations.map((d) => d.screenBuilder()).toList(),
                )
              : const SizedBox.shrink()),
      bottomNavigationBar: showNavBar
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) =>
                  _onDestinationSelected(idx, destinations),
              backgroundColor: Colors.white,
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              elevation: 8,
              destinations: destinations.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(
                    item.selectedIcon,
                    color: AppColors.primary,
                  ),
                  label: item.label,
                );
              }).toList(),
            )
          : null,
    );
  }
}
