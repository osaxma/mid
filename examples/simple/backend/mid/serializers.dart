import 'package:mid_auth/src/models/session.dart';
import 'package:mid_auth/src/models/user_data.dart';

class SessionSerializer {
  static Map<String, dynamic> toMap(Session instance) {
    return {
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiryTime': instance.expiryTime.toUtc().toIso8601String(),
      'user': UserSerializer.toMap(instance.user),
    };
  }

  static Session fromMap(Map<String, dynamic> map) {
    return Session(
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String,
      expiryTime: DateTime.parse(map['expiryTime']),
      user: UserSerializer.fromMap(map['user']),
    );
  }
}

class UserSerializer {
  static Map<String, dynamic> toMap(User instance) {
    return {
      'id': instance.id,
      'email': instance.email,
      'createdAt': instance.createdAt.toUtc().toIso8601String(),
      'emailConfirmedAt': instance.emailConfirmedAt?.toUtc().toIso8601String(),
      'metadata': instance.metadata,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      email: map['email'] as String,
      createdAt: DateTime.parse(map['createdAt']),
      emailConfirmedAt: map['emailConfirmedAt'] == null ? null : DateTime.parse(map['emailConfirmedAt']),
      metadata: map['metadata'],
    );
  }
}
