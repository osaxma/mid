# Client 

When generating a client project, `mid` will generate both an http and websocket called wrapped under a class called `<ProjectName>Client` (e.g. `FooClient` for project `foo`). Unlike the server, the client does not have many configurations but it's important to know the client works. 

Assuming that the server was creating with two `EndPoints` classes (e.g. `Auth` and `Storage`), then the generated client would look like the following (located at `foo_client/lib/mid/client.dart`):

```dart
class FooClient extends BaseClient {
  // this will contain all the methods defined within the `EndPoints` of `Auth`
  late final auth = AuthRoute(executeHttp, executeStream);
  // this will contain all the methods defined within the `EndPoints` of `Storage`
  late final storage = StorageRoute(executeHttp, executeStream);

  FooClient({
    required super.url, // <~ the server URL
    super.initialHeaders, // <~ the initial headers to be sent with any requests 
    super.interceptors, // <~ http interceptors
    super.messageInterceptors, // <~ web socket messages interceptors
  });
}

@override // shown here for the sake of documentation only
void updateHeaders(Map<String, String> newHeaders) => super.updateHeaders(newHeaders); 
```

While everything in the class is pretty much self-explanatory or it has been document else where (i.e. see [interceptors docs][] for both interceptors), it's important to understand the purpose of `updateHeaders` especially when working with streaming endpoints. 

[interceptors docs]: https://github.com/osaxma/mid/blob/main/docs/interceptors.md

While http requests can be intercepted to change its headers, it's impossible to do the same for a websocket connection. When a websocket connection is first created, an http request* is sent that is later upgraded to a websocket connection.  


> \* the http request is not sent from the same http client of `FooClient` so it cannot be intercepted by `interceptors` since the connection is created using the [`web_socket_channels`] package and the package does not provide a way to even attach headers -- let alone intercepting the request. 

[`web_socket_channels`]: https://pub.dev/packages/web_socket_channel

Once a websocket connection is established, `mid_client` will automatically send a connection initialization message (i.e. [`ConnectionInitMessage`][]) including the `initialHeaders` or the latest available headers provided to `FooClient.updateHeaders`. 

Since in most cases the headers would include an expirable variable such as an Authentication Token, such headers needs to be updated especially during a live stream of an endpoint to prevent losing the connection. To do so, the user of `FooClient` must invoke `updateHeaders` with new valid headers before the token expires. In turn, `mid_client` would send a [`ConnectionUpdateMessage`][] to the server containing the newly provided headers. These headers are also cached for any subsequent http request as well as re-initialzing a websocket connection after it was closed\*.

> The websocket connection is only active when there are streaming endpoints. After all streams are closed, the websocket connection is closed and it's only reopened if a new stream is requested. 

Important Note: 
- `mid` in itself does not handle authentication and it's unaware of it. Therefore, `ConnectionInitMessage` & `ConnectionUpdateMessage`are expected to be intercepted by the server to verify the headers. See the [server documentation] for more details. 


[server documentation]: https://github.com/osaxma/mid/blob/main/docs/interceptors.md
[`ConnectionInitMessage`]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart
[`ConnectionUpdate`]: https://github.com/osaxma/mid/blob/main/packages/mid_protocol/lib/src/message.dart
