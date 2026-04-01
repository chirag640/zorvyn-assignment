import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_form_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_avatar.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).profile;
      if (profile != null) {
        ref.read(profileFormProvider.notifier).initialize(
              name: profile.name,
              bio: profile.bio,
              phone: profile.phone,
              location: profile.location,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final formState = ref.watch(profileFormProvider);
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: profileState.isLoading ? null : () => _saveProfile(),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      ProfileAvatar(
                        avatarUrl: profile?.avatar,
                        size: 120,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 20),
                            color: Colors.white,
                            onPressed: () {
                              _showAvatarOptions();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                      errorText: formState.errors['name'],
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    controller: TextEditingController(text: formState.name)
                      ..selection = TextSelection.collapsed(
                        offset: formState.name.length,
                      ),
                    onChanged: (value) {
                      ref.read(profileFormProvider.notifier).setName(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell us about yourself',
                      prefixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    controller: TextEditingController(text: formState.bio)
                      ..selection = TextSelection.collapsed(
                        offset: formState.bio.length,
                      ),
                    onChanged: (value) {
                      ref.read(profileFormProvider.notifier).setBio(value);
                    },
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      hintText: 'Enter your phone number',
                      errorText: formState.errors['phone'],
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    controller: TextEditingController(text: formState.phone)
                      ..selection = TextSelection.collapsed(
                        offset: formState.phone.length,
                      ),
                    onChanged: (value) {
                      ref.read(profileFormProvider.notifier).setPhone(value);
                    },
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Location',
                      hintText: 'Enter your location',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    controller: TextEditingController(text: formState.location)
                      ..selection = TextSelection.collapsed(
                        offset: formState.location.length,
                      ),
                    onChanged: (value) {
                      ref.read(profileFormProvider.notifier).setLocation(value);
                    },
                  ),
                  if (profileState.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              profileState.error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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
                  const SnackBar(content: Text('Camera not implemented in demo')),
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
}

