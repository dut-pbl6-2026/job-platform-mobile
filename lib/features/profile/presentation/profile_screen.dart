import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_profile_repository.dart';
import '../domain/models/profile_model.dart';
import '../domain/repositories/profile_repository.dart';
import 'widgets/add_education_dialog.dart';
import 'widgets/add_experience_dialog.dart';
import 'widgets/add_skill_dialog.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/education_section.dart';
import 'widgets/experience_section.dart';
import 'widgets/skills_section.dart';

/// User Profile Screen with personal info, skills, experience, and education (PROFILE-01, MOB-01-05)
class ProfileScreen extends StatefulWidget {
  final IProfileRepository? profileRepository;

  const ProfileScreen({super.key, this.profileRepository});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final IProfileRepository _repository;
  ProfileModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.profileRepository ?? ApiProfileRepository();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final p = await _repository.getMyProfile();
      if (mounted) {
        setState(() {
          _profile = p;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải hồ sơ cá nhân: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _openEditProfile() {
    if (_profile == null) return;
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        profile: _profile!,
        onSave: (updated) async {
          setState(() => _profile = updated);
          await _repository.updateProfile(updated);
          messenger.showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.success,
              content: Text('Đã cập nhật thông tin hồ sơ thành công!'),
            ),
          );
        },
      ),
    );
  }

  void _openAddSkill() {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AddSkillDialog(
        onAdd: (newSkill) async {
          final added = await _repository.addSkill(newSkill);
          if (mounted && _profile != null) {
            setState(() {
              _profile = _profile!.copyWith(
                skills: List.from(_profile!.skills)..add(added),
              );
            });
            messenger.showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.success,
                content: Text('Đã thêm kỹ năng mới thành công!'),
              ),
            );
          }
        },
      ),
    );
  }

  void _handleDeleteSkill(String skillId) async {
    if (_profile == null) return;
    final updatedSkills = _profile!.skills
        .where((s) => s.id != skillId)
        .toList();
    setState(() {
      _profile = _profile!.copyWith(skills: updatedSkills);
    });
    await _repository.deleteSkill(skillId);
  }

  void _openAddExperience() {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AddExperienceDialog(
        onAdd: (newExp) async {
          final added = await _repository.addExperience(newExp);
          if (mounted && _profile != null) {
            setState(() {
              _profile = _profile!.copyWith(
                experiences: List.from(_profile!.experiences)..insert(0, added),
              );
            });
            messenger.showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.success,
                content: Text('Đã thêm kinh nghiệm làm việc thành công!'),
              ),
            );
          }
        },
      ),
    );
  }

  void _handleDeleteExperience(String expId) async {
    if (_profile == null) return;
    final updated = _profile!.experiences.where((e) => e.id != expId).toList();
    setState(() {
      _profile = _profile!.copyWith(experiences: updated);
    });
    await _repository.deleteExperience(expId);
  }

  void _openAddEducation() {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AddEducationDialog(
        onAdd: (newEdu) async {
          final added = await _repository.addEducation(newEdu);
          if (mounted && _profile != null) {
            setState(() {
              _profile = _profile!.copyWith(
                educations: List.from(_profile!.educations)..insert(0, added),
              );
            });
            messenger.showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.success,
                content: Text('Đã thêm học vấn thành công!'),
              ),
            );
          }
        },
      ),
    );
  }

  void _handleDeleteEducation(String eduId) async {
    if (_profile == null) return;
    final updated = _profile!.educations.where((e) => e.id != eduId).toList();
    setState(() {
      _profile = _profile!.copyWith(educations: updated);
    });
    await _repository.deleteEducation(eduId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Chỉnh sửa hồ sơ',
            onPressed: _profile != null ? _openEditProfile : null,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null || _profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 56,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Không thể tải hồ sơ.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProfile,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            _buildProfileHeaderCard(profile),

            const SizedBox(height: 16),

            // Profile Completion Progress Card
            _buildCompletionCard(profile),

            const SizedBox(height: 20),

            // Summary / Bio Card
            _buildSummaryCard(profile),

            const SizedBox(height: 24),

            // Skills Section (PROFILE-01-02)
            SkillsSection(
              skills: profile.skills,
              onAddSkill: _openAddSkill,
              onDeleteSkill: _handleDeleteSkill,
            ),

            const SizedBox(height: 24),

            // Work Experience Section (PROFILE-01-03)
            ExperienceSection(
              experiences: profile.experiences,
              onAddExperience: _openAddExperience,
              onDeleteExperience: _handleDeleteExperience,
            ),

            const SizedBox(height: 24),

            // Education Section (PROFILE-01-04)
            EducationSection(
              educations: profile.educations,
              onAddEducation: _openAddEducation,
              onDeleteEducation: _handleDeleteEducation,
            ),

            const SizedBox(height: 24),

            // Quick Access Card to Application History
            InkWell(
              onTap: () {
                context.go(AppRoutes.applications);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.primaryLight.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_edu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lịch sử ứng tuyển',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Theo dõi trạng thái các việc làm đã nộp CV',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(ProfileModel profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary,
                child: Text(
                  profile.fullName.isNotEmpty
                      ? profile.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (profile.headline != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.headline!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Contact details
          if (profile.phone != null) ...[
            _buildContactChip(Icons.phone_outlined, profile.phone!),
            const SizedBox(height: 6),
          ],
          if (profile.address != null) ...[
            _buildContactChip(Icons.location_on_outlined, profile.address!),
          ],
        ],
      ),
    );
  }

  Widget _buildContactChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionCard(ProfileModel profile) {
    final pct = profile.completionPercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Độ hoàn thiện hồ sơ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: pct >= 80 ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 80 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct >= 80
                ? 'Hồ sơ của bạn đã rất đầy đủ và thu hút nhà tuyển dụng!'
                : 'Hoàn thiện thêm kỹ năng và học vấn để tăng 300% cơ hội trúng tuyển.',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ProfileModel profile) {
    if (profile.summary == null || profile.summary!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giới thiệu bản thân',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.summary!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
