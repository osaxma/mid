import 'dart:convert';
import 'package:mid_auth/src/models/user_data.dart';
import 'package:meta/meta.dart';

/// A model represents an active session for a [User].
///
/// The model contains the [accessToken] (e.g., JWT), the [refreshToken],
/// the [expiryTime] of the [accessToken] and the [user] of the session.
@immutable
class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiryTime,
    required this.user,
  });

  /// The access token of the given [user]
  ///
  /// e.g. JWT (Json Web Token)
  final String accessToken;

  /// The token that can be used to refresh the session
  final String refreshToken;

  /// The expiry time of the [accessToken]
  final DateTime expiryTime;

  /// The user of this [accessToken]
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
      'expiry_time': expiryTime.toUtc().toIso8601String(),
      'user': user.toMap(),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    // DateTime is stored as toUtc().toIso8601String() tho when retrieved from SQLite, the timezone isn't there
    // so we add `Z` at the end to indicate it's a Zero UTC offset
    String expiryTime = map['expiry_time'];
    if (!expiryTime.endsWith('Z')) {
      expiryTime = '${expiryTime}Z';
    }

    return Session(
      accessToken: map['access_token'] as String,
      refreshToken: map['refresh_token'] as String,
      expiryTime: DateTime.parse(expiryTime),
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
