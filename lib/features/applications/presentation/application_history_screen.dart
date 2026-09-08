import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_application_repository.dart';
import '../domain/models/application_model.dart';
import '../domain/repositories/application_repository.dart';
import 'application_detail_screen.dart';
import 'widgets/application_card.dart';

/// Screen displaying list of user's job applications with status filters (APP-01-03, MOB-01-06)
class ApplicationHistoryScreen extends StatefulWidget {
  final IApplicationRepository? applicationRepository;

  const ApplicationHistoryScreen({
    super.key,
    this.applicationRepository,
  });

  @override
  State<ApplicationHistoryScreen> createState() => _ApplicationHistoryScreenState();
}

class _ApplicationHistoryScreenState extends State<ApplicationHistoryScreen> {
  late final IApplicationRepository _repository;
  List<ApplicationModel> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;
  ApplicationStatus? _selectedStatus;

  final List<ApplicationStatus?> _filterTabs = [
    null, // Tất cả
    ApplicationStatus.pending,
    ApplicationStatus.reviewed,
    ApplicationStatus.shortlisted,
    ApplicationStatus.accepted,
    ApplicationStatus.rejected,
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.applicationRepository ?? ApiApplicationRepository();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getMyApplications(status: _selectedStatus);
      if (mounted) {
        setState(() {
          _applications = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải lịch sử ứng tuyển: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onFilterSelected(ApplicationStatus? status) {
    if (_selectedStatus == status) return;
    setState(() {
      _selectedStatus = status;
    });
    _fetchApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử ứng tuyển'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _fetchApplications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          _buildFilterChips(),

          // List or Loading or Empty
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filterTabs.map((status) {
            final isSelected = _selectedStatus == status;
            final label = status == null ? 'Tất cả' : status.displayName;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (status?.color ?? AppColors.primary)
                        : AppColors.textSecondary,
                  ),
                ),
                selected: isSelected,
                showCheckmark: false,
                backgroundColor: AppColors.background,
                selectedColor: (status?.color ?? AppColors.primary).withValues(alpha: 0.15),
                side: BorderSide(
                  color: isSelected
                      ? (status?.color ?? AppColors.primary)
                      : AppColors.border,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onSelected: (_) => _onFilterSelected(status),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchApplications,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_applications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa có đơn ứng tuyển nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn chưa nộp hồ sơ vào công việc nào trong danh mục này. Hãy bắt đầu tìm kiếm cơ hội ngay hôm nay!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Tìm kiếm việc làm ngay'),
                onPressed: () {
                  context.push(AppRoutes.jobs);
                },
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchApplications,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _applications.length,
        itemBuilder: (context, index) {
          final app = _applications[index];
          return ApplicationCard(
            application: app,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ApplicationDetailScreen(
                    applicationId: app.id,
                    applicationRepository: _repository,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
