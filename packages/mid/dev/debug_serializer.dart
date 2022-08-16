import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/common/utils.dart';
import 'package:mid/src/generators/endpoints_generator/serializer_server.dart';

void main() async {
  final endpointsPath = getEndpointsPath('/Users/osaxma/Projects/mid/examples/simple/backend');

  final routes = await parseRoutes(endpointsPath);

  final m =
      routes.first.methodInfos.firstWhere((element) => element.methodElement.returnType is InterfaceType).methodElement;

  final types = findAllNonDartTypesFromMethodElement(m);

  final serializer = ServerClassesSerializer(types: types);

  final genertedCode = serializer.generateCode();
  print(genertedCode);
}

