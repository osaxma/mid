import 'dart:convert';
import 'package:mid_auth/src/models/user_data.dart';
import 'package:meta/meta.dart';

@immutable
class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiryTime,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiryTime;
  final User user;

  Session copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiryTime,
    User? user,
  }) {
    return Session(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiryTime: expiryTime ?? this.expiryTime,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expiry_time': expiryTime.millisecondsSinceEpoch,
      'user': user.toMap(),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      accessToken: map['access_token'] as String,
      refreshToken: map['refresh_token'] as String,
      expiryTime: DateTime.parse((map['expiry_time'] as String) + 'Z'),
      user: User.fromMap(map['user'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory Session.fromJson(String source) => Session.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Session(accessToken: $accessToken, refreshToken: $refreshToken, expiryTime: $expiryTime, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Session &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.expiryTime == expiryTime &&
        other.user == user;
  }

  @override
  int get hashCode {
    return accessToken.hashCode ^ refreshToken.hashCode ^ expiryTime.hashCode ^ user.hashCode;
  }
}
