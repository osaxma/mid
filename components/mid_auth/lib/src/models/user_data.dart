import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:meta/meta.dart';

@immutable
class User {
  const User({
    required this.id,
    required this.email,
    required this.createdAt,
    this.emailConfirmedAt,
    required this.metadata,
  });

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
    DateTime? lastSignInAt,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'created_at': createdAt.toUtc().toIso8601String(),
      'email_confirmed_at': emailConfirmedAt?.toUtc().toIso8601String(),
      'metadata': metadata,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    var emailConfirmedAt = map['email_confirmed_at'] as String?;
    if (emailConfirmedAt != null) {
      emailConfirmedAt = '${emailConfirmedAt}Z';
    }
    // metadata can be a raw json string
    var metadata = map['metadata'];
    if (metadata is String) {
      try {
        metadata = json.decode(metadata);
      } catch (e) {
        metadata = <String, dynamic>{};
      }
    }
    metadata ??= <String, dynamic>{};
    return User(
      id: map['id'] as int,
      email: map['email'] as String,
      createdAt: DateTime.parse((map['created_at'] as String) + 'Z'),
      emailConfirmedAt: DateTime.tryParse(emailConfirmedAt ?? ''),
      metadata: metadata as Map<String, dynamic>,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) {
    final decoded = Map<String, dynamic>.from(json.decode(source) as Map<dynamic, dynamic>);
    return User.fromMap(decoded);
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, createdAt: $createdAt, emailConfirmedAt: $emailConfirmedAt, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is User &&
        other.id == id &&
        other.email == email &&
        other.createdAt == createdAt &&
        other.emailConfirmedAt == emailConfirmedAt &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ createdAt.hashCode ^ emailConfirmedAt.hashCode ^ metadata.hashCode;
  }
}
