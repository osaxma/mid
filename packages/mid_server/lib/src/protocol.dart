import 'dart:convert';

class Message {
  final String? id;
  final Object? payload;
  final MessageType type;
  const Message({
    this.id,
    this.payload,
    required this.type,
  });

  Message copyWith({
    String? id,
    Object? payload,
    MessageType? type,
  }) {
    return Message(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payload': payload,
      'type': type.name,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    final type = MessageType.fromName(map['type']);
    if (type == null) {
      throw Exception('Unknown MessageType');
    }
    return Message(
      id: map['id'],
      payload: map['payload'],
      type: type,
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) => Message.fromMap(json.decode(source));

  @override
  String toString() => 'Message(id: $id, payload: $payload, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message && other.id == id && other.payload == payload && other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ payload.hashCode ^ type.hashCode;
}

enum MessageType {
  ping, // Bi-directional
  pong, // Bi-directional
  connectionAcknowledge, // Server --> Client
  connectionInit, // Client --> Server
  updateHeaders, // Client --Server
  data, // Bi-directional
  error; // Server --> Client

  static MessageType? fromName(String name) {
    for (final v in MessageType.values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

// abstract class Payload {}

// class InitPayload extends Payload {
//   final String route;

//   InitPayload(this.route);
// }

// class DataPayload<T> extends Payload {
//   final T data;

//   DataPayload(this.data);
// }

// class ErrorPayload extends Payload {
//   final String errorMessage;

//   ErrorPayload(this.errorMessage);
// }
