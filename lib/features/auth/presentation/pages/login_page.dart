import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/login_form_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

/// Login page
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final formState = ref.watch(loginFormProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo or Title
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Email field
                AuthTextField(
                  label: 'Email',
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  value: formState.email,
                  errorText: formState.emailError,
                  onChanged: (value) {
                    ref.read(loginFormProvider.notifier).setEmail(value);
                  },
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),

                // Password field
                AuthTextField(
                  label: 'Password',
                  hintText: 'Enter your password',
                  value: formState.password,
                  errorText: formState.passwordError,
                  obscureText: formState.obscurePassword,
                  onChanged: (value) {
                    ref.read(loginFormProvider.notifier).setPassword(value);
                  },
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: formState.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixIconTap: () {
                    ref
                        .read(loginFormProvider.notifier)
                        .togglePasswordVisibility();
                  },
                ),
                const SizedBox(height: 24),

                // Error message
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Login button
                AuthButton(
                  label: 'Login',
                  isLoading: authState.isLoading,
                  onPressed: () async {
                    // Validate form
                    if (!ref.read(loginFormProvider.notifier).validate()) {
                      return;
                    }

                    // Perform login
                    final success = await ref.read(authProvider.notifier).login(
                          formState.email,
                          formState.password,
                        );

                    if (success && context.mounted) {
                      // Navigate to home on success
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/register');
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

