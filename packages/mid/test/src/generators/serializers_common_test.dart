import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/generators/serializer_common.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

// almost all types are InterfaceType since almost everything in dart is an Object which is an Interface
class InterfaceTypeMock extends Mock implements InterfaceType {}

// dynamic, function, never, void, ,etc.
class NonInterfaceType extends Mock implements DartType {}

class EnumElementMock extends Mock implements EnumElement {}

/// This should be called at the beginning of each test to avoid `Null` return.
/// [type] must be both [Mock] and [DartType]
/// The functions we are testing uses these values to determine the type.
///
/// e.g. when testing a string type:
///   // call this
///   setDefaultValuesForMock(stringType)
///   // then do this
///   when(() => type.isDartCoreString).thenReturn(true);
///   // if needs to be nullable, then do this:
///   when(() => type.nullabilitySuffix).thenReturn(NullabilitySuffix.question);
///   // to set the type name, mock this:
///    setTypeDisplayString('String');
void setDefaultValuesForMock(DartType type, {required String name, required bool nullable, bool isEnum = false}) {
  when(() => type.isBottom).thenReturn(false);
  when(() => type.isDartAsyncFuture).thenReturn(false);
  when(() => type.isDartAsyncFutureOr).thenReturn(false);
  when(() => type.isDartAsyncStream).thenReturn(false);
  when(() => type.isDartCoreBool).thenReturn(false);
  when(() => type.isDartCoreDouble).thenReturn(false);
  when(() => type.isDartCoreEnum).thenReturn(false);
  when(() => type.isDartCoreFunction).thenReturn(false);
  when(() => type.isDartCoreInt).thenReturn(false);
  when(() => type.isDartCoreNum).thenReturn(false);
  when(() => type.isDartCoreNull).thenReturn(false);
  when(() => type.isDartCoreIterable).thenReturn(false);
  when(() => type.isDartCoreList).thenReturn(false);
  when(() => type.isDartCoreMap).thenReturn(false);
  when(() => type.isDartCoreObject).thenReturn(false);
  when(() => type.isDartCoreSet).thenReturn(false);
  when(() => type.isDartCoreString).thenReturn(false);
  when(() => type.isDartCoreSymbol).thenReturn(false);
  when(() => type.isDynamic).thenReturn(false);
  when(() => type.isVoid).thenReturn(false);
  when(() => type.nullabilitySuffix).thenReturn(nullable ? NullabilitySuffix.question : NullabilitySuffix.none);

  /// Since `getDisplayString(withNullability: true)` isn't the same as `getDisplayString(withNullability: false)`
  /// and as both could be used in the code, we set the name for both methods.
  when(() => type.getDisplayString(withNullability: true)).thenReturn(name);
  when(() => type.getDisplayString(withNullability: false)).thenReturn(name.replaceAll('?', ''));
  if (isEnum) {
    when(() => type.element2).thenReturn(EnumElementMock());
  } else {
    when(() => type.element2).thenReturn(InterfaceElementMock());
  }
}

void setTypDisplayString(DartType type, String name) {}

void main() {
  group('de/serialization tests ', () {
    group('- dart types', () {
      // TODO: should we copy this to all basic types: int, double, num, bool, etc?
      test('test String', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'String', nullable: false);
        when(() => type.isDartCoreString).thenReturn(true);

        final valueAssignment = 'value';

        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'value';
        expect(serialiedValue, expectedValue);

        final deserialiedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'value as String';
        expect(expectedValue, deserialiedValue);
      });

      test('test double?', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'double?', nullable: true);
        when(() => type.isDartCoreDouble).thenReturn(true);

        final valueAssignment = 'value';

        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'value';
        expect(serialiedValue, expectedValue);

        final deserialiedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'value as double?';
        expect(expectedValue, deserialiedValue);
      });

      test('test DateTime', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'DateTime', nullable: false);

        final valueAssignment = 'value';

        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);

        var expectedValue = 'value.toUtc().toIso8601String()';
        expect(serialiedValue, expectedValue);

        final deserialiedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'DateTime.parse(value)';
        expect(expectedValue, deserialiedValue);
      });

      test('test DateTime?', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'DateTime?', nullable: true);

        final valueAssignment = 'value';

        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);

        var expectedValue = 'value?.toUtc().toIso8601String()';
        expect(serialiedValue, expectedValue);

        final deserialiedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'value == null ? null : DateTime.parse(value)';
        expect(expectedValue, deserialiedValue);
      });

      test('test Duration', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'Duration', nullable: false);

        final valueAssignment = 'value';

        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'value.inMicroseconds';
        expect(serialiedValue, expectedValue);

        final deserialiedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'Duration(microseconds: value)';
        expect(expectedValue, deserialiedValue);
      });

      test('test Duration?', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'Duration?', nullable: true);

        final valueAssignment = 'value';

        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'value?.inMicroseconds';
        expect(serialiedValue, expectedValue);

        final deserialiedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'value == null ? null : Duration(microseconds: value)';
        expect(expectedValue, deserialiedValue);
      });

      test('test List<int>', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'List<int>', nullable: false);
        when(() => type.isDartCoreList).thenReturn(true);
        final typeArg = InterfaceTypeMock();
        setDefaultValuesForMock(typeArg, name: 'int', nullable: false);
        when(() => typeArg.isDartCoreInt).thenReturn(true);
        when(() => type.typeArguments).thenReturn([typeArg]);

        final valueAssignment = 'value';

        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'value';
        expect(serialiedValue, expectedValue);

        final deserialiedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'List<int>.from(value.map((x) => x as int))';
        expect(expectedValue, deserialiedValue);
      });

      test('test Set<num>?', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'Set<num>?', nullable: true);
        when(() => type.isDartCoreSet).thenReturn(true);
        final typeArg = InterfaceTypeMock();
        setDefaultValuesForMock(typeArg, name: 'num', nullable: false);
        when(() => typeArg.isDartCoreNum).thenReturn(true);
        when(() => type.typeArguments).thenReturn([typeArg]);

        final valueAssignment = 'value';

        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'value?.toList()';
        expect(serialiedValue, expectedValue);

        final deserialiedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'value == null ? null : Set<num>.from(value.map((x) => x as num))';
        expect(expectedValue, deserialiedValue);
      });

      test('test Map<String, dynamic>', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'Map<String, dynamic>', nullable: false);
        when(() => type.isDartCoreMap).thenReturn(true);
        final typeArg1 = InterfaceTypeMock();
        setDefaultValuesForMock(typeArg1, name: 'String', nullable: false);
        when(() => typeArg1.isDartCoreString).thenReturn(true);
        final typeArg2 = NonInterfaceType(); // dynamic is not an interface type
        setDefaultValuesForMock(typeArg2, name: 'dynamic', nullable: false);
        when(() => typeArg2.isDynamic).thenReturn(true);
        when(() => type.typeArguments).thenReturn([typeArg1, typeArg2]);

        final valueAssignment = 'value';

        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'value';
        expect(serialiedValue, expectedValue);

        final deserialiedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'value';
        expect(expectedValue, deserialiedValue);
      });

      // TODO: we should throw if the non-interface type is not dynamic
      test('test Non-InterfaceType', () {
        final type = NonInterfaceType();
        setDefaultValuesForMock(type, name: '_', nullable: false);
        final valueAssignment = 'value';
        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'value';
        expect(serialiedValue, expectedValue);

        final deserializedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expect(deserializedValue, expectedValue);
      });
    });

    group('- non-dart types', () {
      test(' - arbitrary non-dart type (using toMapFromMap)', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'Data', nullable: false);

        final valueAssignment = 'value';
        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: true);
        var expectedValue = 'value.toMap()';
        expect(serialiedValue, expectedValue);

        final deserializedValue = deserializeValue(type, valueAssignment, useToMapFromMap: true);
        expectedValue = 'Data.fromMap(value)';
        expect(deserializedValue, expectedValue);
      });

      test(' - arbitrary non-dart type nullable (using toMapFromMap)', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'Data?', nullable: true);

        final valueAssignment = 'value';
        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: true);
        var expectedValue = 'value?.toMap()';
        expect(serialiedValue, expectedValue);

        final deserializedValue = deserializeValue(type, valueAssignment, useToMapFromMap: true);
        expectedValue = 'value == null ? null : Data.fromMap(value)';
        expect(deserializedValue, expectedValue);
      });

      test(' - arbitrary non-dart type (using Serializer Pattern)', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'Data', nullable: false);

        final valueAssignment = 'value';
        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'DataSerializer.toMap(value)';
        expect(serialiedValue, expectedValue);

        final deserializedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'DataSerializer.fromMap(value)';
        expect(deserializedValue, expectedValue);
      });

      test(' - arbitrary non-dart type nullable (using Serializer Pattern)', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'Data?', nullable: true);

        final valueAssignment = 'value';
        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'value == null ? null : DataSerializer.toMap(value!)';
        expect(serialiedValue, expectedValue);

        final deserializedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'value == null ? null : DataSerializer.fromMap(value)';
        expect(deserializedValue, expectedValue);
      });

      test(' - arbitrary non-dart type in List (using Serializer Pattern)', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'List<Data>', nullable: false);
        final typeArg = InterfaceTypeMock();
        setDefaultValuesForMock(typeArg, name: 'Data', nullable: false);
        when(() => type.isDartCoreList).thenReturn(true);
        when(() => type.typeArguments).thenReturn([typeArg]);

        final valueAssignment = 'value';
        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'value.map((x) => DataSerializer.toMap(x)).toList()';
        expect(serialiedValue, expectedValue);

        final deserializedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue = 'List<Data>.from(value.map((x) => DataSerializer.fromMap(x)))';
        expect(deserializedValue, expectedValue);
      });

      test(' - arbitrary non-dart type in nullable Set (using Serializer Pattern)', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'Set<Data>?', nullable: true);
        final typeArg = InterfaceTypeMock();
        setDefaultValuesForMock(typeArg, name: 'Data', nullable: false);
        when(() => type.isDartCoreSet).thenReturn(true);
        when(() => type.typeArguments).thenReturn([typeArg]);

        final valueAssignment = 'value';
        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: false);
        var expectedValue = 'value?.map((x) => DataSerializer.toMap(x)).toList()';
        expect(serialiedValue, expectedValue);

        final deserializedValue = deserializeValue(type, valueAssignment, useToMapFromMap: false);
        expectedValue =
            'value == null ? null : Set<Data>.from(value.map((x) => DataSerializer.fromMap(x)))';
        expect(deserializedValue, expectedValue);
      });

      test(' - arbitrary non-dart types in Map key/value (using fromMaptoMap)', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'Map<KeyData, ValueData>', nullable: false);
        final typeArg1 = InterfaceTypeMock();
        final typeArg2 = InterfaceTypeMock();
        setDefaultValuesForMock(typeArg1, name: 'KeyData', nullable: false);
        setDefaultValuesForMock(typeArg2, name: 'ValueData', nullable: false);
        when(() => type.isDartCoreMap).thenReturn(true);
        when(() => type.typeArguments).thenReturn([typeArg1, typeArg2]);

        final valueAssignment = 'value';
        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: true);
        var expectedValue = 'value.map((k, v) => MapEntry(k.toMap(), v.toMap()))';
        expect(serialiedValue, expectedValue);

        final deserializedValue = deserializeValue(type, valueAssignment, useToMapFromMap: true);
        expectedValue = '(value as Map).map((k, v) => MapEntry(KeyData.fromMap(k), ValueData.fromMap(v)))';
        expect(deserializedValue, expectedValue);
      });

      test(' - arbitrary non-dart types in nullable Map key/value (using fromMaptoMap)', () {
        final type = InterfaceTypeMock();
        setDefaultValuesForMock(type, name: 'Map<KeyData, ValueData>', nullable: true);
        final typeArg1 = InterfaceTypeMock();
        final typeArg2 = InterfaceTypeMock();
        setDefaultValuesForMock(typeArg1, name: 'KeyData', nullable: false);
        setDefaultValuesForMock(typeArg2, name: 'ValueData', nullable: false);
        when(() => type.isDartCoreMap).thenReturn(true);
        when(() => type.typeArguments).thenReturn([typeArg1, typeArg2]);

        final valueAssignment = 'value';
        final serialiedValue = serializeValue(type, valueAssignment, useToMapFromMap: true);
        var expectedValue = 'value?.map((k, v) => MapEntry(k.toMap(), v.toMap()))';
        expect(serialiedValue, expectedValue);

        final deserializedValue = deserializeValue(type, valueAssignment, useToMapFromMap: true);
        expectedValue = '(value as Map?)?.map((k, v) => MapEntry(KeyData.fromMap(k), ValueData.fromMap(v)))';
        expect(deserializedValue, expectedValue);
      });
    });
  });

  test('test Serializer Pattern Generator', () {
    final type = InterfaceTypeMock();
    setDefaultValuesForMock(type, name: 'Data', nullable: false);
    final serializerName = getSerializerName(type);
    expect(serializerName, 'DataSerializer');
  });

  group('constructor parameter getter function', () {
    test('- returns list of element parameters', () {
      final type = InterfaceTypeMock();
      setDefaultValuesForMock(type, name: 'Data', nullable: false);
      final elementMock = InterfaceElementMock();
      final constructorMock = ConstructorMock();
      when(() => type.element2).thenReturn(elementMock);
      when(() => elementMock.constructors).thenReturn([constructorMock]);
      when(() => constructorMock.isGenerative).thenReturn(true);
      when(() => constructorMock.parameters).thenReturn(<ParameterElement>[]);

      final paras = getGenerativeUnnamedConstructorParameters(type);

      expect(paras, isA<List<ParameterElement>>());
    });

    test('- throws when non-generative constructor found', () {
      final type = InterfaceTypeMock();
      setDefaultValuesForMock(type, name: 'Data', nullable: false);
      final elementMock = InterfaceElementMock();
      final constructorMock = ConstructorMock();
      when(() => type.element2).thenReturn(elementMock);
      when(() => elementMock.constructors).thenReturn([constructorMock]);
      when(() => constructorMock.isGenerative).thenReturn(false);

      expect(() => getGenerativeUnnamedConstructorParameters(type), throwsException);
    });
  });
}

class InterfaceElementMock extends Mock implements InterfaceElement {}

class ConstructorMock extends Mock implements ConstructorElement {}
