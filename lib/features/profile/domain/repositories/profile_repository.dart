import '../models/profile_model.dart';

/// Abstract contract for Profile repository (PROFILE-01, MOB-01-05)
abstract class IProfileRepository {
  /// Fetch authenticated user's full profile (PROFILE-01-05)
  Future<ProfileModel> getMyProfile();

  /// Update personal information (PROFILE-01-01)
  Future<ProfileModel> updateProfile(ProfileModel updated);

  /// Add new professional skill (PROFILE-01-02)
  Future<SkillModel> addSkill(SkillModel skill);

  /// Remove skill by id (PROFILE-01-02)
  Future<void> deleteSkill(String skillId);

  /// Add work experience entry (PROFILE-01-03)
  Future<WorkExperienceModel> addExperience(WorkExperienceModel experience);

  /// Remove work experience entry by id (PROFILE-01-03)
  Future<void> deleteExperience(String experienceId);

  /// Add education entry (PROFILE-01-04)
  Future<EducationModel> addEducation(EducationModel education);

  /// Remove education entry by id (PROFILE-01-04)
  Future<void> deleteEducation(String educationId);
}
