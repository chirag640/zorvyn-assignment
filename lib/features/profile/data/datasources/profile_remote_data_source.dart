import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/logger.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<ProfileModel> updateProfile({
    String? name,
    String? bio,
    String? phone,
    String? location,
  });
  Future<String> uploadAvatar(String filePath);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl({
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  Future<ProfileModel> getProfile() async {
    try {
      AppLogger.debug('Fetching user profile from API');
      final response = await apiClient.get(ApiEndpoints.profile);
      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch profile', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<ProfileModel> updateProfile({
    String? name,
    String? bio,
    String? phone,
    String? location,
  }) async {
    try {
      AppLogger.debug('Updating user profile');
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (bio != null) data['bio'] = bio;
      if (phone != null) data['phone'] = phone;
      if (location != null) data['location'] = location;

      final response = await apiClient.put(
        ApiEndpoints.profile,
        data: data,
      );
      AppLogger.info('Profile updated successfully');
      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update profile', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    try {
      AppLogger.debug('Uploading avatar image');
      // In a real app, you would use FormData to upload the file
      // For demo purposes, we'll simulate by returning a mock URL
      await Future.delayed(const Duration(seconds: 2));
      final avatarUrl = 'https://i.pravatar.cc/150?img=${DateTime.now().millisecondsSinceEpoch % 70}';
      AppLogger.info('Avatar uploaded successfully');
      return avatarUrl;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload avatar', e, stackTrace);
      rethrow;
    }
  }
}

