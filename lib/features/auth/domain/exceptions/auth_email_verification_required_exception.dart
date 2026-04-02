class AuthEmailVerificationRequiredException implements Exception {
  const AuthEmailVerificationRequiredException({required this.email});

  final String email;

  @override
  String toString() =>
      'Email verification required for $email. Please verify your email and login.';
}
