# Headers

## Request ID header
Each request sent by the client will include a unique request id in its headers (i.e. with `X-Request-ID` key). The server will also include this id into the response. When creating interceptors on the server side, the request id is available as a getter in both request and response (i.e. `request.requestID` or `response.requestID`). These getters are an extension on both `Request` and `Response` types from the `shelf` package. 

## Authentication Headers
As it was mentioned in the [client documentation][], `mid` in itself is unaware of Authentication. Therefore, it's the responsiblity of the middlewares/interceptors to verify requests headers for access control to resources. All http requests can be handled using `middlewares`*, wherease websocket connections should be verifed using `messagesInterceptors`. 

> \* When the client tries to establish a websocket connection, an http request is sent to the server to be upgraded to a websocket connection. This request is sent by the `web_socket_channel` package and the headers are not from the client nor can they be intercepted by the client. Therefore, any middlewares should skip the `/ws` route. 

Once a client establishes a websocket connection, the client will immediately send a [ConnectionInitMessage][] which will contain a [ConnectionPayload][] which will contain any headers provided by the client. It's the responsiblity of the `messagesInterceptors` to inspect and verify these headers and return an [ErrorMessage][] message for unauthorized connections. Similarly, throughout the lifetime of the websocket connection, the client is expeted to send a [ConnectionUpdateMessage][] that will contain a [ConnectionPayload][] which contains updated headers (note: `FooClient.updateHeaders(newHeaders)` is used to send such a message which is constructed internally by `mid_client`). The following is a simple example to clarify the picture:

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
```

[client documentation]: https://github.com/osaxma/mid/blob/main/docs/client.md
[ConnectionInitMessage]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart
[ConnectionUpdateMessage]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart
[ConnectionPayload]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart
[ErrorMessage]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart