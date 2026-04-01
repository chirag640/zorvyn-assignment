import 'user_model.dart';

/// Authentication response model from API
class AuthResponseModel {
  const AuthResponseModel({
    required this.user,
    required this.accessToken,
    this.refreshToken,
  });

  final UserModel user;
  final String accessToken;
  final String? refreshToken;

  /// Create from JSON
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken']?.toString() ?? json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
    };
  }
}

