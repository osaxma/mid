# Interceptors

Since a `mid` project is part a server project and another part a client project, there are interceptors for each side. In additon, given that `mid` runs both an http server for handling regular requests and a websocket server for handling streams, there are interceptors for each. Therefore, in total there can be four interceptors:

- [Server HTTP interceptor](#server-http-interceptor) (from `mid_server`)
- [Server Websocket Messages Interceptor](#server-websocket-messages-interceptor) (from `mid_protocol`)
- [Client HTTP interceptor](#client-http-interceptor) (from `mid_client`)
- [Client Websocket Messages Interceptor](#client-websocket-messages-interceptor) (from `mid_protocol`)


## Server Interceptors 

### Server HTTP interceptor
At the time being, the HTTP server interceptors are not yet implemented. Though, the `Middleware` from the `shelf` package can be utilized instead. In order to create middlewares for intercepting http requests and responses, you can add such middlewares in the `mid` server project in the following file:

```
|- <project_name>_server
        |- mid
            |- middlewares.dart 
```

When the project is first created, the file includes an example middleware from the shelf package (i.e. `logRequests`).

> It's still unclear whether to keep using shelf's `Middleware` or use an interceptor pattern. The main difference is that interceptors will intercept requests and responses independently. Middelwares, on the other hand, can wait for the response after intercepting a request (look at [logRequests][] implementation)

[logRequests]: https://pub.dev/documentation/shelf/latest/shelf/logRequests.html

### Server Websocket Messages Interceptor

For streaming endpoints, the websocket messages between the server and client can be intercepted using [MessageInterceptor][] from the `mid_protocol` package which is automatically added to every `mid_server` project. 

You can add a list of `MessageInterceptor` in the `ServerConfig` located at:

```
|- <project_name>_server
        |- bin
            |- server.dart 
```

[MessageInterceptor]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message_interceptor.dart

An example interceptor would be:

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


class LogInterceptor extends MessageInterceptor {
  @override // intercept messages from client to server
  Message clientMessage(Message message) {
    log(message);
    return message;
  }

  @override // intercept messages from server to client
  Message serverMessage(Message message) {
    if (message is ErrorMessage) {
      log.error('error occured ${message.payload.errorMessage}');
    } else {
      log(message.toJson());
    }
    return message;
  }
}
```

Now both interceptors can be added to the `ServerConfig` within `bin/server.dart`:

```dart
Future<void> main(List<String> args) async {
  final serverConfig = ServerConfig(
    handlers: getHandlers(await getEndPoints()), 
    middlewares: getMiddlewares(), 
    messagesInterceptor: [LogInterceptor(), AuthInterceptor()], // <~~~ here
    address: InternetAddress.anyIPv4,
    port: int.parse(Platform.environment['PORT'] ?? '8000'),
  );

  midServer(serverConfig);
}
```
 


## Client Interceptors 

### Client HTTP Interceptor
To intercept http requests and responses on the client side, the `mid_client` package provides an [Interceptor][] type. The type is exported by the generated client library to facilitate its usage. The interceptor types can be imported from your frontend project as follow:
```
import 'package:<project_name>_client/interceptors.dart'; 
```

[Interceptor]: https://github.com/osaxma/mid/blob/main/packages/mid_client/lib/src/interceptor.dart

Here is an example http interceptor:

```dart
class HttpLogInterceptor extends Interceptor {
  @override
  Request onRequest(Request request) {
    print('--> request sent to ${request.url}');
    return request;
  }

  @override
  Response onResponse(Response response) {
    print('<-- resposne received with status: sent to ${response.statusCode}');
    // TODO: implement onResponse
    return response;
  }
}
```

The interceptor(s) can be added to the client upon instantiation (using [Quick Start Tutorial][] as an example):

```dart
  final client = QuickStartClient(
    url: 'localhost:8000',
    interceptors: [HttpLogInterceptor()] // <~~~ here
  );
```

### Client Websocket Messages Interceptor

To intercept Messages on the client side, the same [MessageInterceptor][] type used in the [Server Websocket Messages Interceptor](#server-websocket-messages-interceptor) can also be used in the client side. Similarly, `mid_protocol` is automatically added to the client project. 

[MessageInterceptor]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message_interceptor.dart

The only difference is that the interceptors are added to the generated client. Taking the [Quick Start tutorial][] as an example, the interceptors can be added as follows:

```dart
  final client = QuickStartClient(
    url: 'localhost:8000',
    interceptors: [HttpLogInterceptor()], // i.e. http interceptor
    messageInterceptors: [ModifyMessagesInterceptor()] // <~~~ here
  );
```


[Quick Start Tutorial]: https://github.com/osaxma/mid/tree/main/tutorials/quick_start