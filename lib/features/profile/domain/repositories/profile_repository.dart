import '../../data/models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> getProfile({bool forceRefresh = false});
  Future<ProfileModel> updateProfile({
    String? name,
    String? bio,
    String? phone,
    String? location,
  });
  Future<String> uploadAvatar(String filePath);
  Future<void> clearCache();
}

