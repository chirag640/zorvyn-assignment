import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_info_tile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardRadius = BorderRadius.circular(context.rRadius(24));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.editProfile);
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final success = await ref.read(authProvider.notifier).logout();
              if (!context.mounted) {
                return;
              }

              if (!success) {
                final message = ref.read(authProvider).error ??
                    'Unable to logout right now.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
                return;
              }

              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.login,
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(profileProvider.notifier).refreshProfile();
        },
        child: profileState.isLoading && profile == null
            ? const Center(child: CircularProgressIndicator())
            : profileState.error != null && profile == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: context.rIcon(64),
                          color: colorScheme.error,
                        ),
                        SizedBox(height: context.rs(16)),
                        Text(
                          'Error: ${profileState.error}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                        SizedBox(height: context.rs(16)),
                        FilledButton.tonal(
                          onPressed: () {
                            ref.read(profileProvider.notifier).refreshProfile();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(context.rs(16)),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            context.rs(20),
                            context.rs(24),
                            context.rs(20),
                            context.rs(20),
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.1),
                                colorScheme.surface,
                              ],
                            ),
                            borderRadius: cardRadius,
                            border: Border.all(
                              color:
                                  colorScheme.outline.withValues(alpha: 0.22),
                              width: context.rThickness(1),
                            ),
                          ),
                          child: Column(
                            children: [
                              ProfileAvatar(
                                avatarUrl: profile?.avatar,
                                size: context.rs(120),
                                onTap: () {
                                  _showAvatarOptions(context, ref);
                                },
                              ),
                              SizedBox(height: context.rs(18)),
                              Text(
                                profile?.name ?? 'Unknown User',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: context.rFont(26),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: context.rs(6)),
                              Text(
                                profile?.email ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: context.rs(18)),
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.editProfile,
                                  );
                                },
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: context.rIcon(18),
                                ),
                                label: const Text('Edit Profile'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: context.rs(20)),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: cardRadius,
                            border: Border.all(
                              color:
                                  colorScheme.outline.withValues(alpha: 0.22),
                              width: context.rThickness(1),
                            ),
                          ),
                          child: Column(
                            children: [
                              ProfileInfoTile(
                                icon: Icons.info_outline,
                                label: 'Bio',
                                value: profile?.bio ?? 'No bio yet',
                              ),
                              Divider(
                                height: context.rs(1),
                                color:
                                    colorScheme.outline.withValues(alpha: 0.3),
                              ),
                              ProfileInfoTile(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: profile?.phone ?? 'Not set',
                              ),
                              Divider(
                                height: context.rs(1),
                                color:
                                    colorScheme.outline.withValues(alpha: 0.3),
                              ),
                              ProfileInfoTile(
                                icon: Icons.location_on_outlined,
                                label: 'Location',
                                value: profile?.location ?? 'Not set',
                              ),
                              Divider(
                                height: context.rs(1),
                                color:
                                    colorScheme.outline.withValues(alpha: 0.3),
                              ),
                              ProfileInfoTile(
                                icon: Icons.calendar_today_outlined,
                                label: 'Joined',
                                value: profile?.joinedDate != null
                                    ? _formatDate(profile!.joinedDate!)
                                    : 'Unknown',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  void _showAvatarOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // In a real app, open camera
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Camera not implemented in demo')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // In a real app, open gallery
                ref.read(profileProvider.notifier).uploadAvatar('demo_path');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
