import 'package:mid_auth/mid_auth.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

final sampleData = {
  'id': 13,
  'created_at': DateTime.now().toString(),
  'email': 'some@email.com',
  'email_confirmed_at': null,
  'metadata': null,
};

void main() {
  group('test user model', () {
    test('- user fromMap success', () {
      User.fromMap(sampleData);
    });

    test('- user created at and emailConfirmationis in UTC', () {
      final data = {...sampleData};
      data['email_confirmed_at'] = DateTime.now().toString();
      final user = User.fromMap(data);
      expect(user.createdAt.isUtc, true);
      expect(user.emailConfirmedAt?.isUtc, true);
    });

    test('- user created_at and emailConfirmation time with UTC time zone designator (Z) success', () {
      final data = {...sampleData};
      // "$y-$m-$d $h:$min:$sec.$ms${us}Z"
      data['created_at'] = DateTime.now().toUtc().toString();
      data['email_confirmed_at'] = DateTime.now().toUtc().toString();
      final user = User.fromMap(data);
      expect(user.createdAt.isUtc, true);
      expect(user.emailConfirmedAt?.isUtc, true);
    });
  });
}
