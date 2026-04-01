import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Login form state
class LoginFormState {
  const LoginFormState({
    this.email = '',
    this.password = '',
    this.emailError,
    this.passwordError,
    this.obscurePassword = true,
  });

  final String email;
  final String password;
  final String? emailError;
  final String? passwordError;
  final bool obscurePassword;

  LoginFormState copyWith({
    String? email,
    String? password,
    String? emailError,
    String? passwordError,
    bool? obscurePassword,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: emailError,
      passwordError: passwordError,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }

  bool get isValid =>
      email.isNotEmpty &&
      password.isNotEmpty &&
      emailError == null &&
      passwordError == null;
}

/// Login form notifier
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier() : super(const LoginFormState());

  void setEmail(String email) {
    state = state.copyWith(email: email, emailError: null);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, passwordError: null);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  bool validate() {
    String? emailError;
    String? passwordError;

    if (state.email.isEmpty) {
      emailError = 'Email is required';
    } else if (!_isValidEmail(state.email)) {
      emailError = 'Invalid email format';
    }

    if (state.password.isEmpty) {
      passwordError = 'Password is required';
    } else if (state.password.length < 6) {
      passwordError = 'Password must be at least 6 characters';
    }

    state = state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
    );

    return emailError == null && passwordError == null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void reset() {
    state = const LoginFormState();
  }
}

/// Provider for login form state
final loginFormProvider =
    StateNotifierProvider.autoDispose<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier();
});

