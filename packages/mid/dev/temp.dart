import 'dart:convert';
import 'package:collection/collection.dart';

class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiryTime,
    required this.user,
  });

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String,
      expiryTime: DateTime.parse(map['expiryTime']),
      user: User.fromMap(map['user']),
    );
  }

  factory Session.fromJson(String source) => Session.fromMap(json.decode(source));

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

  String toJson() => json.encode(toMap());
  Map<String, dynamic> toMap() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiryTime': expiryTime.toUtc().toIso8601String(),
      'user': user.toMap(),
    };
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

  @override
  String toString() {
    return 'Session(accessToken: $accessToken, refreshToken: $refreshToken, expiryTime: $expiryTime, user: $user)';
  }
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.createdAt,
    this.emailConfirmedAt,
    required this.metadata,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      email: map['email'] as String,
      createdAt: DateTime.parse(map['createdAt']),
      emailConfirmedAt: map['emailConfirmedAt'] == null ? null : DateTime.parse(map['emailConfirmedAt']),
      metadata: map['metadata'],
    );
  }

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  final int id;

  final String email;

  final DateTime createdAt;

  final DateTime? emailConfirmedAt;

  final Map<String, dynamic> metadata;

  User copyWith({
    int? id,
    String? email,
    DateTime? createdAt,
    DateTime? emailConfirmedAt,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      emailConfirmedAt: emailConfirmedAt ?? this.emailConfirmedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  String toJson() => json.encode(toMap());
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'emailConfirmedAt': emailConfirmedAt?.toUtc().toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final collectionEquals = const DeepCollectionEquality().equals;

    return other is User &&
        other.id == id &&
        other.email == email &&
        other.createdAt == createdAt &&
        other.emailConfirmedAt == emailConfirmedAt &&
        collectionEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ createdAt.hashCode ^ emailConfirmedAt.hashCode ^ metadata.hashCode;
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, createdAt: $createdAt, emailConfirmedAt: $emailConfirmedAt, metadata: $metadata)';
  }
}