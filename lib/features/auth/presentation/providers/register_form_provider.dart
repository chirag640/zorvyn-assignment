import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Register form state
class RegisterFormState {
  const RegisterFormState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  RegisterFormState copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    String? nameError,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return RegisterFormState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      nameError: nameError,
      emailError: emailError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }

  bool get isValid =>
      name.isNotEmpty &&
      email.isNotEmpty &&
      password.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      nameError == null &&
      emailError == null &&
      passwordError == null &&
      confirmPasswordError == null;
}

/// Register form notifier
class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
  RegisterFormNotifier() : super(const RegisterFormState());

  void setName(String name) {
    state = state.copyWith(name: name, nameError: null);
  }

  void setEmail(String email) {
    state = state.copyWith(email: email, emailError: null);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, passwordError: null);
  }

  void setConfirmPassword(String confirmPassword) {
    state = state.copyWith(
        confirmPassword: confirmPassword, confirmPasswordError: null);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleConfirmPasswordVisibility() {
    state =
        state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword);
  }

  bool validate() {
    String? nameError;
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;

    if (state.name.isEmpty) {
      nameError = 'Name is required';
    }

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

    if (state.confirmPassword.isEmpty) {
      confirmPasswordError = 'Please confirm your password';
    } else if (state.password != state.confirmPassword) {
      confirmPasswordError = 'Passwords do not match';
    }

    state = state.copyWith(
      nameError: nameError,
      emailError: emailError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
    );

    return nameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmPasswordError == null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void reset() {
    state = const RegisterFormState();
  }
}

/// Provider for register form state
final registerFormProvider = StateNotifierProvider.autoDispose<
    RegisterFormNotifier, RegisterFormState>((ref) {
  return RegisterFormNotifier();
});

