import 'dart:math';

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890-_';
final _randomGenerator = Random();
String generateRandomID([int length = 20]) => String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(
          _randomGenerator.nextInt(_chars.length),
        ),
      ),
    );
