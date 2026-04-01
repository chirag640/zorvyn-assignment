import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_info_tile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (profile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.editProfile);
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // In a real app, you would call the logout functionality here
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
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${profileState.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        ProfileAvatar(
                          avatarUrl: profile?.avatar,
                          size: 120,
                          onTap: () {
                            // In a real app, this would open image picker
                            _showAvatarOptions(context, ref);
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          profile?.name ?? 'Unknown User',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 32),
                        Card(
                          child: Column(
                            children: [
                              ProfileInfoTile(
                                icon: Icons.info_outline,
                                label: 'Bio',
                                value: profile?.bio ?? 'No bio yet',
                              ),
                              const Divider(height: 1),
                              ProfileInfoTile(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: profile?.phone ?? 'Not set',
                              ),
                              const Divider(height: 1),
                              ProfileInfoTile(
                                icon: Icons.location_on_outlined,
                                label: 'Location',
                                value: profile?.location ?? 'Not set',
                              ),
                              const Divider(height: 1),
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
                  const SnackBar(content: Text('Camera not implemented in demo')),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

