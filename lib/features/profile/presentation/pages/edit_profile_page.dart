import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_responsive.dart';
import '../../data/models/profile_model.dart';
import '../providers/profile_form_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_avatar.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;

  bool _seededProfile = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedFormFromProfile(ref.read(profileProvider).profile);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final formState = ref.watch(profileFormProvider);
    final profile = profileState.profile;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardRadius = BorderRadius.circular(context.rRadius(24));

    if (!_seededProfile && profile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _seedFormFromProfile(profile);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: profileState.isLoading ? null : () => _saveProfile(),
            child: Text(
              'Save',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(context.rs(16)),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: cardRadius,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.22),
                    width: context.rThickness(1),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  context.rs(16),
                  context.rs(24),
                  context.rs(16),
                  context.rs(20),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ProfileAvatar(
                          avatarUrl: profile?.avatar,
                          size: context.rs(120),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: colorScheme.primary,
                            radius: context.rs(20),
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                size: context.rIcon(20),
                              ),
                              color: colorScheme.onPrimary,
                              onPressed: () {
                                _showAvatarOptions();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.rs(24)),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter your name',
                        errorText: formState.errors['name'],
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      controller: _nameController,
                      onChanged: (value) {
                        ref.read(profileFormProvider.notifier).setName(value);
                      },
                    ),
                    SizedBox(height: context.rs(16)),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell us about yourself',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      controller: _bioController,
                      onChanged: (value) {
                        ref.read(profileFormProvider.notifier).setBio(value);
                      },
                      maxLines: 3,
                    ),
                    SizedBox(height: context.rs(16)),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        hintText: 'Enter your phone number',
                        errorText: formState.errors['phone'],
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      controller: _phoneController,
                      onChanged: (value) {
                        ref.read(profileFormProvider.notifier).setPhone(value);
                      },
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: context.rs(16)),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Enter your location',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      controller: _locationController,
                      onChanged: (value) {
                        ref
                            .read(profileFormProvider.notifier)
                            .setLocation(value);
                      },
                    ),
                    if (profileState.error != null) ...[
                      SizedBox(height: context.rs(16)),
                      Container(
                        padding: EdgeInsets.all(context.rs(12)),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(context.rRadius(12)),
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.3),
                            width: context.rThickness(1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.error,
                              size: context.rIcon(20),
                            ),
                            SizedBox(width: context.rs(8)),
                            Expanded(
                              child: Text(
                                profileState.error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _saveProfile() async {
    final formNotifier = ref.read(profileFormProvider.notifier);

    if (!formNotifier.validate()) {
      return;
    }

    final formState = ref.read(profileFormProvider);
    await ref.read(profileProvider.notifier).updateProfile(
          name: formState.name.isNotEmpty ? formState.name : null,
          bio: formState.bio.isNotEmpty ? formState.bio : null,
          phone: formState.phone.isNotEmpty ? formState.phone : null,
          location: formState.location.isNotEmpty ? formState.location : null,
        );

    final profileState = ref.read(profileProvider);
    if (!mounted) return;

    if (profileState.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    }
  }

  void _showAvatarOptions() {
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
                ref.read(profileProvider.notifier).uploadAvatar('demo_path');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _seedFormFromProfile(ProfileModel? profile) {
    if (profile == null || _seededProfile) {
      return;
    }

    _seededProfile = true;
    _nameController.text = profile.name;
    _bioController.text = profile.bio ?? '';
    _phoneController.text = profile.phone ?? '';
    _locationController.text = profile.location ?? '';

    ref.read(profileFormProvider.notifier).initialize(
          name: _nameController.text,
          bio: _bioController.text,
          phone: _phoneController.text,
          location: _locationController.text,
        );
  }
}
