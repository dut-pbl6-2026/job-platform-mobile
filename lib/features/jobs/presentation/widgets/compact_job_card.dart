import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/design_asset.dart';
import '../../domain/models/job_model.dart';

/// Compact listing from Figma 55:3503 with dynamic job content.
class CompactJobCard extends StatelessWidget {
  const CompactJobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.onBookmarkToggle,
  });

  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback? onBookmarkToggle;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: math.max(AppDimensions.compactJobHeight, 100 * scale),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 15, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _companyLogo(),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 36),
                              child: Text(
                                job.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              job.companyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              job.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 8,
                                color: Color(0xB3000000),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _tag(job.jobType.value),
                                _tag(job.experienceLevel.value),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 1,
                top: 0,
                child: IconButton(
                  tooltip: job.isSaved ? 'Bỏ lưu tin' : 'Lưu tin tuyển dụng',
                  onPressed: onBookmarkToggle,
                  icon: job.isSaved
                      ? const Icon(
                          Icons.bookmark,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : const DesignAsset('bookmark'),
                ),
              ),
              Positioned(
                right: 15,
                bottom: 5,
                child: Text(
                  FormatUtils.timeAgo(job.postedAt),
                  style: const TextStyle(fontSize: 9, color: Color(0xB3000000)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _companyLogo() {
    final logo = job.companyLogo;
    final name = job.companyName.toLowerCase().replaceAll(' inc.', '').trim();
    return SizedBox.square(
      dimension: 40,
      child: logo?.isNotEmpty == true
          ? Image.network(
              logo!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _initial(),
            )
          : switch (name) {
              'badoo' => const DesignAsset('badoo'),
              'meta' => const DesignAsset('meta'),
              'netflix' => const DesignAsset('netflix'),
              'bmw' => const Center(child: DesignAsset('bmw')),
              _ => _initial(),
            },
    );
  }

  Widget _initial() => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Center(
      child: Text(
        job.companyName.isEmpty ? 'J' : job.companyName.characters.first,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    ),
  );

  Widget _tag(String text) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Text(
        text,
        style: const TextStyle(fontSize: 8, color: Colors.white),
      ),
    ),
  );
}
