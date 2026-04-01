import '../repositories/profile_repository.dart';
import '../../data/models/profile_model.dart';

class GetProfileUsecase {
  const GetProfileUsecase(this.repository);

  final ProfileRepository repository;

  Future<ProfileModel> call({bool forceRefresh = false}) {
    return repository.getProfile(forceRefresh: forceRefresh);
  }
}

