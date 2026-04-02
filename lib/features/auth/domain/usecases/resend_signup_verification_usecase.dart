import '../repositories/auth_repository.dart';

class ResendSignupVerificationUsecase {
  ResendSignupVerificationUsecase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email) {
    return _repository.resendSignupVerification(email);
  }
}
