import 'package:mid_client/src/types.dart';

abstract class BaseClientRoute {
  Execute<Future<dynamic>> get httpExecute;
  Execute<Stream<dynamic>> get streamExecute;
}
