import '../models/profile_model.dart';

/// The signed-in account has no profile yet (`404` from `/api/profiles/me`).
///
/// Recruiters and admins can also open the profile, so the first visit must be
/// able to create the profile instead of showing an error.
class ProfileNotFoundException implements Exception {
  const ProfileNotFoundException();

  @override
  String toString() => 'ProfileNotFoundException';
}

/// Abstract contract for Profile repository (PROFILE-01, MOB-01-05)
abstract class IProfileRepository {
  /// Fetch authenticated user's full profile (PROFILE-01-05)
  Future<ProfileModel> getMyProfile();

  /// Fetch the profile, creating it first when the API answers `404`.
  Future<ProfileModel> getOrCreateProfile();

  /// Create a minimal profile for the signed-in account.
  Future<ProfileModel> createProfile();

  /// Update personal information (PROFILE-01-01)
  Future<ProfileModel> updateProfile(ProfileModel updated);

  /// Add new professional skill (PROFILE-01-02)
  Future<SkillModel> addSkill(SkillModel skill);

  /// Remove skill by id (PROFILE-01-02)
  Future<void> deleteSkill(String skillId);

  /// Add work experience entry (PROFILE-01-03)
  Future<WorkExperienceModel> addExperience(WorkExperienceModel experience);

  /// Update work experience entry (PROFILE-01-03)
  Future<WorkExperienceModel> updateExperience(WorkExperienceModel experience);

  /// Remove work experience entry by id (PROFILE-01-03)
  Future<void> deleteExperience(String experienceId);

  /// Add education entry (PROFILE-01-04)
  Future<EducationModel> addEducation(EducationModel education);

  /// Update education entry (PROFILE-01-04)
  Future<EducationModel> updateEducation(EducationModel education);

  /// Remove education entry by id (PROFILE-01-04)
  Future<void> deleteEducation(String educationId);
}
