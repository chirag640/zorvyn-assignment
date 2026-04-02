import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
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
    final isSubmitting = authState.isSubmitting;
    final canOpenVerificationFlow =
        (authState.error ?? '').toLowerCase().contains('verify your email');
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
                      width: context.rs(74),
                      height: context.rs(74),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(context.rRadius(22)),
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: context.rIcon(36),
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  SizedBox(height: context.rs(20)),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.rs(8)),
                  Text(
                    'Sign in to continue managing your money with confidence.',
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
                            label: 'Email',
                            hintText: 'Enter your email',
                            keyboardType: TextInputType.emailAddress,
                            value: formState.email,
                            errorText: formState.emailError,
                            onChanged: (value) {
                              ref
                                  .read(loginFormProvider.notifier)
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
                                  .read(loginFormProvider.notifier)
                                  .setPassword(value);
                            },
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: formState.obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            onSuffixIconTap: () {
                              ref
                                  .read(loginFormProvider.notifier)
                                  .togglePasswordVisibility();
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
                            if (canOpenVerificationFlow) ...[
                              SizedBox(height: context.rs(8)),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppRouter.verifyEmail,
                                      arguments: formState.email,
                                    );
                                  },
                                  child: const Text(
                                    'Resend verification email',
                                  ),
                                ),
                              ),
                            ],
                          ],
                          SizedBox(height: context.rs(20)),
                          AuthButton(
                            label: 'Login',
                            isLoading: isSubmitting,
                            onPressed: () async {
                              if (!ref
                                  .read(loginFormProvider.notifier)
                                  .validate()) {
                                return;
                              }

                              final success =
                                  await ref.read(authProvider.notifier).login(
                                        formState.email,
                                        formState.password,
                                      );

                              if (success && context.mounted) {
                                Navigator.of(context)
                                    .pushReplacementNamed(AppRouter.home);
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
                          'Don\'t have an account?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushReplacementNamed(AppRouter.register);
                          },
                          child: const Text('Register'),
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
