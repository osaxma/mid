import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/common/utils.dart';
import 'package:mid/src/generators/client_lib_generator/serializer_client.dart';

void main() async {
  final endpointsPath = getEndpointsPath('/Users/osaxma/Projects/mid/examples/simple/simple_server');

  final routes = await parseRoutes(endpointsPath);

  final m =
      routes.first.methodInfos.firstWhere((element) => element.methodElement.returnType is InterfaceType).methodElement;

  final types = findAllNonDartTypesFromMethodElement(m);

  final serializer = ClientClassesSerializer(types: types);

  final genertedCode = serializer.generate();
  print(genertedCode);
}

