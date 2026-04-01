import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case to get current authenticated user
class GetCurrentUserUsecase {
  GetCurrentUserUsecase(this._repository);

  final AuthRepository _repository;

  /// Execute get current user
  Future<UserEntity?> call() async {
    return await _repository.getCurrentUser();
  }
}

