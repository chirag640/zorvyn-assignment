import '../repositories/profile_repository.dart';
import '../../data/models/profile_model.dart';

class UpdateProfileUsecase {
  const UpdateProfileUsecase(this.repository);

  final ProfileRepository repository;

  Future<ProfileModel> call({
    String? name,
    String? bio,
    String? phone,
    String? location,
  }) {
    return repository.updateProfile(
      name: name,
      bio: bio,
      phone: phone,
      location: location,
    );
  }
}

