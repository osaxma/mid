/// The types of messages that can be sent from the server to the client or vice versa
///
/// Each type has a specific direction:
///   - Server --> Client
///   - Client --> Server
///   - Bidrectional (both of the above)
///
/// See the documentation above each type for more details.
///
/// Inspired by: [GraphQL over WebSocket Protocol][]
///
/// [GraphQL over WebSocket Protocol]: https://github.com/enisdenjo/graphql-ws/blob/master/PROTOCOL.md
enum MessageType {
  /// Direction: bi-directional
  ///
  /// When either the server or the client receives a [ping],
  /// the receiver should respond with a [pong] as soon as possible
  ping,

  /// Direction: bi-directional
  ///
  /// a response to a [ping].
  pong,

  /// Direction: Client --> Server
  ///
  /// Once the websocket connection is established, the client
  /// must send a [connectionInit] to initialize communication.
  ///
  /// The server will terminate the connection if [connectionInit]
  /// was not received within a several seconds after the connection
  /// was established.
  connectionInit,

  /// Direction: Client --> Server
  ///
  /// Updates the existing connections headers
  ///
  /// The main use case is updating Authentication headers
  /// before they expire to prevent terminating any live
  /// subscription or terminating the entire connection.
  connectionUpdate,

  /// Direction: Server --> Client
  ///
  /// a response to a [connectionInit] and [connectionUpdate]. 
  connectionAcknowledge,

  /// Direction: Client --> Server
  ///
  /// Subscribe to a stream endpoint
  subscribe,

  /// Direction: Client --> Server
  ///
  /// stop a subscription to a stream endpoint
  stop,

  /// Direction: Server --> Client
  ///
  /// Indicates that a subscription was complete.
  /// This event is either sent after the last event
  /// [subscribe] of a stream, or after a [stop] message.
  complete,

  /// Direction: Server --> Client
  ///
  /// a response containing a data payload for an active subscription
  /// or an [endpoint] call
  data,

  /// Direction: Server --> Client
  ///
  /// a response containing an error payload for an active subscription
  /// or an [endpoint] call.
  ///
  /// Depending on the error, an active subscription may be terminated.
  /// Or the entire websocket connection will be terminated (e.g. invalid auth).
  error,

  /// Direction: Client --> Server
  ///
  /// A one time call to an endpoint.
  ///
  /// The server will either respond with [data] or [error]
  /// based on the endpoint actual result.
  endpoint;

  /// Returns a [MessageType] from a string representing [Enum.name]
  ///
  /// Returns `null` if [name] has no matches.
  static MessageType? fromName(String name) {
    for (final v in MessageType.values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
