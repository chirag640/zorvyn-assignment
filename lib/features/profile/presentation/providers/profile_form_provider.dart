import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileFormState {
  const ProfileFormState({
    this.name = '',
    this.bio = '',
    this.phone = '',
    this.location = '',
    this.errors = const {},
  });

  final String name;
  final String bio;
  final String phone;
  final String location;
  final Map<String, String> errors;

  ProfileFormState copyWith({
    String? name,
    String? bio,
    String? phone,
    String? location,
    Map<String, String>? errors,
  }) {
    return ProfileFormState(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      errors: errors ?? this.errors,
    );
  }
}

class ProfileFormNotifier extends StateNotifier<ProfileFormState> {
  ProfileFormNotifier() : super(const ProfileFormState());

  void setName(String name) {
    state = state.copyWith(
      name: name,
      errors: {...state.errors}..remove('name'),
    );
  }

  void setBio(String bio) {
    state = state.copyWith(bio: bio);
  }

  void setPhone(String phone) {
    state = state.copyWith(
      phone: phone,
      errors: {...state.errors}..remove('phone'),
    );
  }

  void setLocation(String location) {
    state = state.copyWith(location: location);
  }

  void initialize({
    required String name,
    String? bio,
    String? phone,
    String? location,
  }) {
    state = ProfileFormState(
      name: name,
      bio: bio ?? '',
      phone: phone ?? '',
      location: location ?? '',
    );
  }

  bool validate() {
    final errors = <String, String>{};

    if (state.name.trim().isEmpty) {
      errors['name'] = 'Name is required';
    } else if (state.name.trim().length < 2) {
      errors['name'] = 'Name must be at least 2 characters';
    }

    if (state.phone.isNotEmpty && !_isValidPhone(state.phone)) {
      errors['phone'] = 'Invalid phone number';
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(errors: errors);
      return false;
    }

    return true;
  }

  bool _isValidPhone(String phone) {
    // Basic phone validation - allow digits, spaces, dashes, parentheses, and plus
    final phoneRegex = RegExp(r'^[\d\s\-()\+]+$');
    return phoneRegex.hasMatch(phone) && phone.replaceAll(RegExp(r'[^\d]'), '').length >= 10;
  }

  void reset() {
    state = const ProfileFormState();
  }
}

final profileFormProvider = StateNotifierProvider.autoDispose<ProfileFormNotifier, ProfileFormState>((ref) {
  return ProfileFormNotifier();
});

