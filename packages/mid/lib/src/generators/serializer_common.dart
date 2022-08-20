import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/common/utils.dart';

/// When [useToMapFromMap] is `true`, type.toMap() and Type.fromMap() (i.e. userData.toMap() & UserData.fromMap()).
/// When `false`, the Serializer is used (i.e. UserDataSerializer.toMap() & UserDataSerializer.fromMap()).
///
/// The first case is mainly used for the client side since it uses data classes whereas the second case is used
/// for the server since it uses the Serializer pattern.
String deserializeValue(DartType type, String value, {required bool useToMapFromMap}) {
  final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;
  final typeName = type.getDisplayString(withNullability: true);
  // e.g. dynamic isn't an InterfaceType
  if (type is! InterfaceType) {
    return value;
  }

  if (isBasicType(type)) {
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

  if (type.isDartCoreList || type.isDartCoreSet) {
    if (type.typeArguments.isEmpty) {
      return value;
    }
    final t = type.typeArguments.first;
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
        return "($value as Map?)?.map((k, v) => MapEntry($k, $v))";
      } else {
        return "($value as Map).map((k, v) => MapEntry($k, $v))";
      }
    }
  }

  if (isEnum(type)) {
    final enumName = type.getDisplayString(withNullability: false);
    if (isNullable) {
      // NOTE: `firstWhereOrNull` requirs importing `collection` package!
      return "$enumName.values.firstWhereOrNull((e) => e.name == $value)";
    } else {
      return "$enumName.values.firstWhere((e) => e.name == $value)";
    }
  }

  if (isUri(type)) {
    if (isNullable) {
      return "$value == null ? null : Uri.parse($value)";
    } else {
      return "Uri.parse($value)";
    }
  }

  if (isBigInt(type)) {
    if (isNullable) {
      return "$value == null ? null : BigInt.parse($value)";
    } else {
      return "BigInt.parse($value)";
    }
  }

  if (isOtherDartType(type) || isAsyncType(type) || type.isDartCoreIterable) {
    throw Exception('$typeName is not a serializable type');
  }

  // Since this is an [InterfaceType] and it's not any of the core types, we'll assume it's a serializable type
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

/// When [useToMapFromMap] is `true`, type.toMap() and Type.fromMap() (i.e. userData.toMap() & UserData.fromMap()).
/// When `false`, the Serializer is used (i.e. UserDataSerializer.toMap() & UserDataSerializer.fromMap()).
///
/// The first case is mainly used for the client side since it uses data classes whereas the second case is used
/// for the server since it uses the Serializer pattern.
String serializeValue(DartType type, String value, {required bool useToMapFromMap}) {
  final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;
  // e.g. dynamic isn't an InterfaceType
  if (type is! InterfaceType) {
    return value;
  }
  if (isBasicType(type)) {
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

  if (type.isDartCoreList || type.isDartCoreSet) {
    if (type.typeArguments.isEmpty) {
      return value;
    }
    final t = type.typeArguments.first;

    String statement;

    if (isBasicType(t)) {
      if (type.isDartCoreSet) {
        // set isn't serializable so we need to convert it to list
        statement = isNullable ? '$value?.toList()' : '$value.toList()';
      } else {
        // no mapping required for basic types
        statement = value;
      }
    } else {
      final v = serializeValue(t, 'x', useToMapFromMap: useToMapFromMap);
      // mapping generates an iterrable so we need to convert it into a list.
      if (isNullable) {
        statement = '$value?.map((x) => $v).toList()';
      } else {
        statement = '$value.map((x) => $v).toList()';
      }
    }

    // if (type.isDartCoreSet) {
    //   statement = isNullable && !statement.contains('?') ? '$statement?.toList()' : '$statement.toList()';
    // }

    return statement;
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

  if (isEnum(type)) {
    if (isNullable) {
      return "$value?.name";
    } else {
      return "$value.name";
    }
  }

  if (isUri(type) || isBigInt(type)) {
    if (isNullable) {
      return "$value?.toString()";
    } else {
      return "$value.toString()";
    }
  }

  if (isOtherDartType(type) || isAsyncType(type) || type.isDartCoreIterable) {
    final typeName = type.getDisplayString(withNullability: true);
    throw Exception('$typeName is not a serializable type');
  }

  // Since this is an [InterfaceType] and it's not any of the core types, we'll assume it's a serializable type
  if (useToMapFromMap) {
    if (isNullable) {
      return '$value?.toMap()';
    } else {
      return '$value.toMap()';
    }
  } else {
    if (isNullable) {
      return '$value == null ? null : ${getSerializerName(type)}.toMap($value!)';
    } else {
      return '${getSerializerName(type)}.toMap($value)';
    }
  }
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

/// Set [skipServerOnly] to true so any parameters with [serverOnly] annotation will be ignored
List<ParameterElement> getGenerativeUnnamedConstructorParameters(InterfaceType type, {bool skipServerOnly = false}) {
  // TODO: handle better -- we are looking for the unnamed generative constructor here
  try {
    final paras = type.element2.constructors.firstWhere((c) => c.isGenerative).parameters;
    if (skipServerOnly) {
      return paras;
    } else {
      return paras.where((element) => !elementHasAnnotation(element, 'serverOnly')).toList();
    }
  } catch (e) {
    final typeName = type.getDisplayString(withNullability: true);
    throw Exception('$typeName does not have a generative unnamed constructor');
  }
}
