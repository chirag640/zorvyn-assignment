import '../../../auth/domain/entities/user_entity.dart';
import '../../../../core/storage/local_storage.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.bio,
    this.phone,
    this.location,
    this.joinedDate,
  });

  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String? bio;
  final String? phone;
  final String? location;
  final DateTime? joinedDate;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      bio: json['bio']?.toString(),
      phone: json['phone']?.toString(),
      location: json['location']?.toString(),
      joinedDate: json['joinedDate'] != null
          ? DateTime.tryParse(json['joinedDate'].toString())
          : null,
    );
  }

  factory ProfileModel.fromUserEntity(UserEntity user) {
    return ProfileModel(
      id: user.id,
      email: user.email,
      name: user.name ?? '',
      avatar: user.avatar,
      bio: null,
      phone: null,
      location: null,
      joinedDate: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'phone': phone,
      'location': location,
      'joinedDate': joinedDate?.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    String? bio,
    String? phone,
    String? location,
    DateTime? joinedDate,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  Future<void> saveToCache(LocalStorage storage) async {
    await storage.setJson('cached_profile', toJson());
  }

  static Future<ProfileModel?> loadFromCache(LocalStorage storage) async {
    final data = storage.getJson('cached_profile');
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }
}

