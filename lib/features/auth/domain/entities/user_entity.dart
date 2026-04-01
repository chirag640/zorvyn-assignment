import 'package:equatable/equatable.dart';

/// User entity representing an authenticated user
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
  });

  final String id;
  final String email;
  final String? name;
  final String? avatar;

  @override
  List<Object?> get props => [id, email, name, avatar];
}

