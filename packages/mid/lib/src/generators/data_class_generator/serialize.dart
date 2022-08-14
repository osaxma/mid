// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/common/analyzer.dart';

// todo: once this is working, clean up the client/server generator:
//       - ensure the generated functin is called per format
//       - import the appropriate file if serialization is in a separate file
//       - remove code searching for `toMap`/'toJson`/`fromMap`/`fromJson`

/// Generates serialization code for non-Dart Types (i.e. none of the core types) for the server
///
///
/// The generator should be provided a list of all the available [types]. That is,
/// all the types used in any return statements or any arguments on the API server.
///
/// The generator will ensure each Type is generated only once in the following format:
///
/// ```dart
/// TypeNameSerializer {
///
///   static TypeName fromMap(Map<String, dynamic> map) {/*  */}
///
///   static Map<String, dynamic> toMap(TypeName instance) {/*  */}
/// }
/// ```
///
/// The generator will run recursively for non-Dart Type within the given list of types.
/// And it'll generate the code for them as well.
///
/// For instance, if the given type is the following:
/// ```dart
/// class User {
///     final int id;
///     final String name;
///     final UserData data;
/// }
/// ```
/// Where `UserData` was not supplied within `types`, the serializer will be generated for `UserData`.
/// In addition, if `UserData` contains another non-Dart type (e.g. `MetaData`), the serializer will
/// be generated for `MetaData` as well.
///
///
class ServerClassesSerializer {
  /// A set of all the available non-Dart types
  ///
  /// For `mid`, this mean the types for every return statement and argument.
  final Set<InterfaceType> types;

  ServerClassesSerializer({
    required this.types,
  });

  /// Generates the standard name of the  `toMap` function based on [type]
  static String getSerializerName(InterfaceType type) {
    return type.getDisplayString(withNullability: false) + 'Serializer';
  }

  String generateCode() {
    final code = StringBuffer();

    for (final t in types) {
     /* ... TODO ...  */
    }

    return code.toString();
  }
}
