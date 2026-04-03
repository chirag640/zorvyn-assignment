import '../repositories/auth_repository.dart';

/// Use case for user logout
class LogoutUsecase {
  LogoutUsecase(this._repository);

  final AuthRepository _repository;

  /// Execute logout
  Future<void> call({bool allSessions = false}) async {
    await _repository.logout(allSessions: allSessions);
  }
}
