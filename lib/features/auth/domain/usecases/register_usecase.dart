import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for user registration
class RegisterUsecase {
  RegisterUsecase(this._repository);

  final AuthRepository _repository;

  /// Execute registration
  Future<UserEntity> call({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _repository.register(
      email: email,
      password: password,
      name: name,
    );
  }
}

