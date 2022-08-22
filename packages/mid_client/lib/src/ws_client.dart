import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:mid_protocol/mid_protocol.dart';

class MidWebSocketClient {
  final Uri uri;

  final List<MessageInterceptor> interceptors;

  final List<EndPointStream> _activeStreams = [];

  late Map<String, String> _headers;

  void updateHeaders(Map<String, String> newHeaders) {
    _headers = {...newHeaders};
    _sendUpdateHeadersMessage();
  }

  MidWebSocketClient({
    required this.uri,
    required Map<String, String> headers,
    required this.interceptors,
  }) {
    updateHeaders(headers);
  }
  // TODO: this should be initted in a method for handling errors and retrying
  // TODO: create our own broadcast stream controller to pipe streams from ws to ctrl?
  //       this way a loss of connection can be handled independantly from controller
  //       i.e. we can retry to connect without closing any live subscription and such
  WebSocketChannel? _conn;

  void connect() {
    _conn = WebSocketChannel.connect(uri);
    // TODO: move this with connection init message
    _sendInitMessage();
    _sendUpdateHeadersMessage();
  }

  void close() async {
    await _conn?.sink.close(1000, 'Normal Closure');
    _conn = null;
  }

  // TODO: should this be <Message> instead and handle [MessageType.error] here?
  Stream<dynamic> get stream {
    if (_conn == null) {
      throw Exception('Websocket connection was not initialized');
    }
    return _conn!.stream;
  }

  Sink<dynamic> get sink {
    if (_conn == null) {
      throw Exception('Websocket connection was not initialized');
    }
    return _conn!.sink;
  }

  void _sendUpdateHeadersMessage() {
    // only update headers if there's an active connection
    if (_conn == null) {
      return;
    }

    _sendMessage(ConnectionUpdateMessage(payload: ConnectionPayload(headers: _headers)));
  }

  void _sendMessage(Message message) {
    if (_conn == null) {
      return;
    }
    // try/catch?
    message = _clientIntercept(message);
    sink.add(message.toJson());
  }

  void _sendInitMessage() async {
    try {
      // TODO: mamke [Message.id] required non-nullable
      // TODO: make timeout an option
      // TODO: use retry (`retry` pkg available) also make num of retries optional

      // cannot do this because the stream is single sub
      // await _getStream(initMsg.id!)
      //     .firstWhere((element) => element.type == MessageType.connectionAcknowledge)
      //     .timeout(Duration(seconds: 5));
      _sendMessage(ConnectionInitMessage(payload: ConnectionPayload(headers: _headers)));
    } catch (e) {
      // handle error.. this should inform all those who are subscribing to the _conn (that's why it's better to have our broadcast)
      print('init msg failed error $e');
    }
  }

  Message _clientIntercept(Message message) {
    return interceptors.fold(message, (previousValue, element) => element.clientMessage(message));
  }

  Message _serverIntercept(Message message) {
    return interceptors.fold(message, (previousValue, element) => element.serverMessage(message));
  }

  Stream<Message> _getStream(String messageID) {
    return stream.map((event) => Message.fromJson(event)).map(_serverIntercept).where((event) => event.id == messageID);
  }

  Stream<dynamic> executeStream(Map<String, dynamic> args, String route) {
    if (_conn == null) {
      connect();
    }

    final id = _generateRandomID(10);
    final subscribeMsg = SubscribeMessage(
      id: id,
      payload: SubscribePayload(args: args, route: route),
    );

    final stopMsg = StopMessage(
      id: id,
    );

    final endpointStream = EndPointStream(
      id: id,
      route: route,
      args: args,
      rootStream: _getStream(id),
    );

    endpointStream.onListen = () {
      _activeStreams.add(endpointStream);
      _sendMessage(subscribeMsg);
    };

    endpointStream.onCancel = () {
      _activeStreams.removeWhere((element) => element.id == endpointStream.id);
      _sendMessage(stopMsg);
    };

    return endpointStream.stream.map((event) => json.decode(event));
  }
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890-_';
final _randomGenerator = Random();
String _generateRandomID(int length) => String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(
          _randomGenerator.nextInt(_chars.length),
        ),
      ),
    );

class EndPointStream {
  final String id;
  final String route;
  final Map<String, dynamic> args;
  void Function()? onListen;
  void Function()? onCancel;
  final Stream<Message> rootStream;

  late final controller = StreamController<String>(onListen: _onListen, onCancel: _onCancel);
  StreamSubscription? _sub;

  EndPointStream({
    required this.id,
    required this.route,
    required this.args,
    required this.rootStream,
    this.onListen,
    this.onCancel,
  });

  Stream<String> get stream => controller.stream;
  // must add events indivisually. `controller.addStream` is limited (blocks stream).
  // that is, nothing can be added to stream nor can the stream be closed until the
  // addStream completes (see its docs).
  void _onListen() {
    _sub = mapStream(rootStream).listen(addEvent);
    _sub!.onError(addError);
    _sub!.onDone(_onCancel);
    onListen?.call();
  }

  void _onCancel() async {
    // this is causing an issue where the program does not exit :/
    // see: https://github.com/dart-lang/sdk/issues/49777
    // await _sub?.cancel();
    await controller.close();
    onCancel?.call();
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    if (!controller.isClosed) {
      controller.sink.addError(error, stackTrace);
    }
  }

  void addEvent(String event) {
    if (!controller.isClosed) {
      controller.sink.add(event);
    }
  }

  void handleComplete(Message message) {
    if (!controller.isClosed) {
      _onCancel();
    }
  }

  Stream<String> mapStream(Stream<Message> stream) => stream.where((event) {
        if (event.type == MessageType.error) {
          addError(Exception(event.payload));
          return false;
        } else if (event.type == MessageType.complete) {
          handleComplete(event);
          return false;
        }
        return true;
        // TODO: make sure the payload is a string first
        //       all streams data are encoded as json string in the server handlers.
      }).map((event) => event.payload as String);
  // maybe this should be handled at the endpoint handler itself
  // .map((event) => json.decode(event));
}
