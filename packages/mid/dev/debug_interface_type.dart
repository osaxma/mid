import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/common/utils.dart';

void main() async {
  final endpointsPath = getEndpointsPath('/Users/osaxma/Projects/mid/examples/simple/backend');

  final routes = await parseRoutes(endpointsPath);

  final m = routes.first.methodInfos.firstWhere((element) => element.methodElement.returnType is InterfaceType).methodElement;

  final types = findAllNonDartTypesFromMethodElement(m);
  print(types);
}
