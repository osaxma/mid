import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/common/analyzer.dart';

bool allArgumentsInUnnamedConstructorIsToThis(InterfaceType type) {
  final constructors = type.element.constructors.where((c) => c.isGenerative);

  if (constructors.isEmpty) {
    final name = type.getDisplayString(withNullability: false);
    final packageURI = type.element.librarySource.uri.toString();
    throw Exception('$name at does not have a generative constructor (package: $packageURI');
  }
  final constructor = constructors.first;

  constructor.parameters.any((p) => !p.isInitializingFormal);

  // [ParameterElement.isInitializingFormal] refers when a field is initialized using `this` keyword.
  return constructor.parameters.any((p) => !p.isInitializingFormal);
}

/// When [useToMapFromMap] is `true`, type.toMap() and Type.fromMap() (i.e. userData.toMap() & UserData.fromMap()).
/// When `false`, the Serializer is used (i.e. UserDataSerializer.toMap() & UserDataSerializer.fromMap()).
///
/// The first case is mainly used for the client side since it uses data classes whereas the second case is used
/// for the server since it uses the Serializer pattern.
String deserializeValue(DartType type, String value, {required bool useToMapFromMap}) {
  final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;
  final typeName = type.getDisplayString(withNullability: true);
  if (isBasicType(type) || type is! InterfaceType) {
    return '$value as $typeName';
  }

  if (isDateTime(type)) {
    if (isNullable) {
      return '$value == null ? null : DateTime.parse($value)';
    } else {
      return 'DateTime.parse($value)';
    }
  }

  if (isDuration(type)) {
    if (isNullable) {
      return '$value == null ? null : Duration(microseconds: $value)';
    } else {
      return 'Duration(microseconds: $value)';
    }
  }

  if (!isDartType(type)) {
    if (useToMapFromMap) {
      final className = type.getDisplayString(withNullability: false);
      if (isNullable) {
        return '$value == null ? null : $className.fromMap($value)';
      } else {
        return '$className.fromMap($value)';
      }
    } else {
      final serializerName = getSerializerName(type);
      if (isNullable) {
        return '$value == null ? null : $serializerName.fromMap($value)';
      } else {
        return '$serializerName.fromMap($value)';
      }
    }
  }

  if (type.isDartCoreList || type.isDartCoreSet) {
    if (type.typeArguments.isEmpty) {
      return value;
    }
    final t = type.typeArguments.first as InterfaceType;
    final listOrSet = type.isDartCoreList ? 'List' : 'Set';
    final typeArg =
        type.typeArguments.isEmpty ? '' : '<${type.typeArguments.first.getDisplayString(withNullability: true)} >';
    final v = deserializeValue(t, 'x', useToMapFromMap: useToMapFromMap);
    if (isNullable) {
      return "$value == null ? null : $listOrSet$typeArg.from($value.map((x) => $v))";
    } else {
      return "$listOrSet$typeArg.from($value.map((x) => $v))";
    }
  }

  if (type.isDartCoreMap) {
    if (type.typeArguments.isEmpty) {
      return value;
    }
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    if (isBasicType(keyType) && isBasicType(valueType)) {
      return value;
    } else {
      final k = deserializeValue(keyType, 'k', useToMapFromMap: useToMapFromMap);
      final v = deserializeValue(valueType, 'v', useToMapFromMap: useToMapFromMap);
      if (isNullable) {
        return "$value?.map((k, v) => MapEntry($k, $v))";
      } else {
        return "$value.map((k, v) => MapEntry($k, $v))";
      }
    }
  }
  throw UnimplementedError();
}

/// When [useToMapFromMap] is `true`, type.toMap() and Type.fromMap() (i.e. userData.toMap() & UserData.fromMap()).
/// When `false`, the Serializer is used (i.e. UserDataSerializer.toMap() & UserDataSerializer.fromMap()).
///
/// The first case is mainly used for the client side since it uses data classes whereas the second case is used
/// for the server since it uses the Serializer pattern.
String serializeValue(DartType type, String value, {required bool useToMapFromMap}) {
  final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;
  if (isBasicType(type) || type is! InterfaceType) {
    return value;
  }

  if (isDateTime(type)) {
    if (isNullable) {
      return '$value?.toUtc().toIso8601String()';
    } else {
      return '$value.toUtc().toIso8601String()';
    }
  }

  if (isDuration(type)) {
    if (isNullable) {
      return '$value?.inMicroseconds';
    } else {
      return '$value.inMicroseconds';
    }
  }

  if (!isDartType(type)) {
    if (useToMapFromMap) {
      if (isNullable) {
        return '$value?.toMap()';
      } else {
        return '$value.toMap()';
      }
    } else {
      if (isNullable) {
        return '$value == null ? null : ${getSerializerName(type)}.toMap($value)';
      } else {
        return '${getSerializerName(type)}.toMap($value)';
      }
    }
  }

  if (type.isDartCoreList || type.isDartCoreSet) {
    if (type.typeArguments.isEmpty) {
      return value;
    }
    final t = type.typeArguments.first as InterfaceType;
    final v = serializeValue(t, 'x', useToMapFromMap: useToMapFromMap);
    if (isNullable) {
      return '$value?.map((x) => $v)';
    } else {
      return '$value.map((x) => $v)';
    }
  }

  if (type.isDartCoreMap) {
    if (type.typeArguments.isEmpty) {
      return value;
    }
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    if (isBasicType(keyType) && isBasicType(valueType)) {
      return value;
    } else {
      final k = serializeValue(keyType, 'k', useToMapFromMap: useToMapFromMap);
      final v = serializeValue(valueType, 'v', useToMapFromMap: useToMapFromMap);
      if (isNullable) {
        return '$value?.map((k, v) => MapEntry($k, $v))';
      } else {
        return '$value.map((k, v) => MapEntry($k, $v))';
      }
    }
  }

  throw UnimplementedError();
}

/// Generates the standard name of the `toMap`/`fromMap` Serializer based on [type]
///
/// e.g. if the class name is User, this returns `UserSerializer`
///
/// The caller then use the name to form the desired function:
///
/// e.g. UserSerializer.fromMap(...) or UserSerializer.toMap(...)
String getSerializerName(InterfaceType type) {
  return '${type.getDisplayString(withNullability: false)}Serializer';
}

List<ParameterElement> getGenerativeUnnamedConstructorParameters(InterfaceType type) {
  // TODO: handle better -- we are looking for the unnamed generative constructor here
  try {
    return type.element.constructors.firstWhere((c) => c.isGenerative).parameters;
  } catch (e) {
    final typeName = type.getDisplayString(withNullability: true);
    final uri = getTypePackageURI(type);
    throw Exception('$typeName does not have a generative unnamed constructor\n$uri');
  }
}
