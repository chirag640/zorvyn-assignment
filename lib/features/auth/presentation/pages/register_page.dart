import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../core/widgets/zorvyn_logo.dart';
import '../providers/auth_provider.dart';
import '../providers/register_form_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

/// Register page
class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final formState = ref.watch(registerFormProvider);
    final isSubmitting = authState.isSubmitting;
    final cardRadius = BorderRadius.circular(context.rRadius(28));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            context.rs(20),
            context.rs(16),
            context.rs(20),
            context.rs(24),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: context.rValue(
                mobile: double.infinity,
                tablet: 480,
                desktop: 520,
              )),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: context.rs(8)),
                  Align(
                    child: Container(
                      padding: EdgeInsets.all(context.rs(8)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(context.rRadius(22)),
                        border: Border.all(
                          color: AppColors.muted.withValues(alpha: 0.14),
                          width: context.rThickness(1),
                        ),
                      ),
                      child: const ZorvynLogo(size: 74),
                    ),
                  ),
                  SizedBox(height: context.rs(20)),
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.rs(8)),
                  Text(
                    'Set up your account and start building better habits.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.rs(28)),
                  AbsorbPointer(
                    absorbing: isSubmitting,
                    child: Container(
                      padding: EdgeInsets.all(context.rs(20)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: cardRadius,
                        border: Border.all(
                          color: AppColors.muted.withValues(alpha: 0.16),
                          width: context.rThickness(1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthTextField(
                            label: 'Full Name',
                            hintText: 'Enter your name',
                            value: formState.name,
                            errorText: formState.nameError,
                            onChanged: (value) {
                              ref
                                  .read(registerFormProvider.notifier)
                                  .setName(value);
                            },
                            prefixIcon: Icons.person_outline,
                          ),
                          SizedBox(height: context.rs(16)),
                          AuthTextField(
                            label: 'Email',
                            hintText: 'Enter your email',
                            keyboardType: TextInputType.emailAddress,
                            value: formState.email,
                            errorText: formState.emailError,
                            onChanged: (value) {
                              ref
                                  .read(registerFormProvider.notifier)
                                  .setEmail(value);
                            },
                            prefixIcon: Icons.email_outlined,
                          ),
                          SizedBox(height: context.rs(16)),
                          AuthTextField(
                            label: 'Password',
                            hintText: 'Enter your password',
                            value: formState.password,
                            errorText: formState.passwordError,
                            obscureText: formState.obscurePassword,
                            onChanged: (value) {
                              ref
                                  .read(registerFormProvider.notifier)
                                  .setPassword(value);
                            },
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: formState.obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            onSuffixIconTap: () {
                              ref
                                  .read(registerFormProvider.notifier)
                                  .togglePasswordVisibility();
                            },
                          ),
                          SizedBox(height: context.rs(16)),
                          AuthTextField(
                            label: 'Confirm Password',
                            hintText: 'Re-enter your password',
                            value: formState.confirmPassword,
                            errorText: formState.confirmPasswordError,
                            obscureText: formState.obscureConfirmPassword,
                            onChanged: (value) {
                              ref
                                  .read(registerFormProvider.notifier)
                                  .setConfirmPassword(value);
                            },
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: formState.obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            onSuffixIconTap: () {
                              ref
                                  .read(registerFormProvider.notifier)
                                  .toggleConfirmPasswordVisibility();
                            },
                          ),
                          if (authState.error != null) ...[
                            SizedBox(height: context.rs(14)),
                            Container(
                              padding: EdgeInsets.all(context.rs(12)),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(context.rRadius(14)),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.28),
                                  width: context.rThickness(1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(context).colorScheme.error,
                                    size: context.rIcon(18),
                                  ),
                                  SizedBox(width: context.rs(10)),
                                  Expanded(
                                    child: Text(
                                      authState.error!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: context.rs(20)),
                          AuthButton(
                            label: 'Register',
                            isLoading: isSubmitting,
                            onPressed: () async {
                              if (!ref
                                  .read(registerFormProvider.notifier)
                                  .validate()) {
                                return;
                              }

                              final success = await ref
                                  .read(authProvider.notifier)
                                  .register(
                                    formState.email,
                                    formState.password,
                                    formState.name,
                                  );

                              if (!success || !context.mounted) {
                                return;
                              }

                              final nextState = ref.read(authProvider);
                              if (nextState.isAuthenticated) {
                                Navigator.of(context)
                                    .pushReplacementNamed(AppRouter.home);
                                return;
                              }

                              if (nextState.isAwaitingEmailVerification) {
                                Navigator.of(context).pushReplacementNamed(
                                  AppRouter.verifyEmail,
                                  arguments: nextState.verificationEmail ??
                                      formState.email,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.rs(16)),
                  IgnorePointer(
                    ignoring: isSubmitting,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: context.rs(2),
                      children: [
                        Text(
                          'Already have an account?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushReplacementNamed(AppRouter.login);
                          },
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
