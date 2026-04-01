import '../../../../core/utils/logger.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/profile_model.dart';

abstract class ProfileLocalDataSource {
  Future<ProfileModel?> getCachedProfile();
  Future<void> cacheProfile(ProfileModel profile);
  Future<void> clearCachedProfile();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  const ProfileLocalDataSourceImpl({
    required this.localStorage,
  });

  final LocalStorage localStorage;

  static const String _profileKey = 'cached_profile';
  static const String _profileTimestampKey = 'cached_profile_timestamp';

  @override
  Future<ProfileModel?> getCachedProfile() async {
    try {
      final timestamp = localStorage.getString(_profileTimestampKey);
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
        final now = DateTime.now();
        final difference = now.difference(cacheTime);
        
        // Cache expires after 1 hour
        if (difference.inHours >= 1) {
          AppLogger.debug('Profile cache expired');
          await clearCachedProfile();
          return null;
        }
      }

      final profileData = localStorage.getJson(_profileKey);
      if (profileData == null) {
        AppLogger.debug('No cached profile found');
        return null;
      }

      AppLogger.debug('Retrieved cached profile');
      return ProfileModel.fromJson(profileData);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached profile', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> cacheProfile(ProfileModel profile) async {
    try {
      await localStorage.setJson(_profileKey, profile.toJson());
      await localStorage.setString(_profileTimestampKey, DateTime.now().millisecondsSinceEpoch.toString());
      AppLogger.debug('Profile cached successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache profile', e, stackTrace);
    }
  }

  @override
  Future<void> clearCachedProfile() async {
    try {
      await localStorage.remove(_profileKey);
      await localStorage.remove(_profileTimestampKey);
      AppLogger.debug('Cached profile cleared');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear cached profile', e, stackTrace);
    }
  }
}

