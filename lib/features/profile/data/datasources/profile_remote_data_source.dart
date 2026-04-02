import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env_loader.dart';
import '../../../../core/supabase/supabase_service.dart';
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
  ProfileRemoteDataSourceImpl({
    required this.supabaseClient,
  });

  final SupabaseClient? supabaseClient;

  static const String _profilesTable = 'profiles';

  Future<SupabaseClient> _requireSupabaseClient() async {
    final client = supabaseClient ?? SupabaseService.client;
    if (client != null) {
      return client;
    }

    // Recover from stale null-client snapshots by reloading env and retrying init.
    await EnvLoader.load();
    await SupabaseService.initialize();

    final recovered = SupabaseService.client;
    if (recovered != null) {
      return recovered;
    }

    final hasUrl = EnvLoader.supabaseUrl.trim().isNotEmpty;
    final hasAnonKey = EnvLoader.supabaseAnonKey.trim().isNotEmpty;

    throw Exception(
      'Supabase client is unavailable. SUPABASE_URL set: $hasUrl, '
      'SUPABASE_ANON_KEY set: $hasAnonKey. Ensure .env is bundled in flutter '
      'assets and restart app after pubspec changes.',
    );
  }

  @override
  Future<ProfileModel> getProfile() async {
    final supabase = await _requireSupabaseClient();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      final response = await supabase
          .from(_profilesTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return _mapProfile(response);
      }

      final defaultName =
          (user.userMetadata?['name'] as String?)?.trim().isNotEmpty == true
              ? (user.userMetadata?['name'] as String).trim()
              : ((user.email ?? 'User').split('@').first);

      final inserted = await supabase
          .from(_profilesTable)
          .upsert(
            {
              'id': user.id,
              'email': user.email ?? '',
              'name': defaultName,
            },
            onConflict: 'id',
          )
          .select()
          .single();

      return _mapProfile(inserted);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch profile from Supabase', e, stackTrace);
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
    final supabase = await _requireSupabaseClient();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) data['name'] = name;
      if (bio != null) data['bio'] = bio;
      if (phone != null) data['phone'] = phone;
      if (location != null) data['location'] = location;

      final response = await supabase
          .from(_profilesTable)
          .update(data)
          .eq('id', user.id)
          .select()
          .maybeSingle();

      if (response != null) {
        return _mapProfile(response);
      }

      final inserted = await supabase
          .from(_profilesTable)
          .upsert(
            {
              'id': user.id,
              'email': user.email ?? '',
              'name': name ?? (user.email ?? 'User').split('@').first,
              if (bio != null) 'bio': bio,
              if (phone != null) 'phone': phone,
              if (location != null) 'location': location,
            },
            onConflict: 'id',
          )
          .select()
          .single();

      return _mapProfile(inserted);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update profile in Supabase', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    final supabase = await _requireSupabaseClient();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      final avatarUrl =
          'https://i.pravatar.cc/150?img=${DateTime.now().millisecondsSinceEpoch % 70}';

      await supabase.from(_profilesTable).upsert(
        {
          'id': user.id,
          'email': user.email ?? '',
          'avatar': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );

      return avatarUrl;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update avatar in Supabase', e, stackTrace);
      rethrow;
    }
  }

  ProfileModel _mapProfile(Map<String, dynamic> json) {
    return ProfileModel.fromJson({
      'id': json['id'],
      'email': json['email'],
      'name': json['name'],
      'avatar': json['avatar'],
      'bio': json['bio'],
      'phone': json['phone'],
      'location': json['location'],
      'joinedDate': json['created_at'] ?? json['joinedDate'],
    });
  }
}
