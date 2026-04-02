import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/datasources/profile_local_data_source.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';

// Data Sources
final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSourceImpl(
    localStorage: ref.watch(localStorageProvider),
  );
});

// Repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    localDataSource: ref.watch(profileLocalDataSourceProvider),
  );
});

// Use Cases
final getProfileUsecaseProvider = Provider<GetProfileUsecase>((ref) {
  return GetProfileUsecase(ref.watch(profileRepositoryProvider));
});

final updateProfileUsecaseProvider = Provider<UpdateProfileUsecase>((ref) {
  return UpdateProfileUsecase(ref.watch(profileRepositoryProvider));
});

// Profile State
class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  final ProfileModel? profile;
  final bool isLoading;
  final String? error;

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Profile Notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this.ref) : super(const ProfileState()) {
    _loadProfile();
  }

  final Ref ref;

  Future<void> _loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final usecase = ref.read(getProfileUsecaseProvider);
      final profile = await usecase();
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshProfile() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final usecase = ref.read(getProfileUsecaseProvider);
      final profile = await usecase(forceRefresh: true);
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? phone,
    String? location,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final usecase = ref.read(updateProfileUsecaseProvider);
      final updatedProfile = await usecase(
        name: name,
        bio: bio,
        phone: phone,
        location: location,
      );
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final repository = ref.read(profileRepositoryProvider);
      final avatarUrl = await repository.uploadAvatar(filePath);

      // Update profile with new avatar
      final updatedProfile = state.profile?.copyWith(avatar: avatarUrl);
      if (updatedProfile != null) {
        final localDataSource = ref.read(profileLocalDataSourceProvider);
        await localDataSource.cacheProfile(updatedProfile);
      }

      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});
