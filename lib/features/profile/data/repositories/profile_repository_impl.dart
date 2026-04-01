import '../../../../core/utils/logger.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_data_source.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;

  @override
  Future<ProfileModel> getProfile({bool forceRefresh = false}) async {
    try {
      // Try cache first unless force refresh
      if (!forceRefresh) {
        final cachedProfile = await localDataSource.getCachedProfile();
        if (cachedProfile != null) {
          AppLogger.debug('Returning cached profile');
          return cachedProfile;
        }
      }

      // Fetch from API
      AppLogger.debug('Fetching profile from API');
      final profile = await remoteDataSource.getProfile();
      
      // Cache the result
      await localDataSource.cacheProfile(profile);
      
      return profile;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get profile', e, stackTrace);
      
      // Try to return cached data as fallback
      final cachedProfile = await localDataSource.getCachedProfile();
      if (cachedProfile != null) {
        AppLogger.debug('Returning cached profile as fallback');
        return cachedProfile;
      }
      
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
      final updatedProfile = await remoteDataSource.updateProfile(
        name: name,
        bio: bio,
        phone: phone,
        location: location,
      );
      
      // Update cache
      await localDataSource.cacheProfile(updatedProfile);
      
      return updatedProfile;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update profile', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    try {
      return await remoteDataSource.uploadAvatar(filePath);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload avatar', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    await localDataSource.clearCachedProfile();
  }
}

