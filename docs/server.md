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

In the code snippet above, we can see that `getHandlers` and `getEndPoints`. The `getHandlers` retrieves a set of handlers that were generated based on the provided `EndPoints` at `getEndPoints` function. Once `mid generate all` is executed, the handlers are placed within `foo_server/lib/mid/generated/handlers.dart`. When the file is inspected, two types of handlers may be found: [FutureOrBaseHandler][] and [StreamBaseHandler][]. As their names suggest, one handles Future or non-Future endpoints whereas the other handles streaming endpoints. 

[FutureOrBaseHandler]: https://github.com/osaxma/mid/blob/main/packages/mid_server/lib/src/handlers.dart
[StreamBaseHandler]: https://github.com/osaxma/mid/blob/main/packages/mid_server/lib/src/handlers.dart


Both `interceptors` and `middlewares` are discussed in more details at the [interceptors documentation][] page. The rest of the arguments are based on the [shelf][] server arguments which are also documented within [HttpServer.bind][] or [HttpServer.bindSecure][].

[interceptors documentation]: https://github.com/osaxma/mid/blob/main/docs/interceptors.md
[shelf]: https://pub.dev/packages/shelf
[HttpServer.bind]: https://api.dart.dev/stable/2.17.7/dart-io/HttpServer/bind.html
[HttpServer.bindSecure]: https://api.dart.dev/stable/2.17.7/dart-io/HttpServer/bindSecure.html


