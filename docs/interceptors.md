# Interceptors

Since a `mid` project is part a server project and another part a client project, there are interceptors for each side. In additon, given that `mid` runs both an http server for handling regular requests and a websocket server for handling streams, there are in total there four interceptors:

- [Server HTTP interceptor](#server-http-interceptor) (from `mid_server`)
- [Server Websocket Messages Interceptor](#server-websocket-messages-interceptor) (from `mid_server`)
- [Client HTTP interceptor](#client-http-interceptor) (from `mid_client`)
- [Client Websocket Messages Interceptor](#client-websocket-messages-interceptor) (from `mid_client`)


It's important to understand that if a server exposes both regular endpoints and stream endpoints, then handling authentication will require creating an `HttpInterceptorServer` and a `MessageInterceptorServer` to handle the authentication for http and websocket respectively. For more details, read the [headers][] documentation.

[headers]: https://github.com/osaxma/mid/blob/main/docs/headers.md


## Server Interceptors 

### Server HTTP interceptor

To intercept http requests and responses on the server side, the `mid_server` package provides an [HttpInterceptorServer][] type. The type is exported by the generated client library to facilitate its usage. The interceptor types can be imported from your frontend project as follow:
```dart
import 'package:<project_name>_server/interceptors.dart'; 
```

[HttpInterceptorServer]: https://github.com/osaxma/mid/blob/main/packages/mid_server/lib/src/interceptor.dart

Here are two simple examples for http interceptor on the server:

```dart
class VerifyTokenHttpInterceptor extends HttpInterceptorServer {
  @override
  Future<Request> onRequest(Request request) async {
    final token = request.headers['your-token-id'];
    final isVerified = auth.verifyToken(token);
    if (isVerified) {
      return request;
    } else {
      // `mid` will return this response to the client
      //  the response will also pass through the response interceptors
      throw Response(401, body: 'Invalid Token');
    }
  }
}


class HttpLogInterceptor extends HttpInterceptorServer {
  @override
  Future<Request> onRequest(Request request) async {
    print('--> request received from client for url: ${request.url}');
    return request;
  }

  @override
  Future<Response> onResponse(Response response) async {
    print('<-- resposne is being sent to the client with status: ${response.statusCode}');
    return response;
  }
}
```

You can add a list of `HttpInterceptorServer` in the `ServerConfig` located at:

```
|- <project_name>_server
        |- bin
            |- server.dart 
```

The interceptor(s) can be added to the `ServerConfig` (using [Quick Start Tutorial][] as an example) such as:

```dart
Future<void> main(List<String> args) async {
  final handlers = await getHandlers();
  final serverConfig = ServerConfig(
    handlers: handlers, 
    httpInterceptors: [VerifyTokenHttpInterceptor(), HttpLogInterceptor()], 
    address: InternetAddress.anyIPv4,
    port: int.parse(Platform.environment['PORT'] ?? '8000'),
  );

  midServer(serverConfig);
}
```


### Server Websocket Messages Interceptor

For streaming endpoints, the websocket messages between the server and client can be intercepted using [MessageInterceptorServer][] from the `mid_server` package which is automatically added to every generated server project. 

[MessageInterceptorServer]: https://github.com/osaxma/mid/blob/main/packages/mid_server/lib/src/interceptor.dart

Here are simple examples of messages interceptors:

```dart
class VerifyMessagesToken extends MessageInterceptorServer {
  @override // intercept messages from client to server
  Message clientMessage(Message message, Map<String, String> headers) {
   final token = headers['your-auth-token-id'];
   final isVerified = auth.verifyToken(token);
      if (isVerified) {
        return message;
      } else {
        return ErrorMessage(
          id: defaultErrorID,
          payload: ErrorPayload(errorCode: 401, errorMessage: 'Invalid Token'),
        );
      }
    return message;
  }
}


class LogInterceptor extends MessageInterceptorServer {
  @override // intercept messages from client to server
  Message clientMessage(Message message, Map<String, String> headers) {
    log(message);
    return message;
  }

  @override // intercept messages from server to client
  Message serverMessage(Message message) {
    if (message is ErrorMessage) {
      log.error(message.payload.errorMessage);
    } else {
      log.trace(message.toJson());
    }
    return message;
  }
}
```

You can add a list of `MessageInterceptorServer` in the `ServerConfig` located at:

```
|- <project_name>_server
        |- bin
            |- server.dart 
```

The interceptor(s) can be added to the `ServerConfig` (using [Quick Start Tutorial][] as an example) such as:

```dart
Future<void> main(List<String> args) async {
  final handlers = await getHandlers();
  final serverConfig = ServerConfig(
    handlers: handlers, 
    httpInterceptors: [VerifyTokenHttpInterceptor(), HttpLogInterceptor()], 
    messagesInterceptors: [LogInterceptor(), VerifyMessagesToken()], // <~~~ here
    address: InternetAddress.anyIPv4,
    port: int.parse(Platform.environment['PORT'] ?? '8000'),
  );

  midServer(serverConfig);
}
```
 


## Client Interceptors 

### Client HTTP Interceptor
To intercept http requests and responses on the client side, the `mid_client` package provides an [HttpInterceptorClient][] type. The type is exported by the generated client library to facilitate its usage. The interceptor types can be imported from your frontend project as follow:
```
import 'package:<project_name>_client/interceptors.dart'; 
```

[HttpInterceptorClient]: https://github.com/osaxma/mid/blob/main/packages/mid_client/lib/src/interceptor.dart

Here is an example http interceptor:

```dart
class AddAuthTokenInterceptor extends HttpInterceptorClient {
  @override
  Future<Request> onRequest(Request request) async {
    request.headers['your-auth-token-id'] = 'the-user-auth-token';
    return request;
  }
}
```

The interceptor(s) can be added to the client upon instantiation (using [Quick Start Tutorial][] as an example):

```dart
  final client = QuickStartClient(
    url: 'localhost:8000',
    httpInterceptors: [AddAuthTokenInterceptor()] // <~~~ here
  );
```

### Client Websocket Messages Interceptor

To intercept Messages on the client side, the [MessageInterceptorClient][] type can be used in the client side. 

[MessageInterceptorClient]: https://github.com/osaxma/mid/blob/main/packages/mid_client/lib/src/interceptor.dart

Taking the [Quick Start tutorial][] as an example, the interceptors can be added as follows:

```dart
  final client = QuickStartClient(
    url: 'localhost:8000',
    httpInterceptors: [AddAuthTokenInterceptor()], // i.e. http interceptor
    messageInterceptors: [ModifyMessagesInterceptor()] // <~~~ here
  );
```


[Quick Start Tutorial]: https://github.com/osaxma/mid/tree/main/tutorials/quick_start