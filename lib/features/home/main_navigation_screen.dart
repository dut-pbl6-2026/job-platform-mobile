import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/auth_session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_asset.dart';
import '../../core/widgets/user_avatar.dart';
import '../applications/presentation/application_history_screen.dart';
import '../auth/domain/models/user_model.dart';
import '../connections/presentation/connections_screen.dart';
import '../cv/presentation/create_cv_screen.dart';
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

/// Persistent five-destination shell from Figma 2073:864 and role-based navigation.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.navigationShell,
    this.children,
    this.initialIndex = 0,
    this.homeScreen,
    this.body,
  });

  final StatefulNavigationShell? navigationShell;
  final List<Widget>? children;
  final int initialIndex;
  final Widget? homeScreen;
  final Widget? body;

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
  late int _currentIndex;
  final Set<int> _visited = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell?.currentIndex ?? widget.initialIndex;
    _visited.add(_currentIndex);
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

  void _onRoleDestinationSelected(
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
      setState(() {
        _currentIndex = uiIndex;
      });
    }
  }

  int _calculateRoleSelectedIndex(List<RoleNavDestination> destinations) {
    if (destinations.isEmpty) return 0;

    if (widget.navigationShell != null) {
      final currentBranch = widget.navigationShell!.currentIndex;
      final found = destinations.indexWhere(
        (item) => item.branchIndex == currentBranch,
      );
      return found != -1 ? found : 0;
    } else {
      return _currentIndex.clamp(0, destinations.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.body != null) {
      final currentRole = AuthSession.instance.resolvedRole;
      final destinations = MainNavigationScreen.getDestinationsForRole(
        currentRole,
      );
      final selectedIndex = _calculateRoleSelectedIndex(destinations);
      final showNavBar = destinations.length >= 2;

      return Scaffold(
        body: widget.body,
        bottomNavigationBar: showNavBar
            ? NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (idx) =>
                    _onRoleDestinationSelected(idx, destinations),
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

    final index = widget.navigationShell?.currentIndex ?? _currentIndex;
    final screens = [
      widget.homeScreen ?? const HomeScreen(),
      const JobListScreen(),
      const CreateCvScreen(),
      const ConnectionsScreen(),
      const ProfileScreen(),
    ];

    final Widget activePage;
    if (widget.children != null && widget.children!.isNotEmpty) {
      activePage = widget.children![index];
    } else {
      activePage = _visited.contains(index)
          ? screens[index]
          : const SizedBox.shrink();
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(key: ValueKey<int>(index), child: activePage),
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
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            top: i == selectedIndex ? -8 : 10,
                            child: Container(
                              color: Colors.transparent,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (i == selectedIndex)
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF123D8C,
                                            ).withValues(alpha: 0.12),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutBack,
                                    width: i == selectedIndex ? 48 : 28,
                                    height: i == selectedIndex ? 48 : 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i == selectedIndex
                                          ? Colors.white
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: i == selectedIndex
                                            ? const Color(0xFFC7DEFF)
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: AnimatedScale(
                                        scale: i == selectedIndex ? 1.08 : 1.0,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeOutBack,
                                        child: SizedBox(
                                          width: 23,
                                          height: 23,
                                          child: Center(
                                            child: _buildIcon(i, user),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 39,
                            left: 2,
                            right: 2,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: i == selectedIndex
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: i == selectedIndex
                                    ? AppColors.primary
                                    : AppColors.darkSurface,
                              ),
                              child: Text(
                                _labels[i],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
      2 => Icon(Icons.description_outlined, size: 23, color: iconColor),
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
