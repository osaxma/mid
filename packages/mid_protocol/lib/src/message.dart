import 'dart:convert';

import 'message_type.dart';

/// The base class representing a message in mid websocket protocol
///
/// Each [MessageType] has its own [Message] with a specific payload type
/// Some [MessageType] such as `ping` and `pong` share the same type
/// i.e. NoPayLoadMessage
///
abstract class Message {
  const Message();
  String get id;
  MessageType get type;
  Object? get payload => null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'payload': payload,
      };

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'Message(id: $id, type: $type, payload: $payload)';
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    final type = map['type'];
    if (map['type'] == null || map['type'] is! String) {
      throw Exception('"Message.fromMap failed due to unkown MessageType -- type $type');
    }

    final messageType = MessageType.fromName(type);
    if (messageType == null) {
      throw Exception('"Message.fromMap failed due to unkown MessageType -- type $type');
    }

    try {
      switch (messageType) {
        case MessageType.ping:
          return PingMessage();
        case MessageType.pong:
          return PongMessage();
        case MessageType.connectionInit:
          return ConnectionInitMessage.fromMap(map);
        case MessageType.connectionUpdate:
          return ConnectionUpdateMessage.fromMap(map);
        case MessageType.connectionAcknowledge:
          return ConnectionAcknowledgeMessage();
        case MessageType.subscribe:
          return SubscribeMessage.fromMap(map);
        case MessageType.stop:
          return StopMessage(id: map['id']);
        case MessageType.complete:
          return CompleteMessage(id: map['id']);
        case MessageType.data:
          return DataMessage.fromMap(map);
        case MessageType.error:
          return ErrorMessage.fromMap(map);
        case MessageType.endpoint:
          return EndpointMessage.fromMap(map);
      }
    } catch (e) {
      throw Exception('Message.fromMap failed to parse the following map\n$map\ndue to the following error:\n$e');
    }
  }
  factory Message.fromJson(String source) => Message.fromMap(json.decode(source));
}

/* -------------------------------------------------------------------------- */
/*                                  ping pong                                 */
/* -------------------------------------------------------------------------- */

class PingMessage extends Message {
  const PingMessage();

  @override
  String get id => type.name;

  @override
  final MessageType type = MessageType.ping;
}

class PongMessage extends Message {
  const PongMessage();

  @override
  String get id => type.name;

  @override
  final MessageType type = MessageType.ping;
}

/* -------------------------------------------------------------------------- */
/*                               connection                                   */
/* -------------------------------------------------------------------------- */

class ConnectionInitMessage extends Message {
  @override
  final ConnectionPayload payload;

  const ConnectionInitMessage({required this.payload});

  @override
  String get id => type.name;

  @override
  MessageType get type => MessageType.connectionInit;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload.toMap(),
    };
  }

  factory ConnectionInitMessage.fromMap(Map<String, dynamic> map) {
    return ConnectionInitMessage(
      payload: ConnectionPayload.fromMap(map['payload']),
    );
  }
}

class ConnectionUpdateMessage extends Message {
  @override
  final ConnectionPayload payload;

  const ConnectionUpdateMessage({required this.payload});

  @override
  String get id => type.name;

  @override
  MessageType get type => MessageType.connectionUpdate;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload.toMap(),
    };
  }

  factory ConnectionUpdateMessage.fromMap(Map<String, dynamic> map) {
    return ConnectionUpdateMessage(
      payload: ConnectionPayload.fromMap(map['payload']),
    );
  }
}

class ConnectionPayload {
  final Map<String, String> headers;
  ConnectionPayload({required this.headers});

  Map<String, dynamic> toMap() {
    return {
      'headers': headers,
    };
  }

  factory ConnectionPayload.fromMap(Map<String, dynamic> map) {
    return ConnectionPayload(
      headers: Map<String, String>.from(map['headers']),
    );
  }

  @override
  String toString() => 'ConnectionPayload(headers: $headers)';
}

class ConnectionAcknowledgeMessage extends Message {
  const ConnectionAcknowledgeMessage();
  @override
  String get id => type.name;

  @override
  MessageType get type => MessageType.connectionAcknowledge;
}

/* -------------------------------------------------------------------------- */
/*                                    error                                   */
/* -------------------------------------------------------------------------- */

/// used when no message id is present
const defaultErrorID = 'error';
const defaultConnectionErrorID = 'connectionError';

class ErrorMessage extends Message {
  @override
  final String id;
  @override
  final ErrorPayload payload;

  final bool isConnectionError;

  const ErrorMessage({
    required this.id,
    required this.payload,
    this.isConnectionError = false,
  });

  @override
  MessageType get type => MessageType.error;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'isConnectionError': isConnectionError,
      'payload': payload.toMap(),
    };
  }

  factory ErrorMessage.fromMap(Map<String, dynamic> map) {
    return ErrorMessage(
      id: map['id'],
      isConnectionError: map['isConnectionError'],
      payload: ErrorPayload.fromMap(map['payload']),
    );
  }
}

class ErrorPayload {
  final int errorCode;
  final String errorMessage;
  ErrorPayload({
    required this.errorCode,
    required this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'errorCode': errorCode,
      'errorMessage': errorMessage,
    };
  }

  factory ErrorPayload.fromMap(Map<String, dynamic> map) {
    return ErrorPayload(
      errorCode: map['errorCode'],
      errorMessage: map['errorMessage'],
    );
  }

  @override
  String toString() => 'ErrorPayload(errorCode: $errorCode, errorMessage: $errorMessage)';
}

/* -------------------------------------------------------------------------- */
/*                                  subscribe                                 */
/* -------------------------------------------------------------------------- */

class SubscribeMessage extends Message {
  const SubscribeMessage({required this.id, required this.payload});

  @override
  final String id;

  @override
  final SubscribePayload payload;

  @override
  MessageType get type => MessageType.subscribe;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload.toMap(),
    };
  }

  factory SubscribeMessage.fromMap(Map<String, dynamic> map) {
    return SubscribeMessage(
      id: map['id'],
      payload: SubscribePayload.fromMap(map['payload']),
    );
  }
}

class SubscribePayload {
  final String route;
  final Map<String, dynamic> args;
  const SubscribePayload({required this.route, required this.args});

  Map<String, dynamic> toMap() {
    return {
      'route': route,
      'args': args,
    };
  }

  factory SubscribePayload.fromMap(Map<String, dynamic> map) {
    return SubscribePayload(
      route: map['route'],
      args: Map<String, dynamic>.from(map['args']),
    );
  }

  @override
  String toString() => 'SubscribePayload(route: $route, args: $args)';
}

/* -------------------------------------------------------------------------- */
/*                                    stop                                    */
/* -------------------------------------------------------------------------- */

class StopMessage extends Message {
  const StopMessage({required this.id});

  @override
  final String id;

  @override
  MessageType get type => MessageType.stop;
}

/* -------------------------------------------------------------------------- */
/*                                  complete                                  */
/* -------------------------------------------------------------------------- */

class CompleteMessage extends Message {
  const CompleteMessage({required this.id});

  @override
  final String id;

  @override
  MessageType get type => MessageType.complete;
}

/* -------------------------------------------------------------------------- */
/*                                    data                                    */
/* -------------------------------------------------------------------------- */

class DataMessage extends Message {
  const DataMessage({required this.id, required this.payload});

  @override
  final String id;

  /// The payload must be a json encoded string.
  @override
  final String payload;

  @override
  MessageType get type => MessageType.data;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload,
    };
  }

  factory DataMessage.fromMap(Map<String, dynamic> map) {
    return DataMessage(
      id: map['id'],
      payload: map['payload'],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                  endpoint                                  */
/* -------------------------------------------------------------------------- */

class EndpointMessage extends Message {
  const EndpointMessage({required this.id, required this.payload});

  @override
  final String id;

  @override
  final EndpointPayload payload;

  @override
  MessageType get type => MessageType.endpoint;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload.toMap(),
    };
  }

  factory EndpointMessage.fromMap(Map<String, dynamic> map) {
    return EndpointMessage(
      id: map['id'],
      payload: EndpointPayload.fromMap(map['payload']),
    );
  }
}

class EndpointPayload {
  final String route;
  final Map<String, dynamic> args;

  const EndpointPayload({required this.route, required this.args});

  Map<String, dynamic> toMap() {
    return {
      'route': route,
      'args': args,
    };
  }

  factory EndpointPayload.fromMap(Map<String, dynamic> map) {
    return EndpointPayload(
      route: map['route'],
      args: Map<String, dynamic>.from(map['args']),
    );
  }

  @override
  String toString() => 'EndpointPayload(route: $route, args: $args)';
}

final reservedMessageIDs = [
  ...MessageType.values.map((e) => e.name),
  defaultErrorID,
  defaultConnectionErrorID,
];
