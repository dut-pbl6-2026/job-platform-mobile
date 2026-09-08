import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/profile_model.dart';

/// Skills Section displaying candidate skills with star rating & years of experience (PROFILE-01-02)
class SkillsSection extends StatelessWidget {
  final List<SkillModel> skills;
  final VoidCallback onAddSkill;
  final ValueChanged<String> onDeleteSkill;

  const SkillsSection({
    super.key,
    required this.skills,
    required this.onAddSkill,
    required this.onDeleteSkill,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kỹ năng chuyên môn (${skills.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm'),
              onPressed: onAddSkill,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (skills.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Chưa có kỹ năng nào. Nhấn "+ Thêm" để cập nhật kỹ năng chuyên môn.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            // Star rating
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < skill.proficiency
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 13,
                                  color: const Color(0xFFF59E0B),
                                );
                              }),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${skill.yearsOfExperience} năm',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => onDeleteSkill(skill.id),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
