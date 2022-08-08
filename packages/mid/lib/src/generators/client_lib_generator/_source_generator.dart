import 'package:mid/src/generators/endpoints_generator/_models.dart';

class ClientLibSourceGenerator {
  final List<ClassInfo> routes;

  /// holds a Set of non-dart types in order to serialize them for the client
  /// 
  /// This set is populated during generation  
  final nonDartTypes = <TypeInfo>{};
  
  
  ClientLibSourceGenerator(
    this.routes,
  );
}
