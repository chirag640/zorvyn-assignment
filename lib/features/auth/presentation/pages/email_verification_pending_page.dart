import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../providers/auth_provider.dart';

class EmailVerificationPendingPage extends ConsumerStatefulWidget {
  const EmailVerificationPendingPage({
    super.key,
    required this.email,
  });

  final String email;

  @override
  ConsumerState<EmailVerificationPendingPage> createState() =>
      _EmailVerificationPendingPageState();
}

class _EmailVerificationPendingPageState
    extends ConsumerState<EmailVerificationPendingPage> {
  late final TextEditingController _emailController;
  Timer? _cooldownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.rs(20)),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.rValue(
                  mobile: double.infinity,
                  tablet: 520,
                  desktop: 560,
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(context.rs(20)),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(context.rRadius(24)),
                  border: Border.all(
                    color: AppColors.muted.withValues(alpha: 0.18),
                    width: context.rThickness(1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.mark_email_unread_outlined,
                      size: context.rIcon(42),
                      color: AppColors.text,
                    ),
                    SizedBox(height: context.rs(12)),
                    Text(
                      'Verify your email',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: context.rs(10)),
                    Text(
                      'We created your account. Open your inbox and click the verification link before signing in.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                    SizedBox(height: context.rs(16)),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                    if (authState.error != null) ...[
                      SizedBox(height: context.rs(12)),
                      _MessageCard(
                        message: authState.error!,
                        color: Theme.of(context).colorScheme.error,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.10),
                      ),
                    ],
                    if (authState.infoMessage != null) ...[
                      SizedBox(height: context.rs(12)),
                      _MessageCard(
                        message: authState.infoMessage!,
                        color: const Color(0xFF1B8F4A),
                        backgroundColor: const Color(0xFFE9F8EF),
                      ),
                    ],
                    SizedBox(height: context.rs(16)),
                    FilledButton.icon(
                      onPressed: authState.isSubmitting || _secondsRemaining > 0
                          ? null
                          : _resendVerification,
                      icon: authState.isSubmitting
                          ? SizedBox(
                              width: context.rs(16),
                              height: context.rs(16),
                              child: CircularProgressIndicator(
                                strokeWidth: context.rThickness(2),
                                color: AppColors.background,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(
                        _secondsRemaining > 0
                            ? 'Resend in ${_secondsRemaining}s'
                            : 'Resend verification email',
                      ),
                    ),
                    SizedBox(height: context.rs(10)),
                    OutlinedButton(
                      onPressed:
                          authState.isSubmitting ? null : _continueAndAutoLogin,
                      child: Text(
                        authState.isSubmitting
                            ? 'Signing in...'
                            : 'I have verified, continue',
                      ),
                    ),
                    SizedBox(height: context.rs(6)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed(AppRouter.register);
                      },
                      child: const Text('Use a different email'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resendVerification() async {
    final email = _emailController.text.trim();
    final success =
        await ref.read(authProvider.notifier).resendSignupVerification(email);
    if (!mounted) {
      return;
    }

    if (success) {
      _startCooldown(const Duration(seconds: 60));
    }
  }

  Future<void> _continueAndAutoLogin() async {
    final success =
        await ref.read(authProvider.notifier).continueAfterEmailVerification();
    if (!mounted || !success) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRouter.home);
  }

  void _startCooldown(Duration duration) {
    _cooldownTimer?.cancel();
    setState(() {
      _secondsRemaining = duration.inSeconds;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
        return;
      }

      setState(() {
        _secondsRemaining -= 1;
      });
    });
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.color,
    required this.backgroundColor,
  });

  final String message;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.rs(12)),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(context.rRadius(14)),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
          width: context.rThickness(1),
        ),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
            ),
      ),
    );
  }
}
