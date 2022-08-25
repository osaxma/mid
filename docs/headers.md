# Headers

## Request ID header
Each request sent by the client will include a unique request id in its headers (i.e. with `X-Request-ID` key). The server will also include this id into the response. When creating interceptors on the server side, the request id is available as a getter in both request and response (i.e. `request.requestID` or `response.requestID`). These getters are an extension on both `Request` and `Response` types from the `shelf` package. 

## Authentication Headers
As it was mentioned in the [client documentation][], `mid` in itself is unaware of Authentication. Therefore, it's the responsiblity of the server interceptors to verify requests headers for access control to resources. All http requests can be handled using `HttpInterceptorServer`*, wherease websocket connections should be verifed using `MessagesInterceptorServer`. 

> \* When the client tries to establish a websocket connection, an http request is sent to the server to be upgraded to a websocket connection. This request is sent by the `web_socket_channel` package and the headers are not from the client nor can they be intercepted by the client.

Once a client establishes a websocket connection, the client will immediately send a [ConnectionInitMessage][] which will contain a [ConnectionPayload][] which will contain any headers provided by the client (e.g. `Client.initialHeaders`). It's the responsiblity of the `messagesInterceptors` to inspect and verify these headers and return an [ErrorMessage][] message for unauthorized connections. Similarly, throughout the lifetime of the websocket connection, the client is expeted to send a [ConnectionUpdateMessage][] that will contain a [ConnectionPayload][] which contains updated headers.

Note, the [ConnectionInitMessage][] and [ConnectionUpdateMessage][] are constructed by the `mid_client` internally as well as adding the headers to the [ConnectionPayload][]. The client will use either the `Client.initialHeaders` that were provided upon instantiation, or use the latest ones provided by `FooClient.updateHeaders(newHeaders)` if it was invoked before establishing the connection. 

The following is a simple server message interceptor example to clarify the picture:

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

As you can see above, the headers are provided for each `clientMessage` and they are stored in the server and will be updated once a [ConnectionUpdateMessage][] is received when `FooClient.updateHeaders(newHeaders)` is invoked by the client. 

[client documentation]: https://github.com/osaxma/mid/blob/main/docs/client.md
[ConnectionInitMessage]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart
[ConnectionUpdateMessage]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart
[ConnectionPayload]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart
[ErrorMessage]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart