import 'package:client/client.dart' as client;
import 'package:client/src/auth.dart';

void main(List<String> arguments) async {
  final a = Auth(url: 'localhost:8080', headersProvider: () => {});

  final b = await a.signInWithEmailAndPassword('example@example.net', '123456');

  print(b);
}
