import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for user login
class LoginUsecase {
  LoginUsecase(this._repository);

  final AuthRepository _repository;

  /// Execute login
  Future<UserEntity> call({
    required String email,
    required String password,
  }) async {
    return await _repository.login(
      email: email,
      password: password,
    );
  }
}

