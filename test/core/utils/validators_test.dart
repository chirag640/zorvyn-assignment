import 'package:flutter_test/flutter_test.dart';
import 'package:zorvyn_finance/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('returns error when email is empty', () {
        expect(Validators.email(''), 'Email is required');
        expect(Validators.email(null), 'Email is required');
      });

      test('returns error for invalid email', () {
        expect(Validators.email('invalid'), 'Please enter a valid email');
        expect(Validators.email('test@'), 'Please enter a valid email');
      });

      test('returns null for valid email', () {
        expect(Validators.email('test@example.com'), null);
      });
    });

    group('password', () {
      test('returns error when password is empty', () {
        expect(Validators.password(''), 'Password is required');
      });

      test('returns error when password is too short', () {
        expect(Validators.password('short'), contains('at least 8 characters'));
      });

      test('returns error when password has no letter', () {
        expect(
            Validators.password('12345678'), contains('at least one letter'));
      });

      test('returns error when password has no number', () {
        expect(
            Validators.password('password'), contains('at least one number'));
      });

      test('returns null for valid password', () {
        expect(Validators.password('password123'), null);
      });
    });
  });
}
