# Server 

When creating a new `mid` project (e.g. named `foo` ), a server entrypoint is placed within `foo_server/bin/server.dart`. This file is created only once upon project initialization and the file is meant to be configrable using [`ServerConfig`][]. The file would look something like this:

```dart
Future<void> main(List<String> args) async {
  final serverConfig = ServerConfig(
    handlers: getHandlers(await getEndPoints()), 
    middlewares: getMiddlewares(), 
    messagesInterceptors:  [] // <~~ Messages Interceptors can be added here
    // all the following are the shelf http server arguments:
    address: InternetAddress.anyIPv4,
    port: int.parse(Platform.environment['PORT'] ?? '8000'),
    // securityContext:
    // shared:
    // backlog
  );

  midServer(serverConfig);
}
```

[`ServerConfig`]: https://github.com/osaxma/mid/blob/main/packages/mid_server/lib/src/config.dart 

In the code snippet above, we can see that `getHandlers` and `getEndPoints`. The `getHandlers` retrieves a set of handlers that were generated based on the provided `EndPoints` at `getEndPoints` function. Once `mid generate all` is executed, the handlers are placed within `foo_server/lib/mid/generated/handlers.dart`. When the file is inspected, two types of handlers may be found: [`FutureOrBaseHandler`] and [`StreamBaseHandler`]. As their names suggest, one handles Future or non-Future endpoints whereas the other handles streaming endpoints. 

[`FutureOrBaseHandler`]: https://github.com/osaxma/mid/blob/main/packages/mid_server/lib/src/handlers.dart
[`StreamBaseHandler`]: https://github.com/osaxma/mid/blob/main/packages/mid_server/lib/src/handlers.dart


Both `interceptors` and `middlewares` are discussed in more details at the [interceptors documentation][] page. The rest of the arguments are based on the [shelf][] server arguments which are also documented within [HttpServer.bind][] or [HttpServer.bindSecure][].

[interceptors documentation]: https://github.com/osaxma/mid/blob/main/docs/interceptors.md
[shelf]: https://pub.dev/packages/shelf
[HttpServer.bind]: https://api.dart.dev/stable/2.17.7/dart-io/HttpServer/bind.html
[HttpServer.bindSecure]: https://api.dart.dev/stable/2.17.7/dart-io/HttpServer/bindSecure.html


## Authentication Headers
As it was mentioned in the [client documentation][], `mid` in itself is unaware of Authentication. Therefore, it's the responsiblity of the middlewares/interceptors to verify requests headers for access control to resources. All http requests can be handled using `middlewares`*, wherease websocket connections should be verifed using `messagesInterceptors`. 

> \* When the client tries to establish a websocket connection, an http request is sent to the server to be upgraded to a websocket connection. This request is sent by the `web_socket_channel` package and the headers are not from the client nor can they be intercepted by the client. Therefore, any middlewares should skip the `/ws` route. 

Once a client establishes a websocket connection, the client will immediately send a [`ConnectionInitMessage`][] which will contain a [`ConnectionPayload`][] which will contain any headers provided by the client. It's the responsiblity of the `messagesInterceptors` to inspect and verify these headers and return an [`ErrorMessage`][] message for unauthorized connections. Similarly, throughout the lifetime of the websocket connection, the client is expeted to send a [`ConnectionUpdateMessage`][] that will contain a [`ConnectionPayload`][] which contains updated headers (note: `FooClient.updateHeaders(newHeaders)` is used to send such a message which is constructed internally by `mid_client`). The following is a simple example to clarify the picture:

```dart
class AuthInterceptor extends MessageInterceptor {
  @override // intercept messages from client to server
  Message clientMessage(Message message) {
    if (message is ConnectionInitMessage || message is ConnectionUpdateMessage) {
      final isVerified = auth.verifyToken(message.payload as ConnectionPayload);
      if (isVerified) {
        return message;
      } else {
        return ErrorMessage(
          id: defaultErrorID,
          payload: ErrorPayload(errorCode: -1, errorMessage: 'Invalid Token'),
        );
      }
    }
    return message;
  }
}
```

[client documentation]: https://github.com/osaxma/mid/blob/main/docs/interceptors.md
[`ConnectionInitMessage`]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart
[`ConnectionUpdate`]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart
[`ConnectionPayload`]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart
[client documentation]: https://github.com/osaxma/mid/blob/main/docs/interceptors.md