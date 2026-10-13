import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/utils/validators.dart';

void main() {
  group('parseNumber', () {
    test('reads plain and decimal numbers', () {
      expect(parseNumber('5000'), 5000);
      expect(parseNumber('12.5'), 12.5);
      expect(parseNumber('.5'), 0.5);
      expect(parseNumber('0'), 0);
    });

    test('ignores thousands separators and spaces', () {
      expect(parseNumber('20,000'), 20000);
      expect(parseNumber(' 1,234,567.5 '), 1234567.5);
      expect(parseNumber('20 000'), 20000);
    });

    test('rejects text, NaN, Infinity, exponents and hex', () {
      for (final bad in ['', '   ', 'abc', 'NaN', 'Infinity', '-Infinity', '1e5', '1E5', '0x10', '1.2.3', '--5']) {
        expect(parseNumber(bad), isNull, reason: bad);
      }
    });

    test('rejects a number too big to be finite', () {
      expect(parseNumber('9' * 400), isNull);
    });

    test('rejects negatives unless allowed', () {
      expect(parseNumber('-5'), isNull);
      expect(parseNumber('-5', allowNegative: true), -5);
    });
  });

  group('parseWholeNumber', () {
    test('reads whole numbers, commas allowed', () {
      expect(parseWholeNumber('12'), 12);
      expect(parseWholeNumber('1,200'), 1200);
    });

    test('rejects decimals, text, negatives and overflow', () {
      for (final bad in ['1.5', 'abc', '', '-3', '99999999999999999999999']) {
        expect(parseWholeNumber(bad), isNull, reason: bad);
      }
      expect(parseWholeNumber('-3', allowNegative: true), -3);
    });
  });

  test('requiredText rejects blank and spaces-only text', () {
    final v = Validators.requiredText('Needed');
    expect(v(null), 'Needed');
    expect(v(''), 'Needed');
    expect(v('   '), 'Needed');
    expect(v('x'), isNull);
  });

  test('minLength needs text of at least that length', () {
    final v = Validators.minLength(6);
    expect(v(''), isNotNull);
    expect(v('12345'), isNotNull);
    expect(v('123456'), isNull);
  });

  group('positiveNumber', () {
    test('needs a number above 0', () {
      final v = Validators.positiveNumber();
      expect(v(''), isNotNull);
      expect(v('abc'), isNotNull);
      expect(v('1e5'), isNotNull);
      expect(v('0'), isNotNull);
      expect(v('-10'), isNotNull);
      expect(v('0.5'), isNull);
      expect(v('20,000'), isNull);
    });

    test('max is inclusive, with a custom message over it', () {
      final v = Validators.positiveNumber(max: 25000, maxMessage: 'Too much');
      expect(v('25,000'), isNull);
      expect(v('25000.5'), 'Too much');
    });

    test('the default over-max message names the limit', () {
      expect(Validators.positiveNumber(max: 18000)('20000'), contains('18,000'));
    });
  });

  group('intInRange', () {
    final v = Validators.intInRange(1, 20);

    test('accepts the bounds and between', () {
      expect(v('1'), isNull);
      expect(v('20'), isNull);
      expect(v('7'), isNull);
    });

    test('rejects out of range, decimals, text and blank', () {
      for (final bad in ['0', '21', '-1', '1.5', 'two', '', '999999999999999999999']) {
        expect(v(bad), isNotNull, reason: bad);
      }
    });

    test('a blank field passes when not required', () {
      expect(Validators.intInRange(0, 40, required: false)(''), isNull);
      expect(Validators.intInRange(0, 40, required: false)('41'), isNotNull);
    });
  });

  test('wholeNumber with no max takes anything from min up', () {
    final v = Validators.wholeNumber(required: false);
    expect(v(''), isNull);
    expect(v('0'), isNull);
    expect(v('1,000'), isNull);
    expect(v('-1'), isNotNull);
  });

  test('email is optional but must look like an address', () {
    final v = Validators.email();
    expect(v(''), isNull);
    expect(v('owner@example.com'), isNull);
    expect(v('owner@example'), isNotNull);
    expect(v('owner example.com'), isNotNull);
    expect(Validators.email(required: true)(''), isNotNull);
  });

  test('cnic is optional but must be 13 digits, dashes allowed', () {
    final v = Validators.cnic();
    expect(v(''), isNull);
    expect(v('35202-1234567-1'), isNull);
    expect(v('3520212345671'), isNull);
    expect(v('35202-1234567'), isNotNull);
    expect(v('35202-1234567-12'), isNotNull);
    expect(v('3520A-1234567-1'), isNotNull);
  });

  test('phone needs 10 to 13 digits, dashes, spaces and a leading + allowed', () {
    final v = Validators.phone();
    expect(v(''), isNotNull);
    expect(v('0300-1234567'), isNull);
    expect(v('+92 300 1234567'), isNull);
    expect(v('03001234567'), isNull);
    expect(v('12345'), isNotNull);
    expect(v('12345678901234'), isNotNull);
    expect(v('0300-12345ab'), isNotNull);
    expect(Validators.phone(required: false)(''), isNull);
  });
}
