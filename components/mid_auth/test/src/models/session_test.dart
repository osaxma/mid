import 'package:mid_auth/mid_auth.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

final sampleData = {
  'access_token': 'some.access.token',
  'refresh_token': 'some.refresh.token',
  'expiry_time': DateTime.now().toString(),
  'user': User(
    id: 13,
    createdAt: DateTime.now(),
    email: 'some@email.com',
    metadata: {},
  ).toMap(),
};

void main() {
  group('test session model', () {
    test('- session fromMap success', () {
      Session.fromMap(sampleData);
    });

    test('- session expiry time is in UTC', () {
      final session = Session.fromMap(sampleData);
      expect(session.expiryTime.isUtc, true);
    });

    test('- session expiry time with UTC time zone designator (Z) success', () {
      final data = {...sampleData};
      // "$y-$m-$d $h:$min:$sec.$ms${us}Z"
      data['expiry_time'] = DateTime.now().toUtc().toString();
      final session = Session.fromMap(data);
      expect(session.expiryTime.isUtc, true);
    });
  });
}
