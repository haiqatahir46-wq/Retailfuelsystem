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

    test('reads Arabic-Indic and Urdu digits', () {
      expect(parseNumber('\u0662\u0660,\u0660\u0660\u0660'), 20000); // ٢٠,٠٠٠
      expect(parseNumber('\u06f1\u06f2.\u06f5'), 12.5); // ۱۲.۵
    });
  });

  test('normaliseDigits turns only Eastern digits into ASCII', () {
    expect(normaliseDigits('\u0660\u0669 \u06f0\u06f9 -42 abc'), '09 09 -42 abc');
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

    test('reads Urdu digits', () {
      expect(parseWholeNumber('\u06f1,\u06f2\u06f0\u06f0'), 1200); // ۱,۲۰۰
    });
  });

  test('formatLimit rounds down, so the limit it names always passes', () {
    expect(formatLimit(17999.6), '17,999');
    expect(formatLimit(18000), '18,000');
    expect(formatLimit(0.9), '0');
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

    test('says which way a number is wrong', () {
      final v = Validators.positiveNumber(max: 18000);
      expect(v('abc'), 'Enter a number, e.g. 5,000');
      expect(v('-10'), "Can't be negative");
      expect(v('0'), 'Must be more than 0');
      expect(v('20000'), 'Too large (max 18,000)');
      final huge = '9' * 400; // too big even for a double
      expect(v(huge), 'Too large (max 18,000)');
      expect(v('-$huge'), "Can't be negative");
    });

    test('max is inclusive, with a custom message over it', () {
      final v = Validators.positiveNumber(max: 25000, maxMessage: 'Too much');
      expect(v('25,000'), isNull);
      expect(v('25000.5'), 'Too much');
    });

    test('the default over-max message names the limit, rounded down', () {
      expect(Validators.positiveNumber(max: 17999.6)('18000'), 'Too large (max 17,999)');
      expect(Validators.positiveNumber(max: 17999.6)('17999'), isNull);
    });

    test('min sets the smallest amount', () {
      final v = Validators.positiveNumber(min: 1);
      expect(v('0.4'), 'Must be at least 1');
      expect(v('1'), isNull);
    });

    test('reads Urdu digits', () {
      expect(Validators.positiveNumber(max: 100)('\u06f5\u06f0'), isNull); // ۵۰
      expect(Validators.positiveNumber(max: 100)('\u06f5\u06f0\u06f0'), 'Too large (max 100)'); // ۵۰۰
    });
  });

  test('nonNegativeNumber takes blank, 0 and up to max', () {
    final v = Validators.nonNegativeNumber(max: 1000000);
    expect(v(''), isNull);
    expect(v('0'), isNull);
    expect(v('1,000,000'), isNull);
    expect(v('-5'), "Can't be negative");
    expect(v('1,000,001'), 'Too large (max 1,000,000)');
    expect(v('abc'), 'Enter a number, e.g. 5,000');
    expect(Validators.nonNegativeNumber(required: true)(''), 'Enter an amount');
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

    test('says which way a number is wrong', () {
      expect(v('0'), 'Enter a number from 1 to 20');
      expect(v('21'), 'Too large (max 20)');
      expect(v('999999999999999999999'), 'Too large (max 20)');
      expect(v('-1'), "Can't be negative");
      expect(v('1.5'), 'Enter a whole number');
    });

    test('reads Urdu digits', () {
      expect(v('\u06f7'), isNull); // ۷
      expect(parseWholeNumber('\u06f7'), 7);
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
    expect(v('-1'), "Can't be negative");
    // No limit to name, but no int holds this many digits.
    expect(v('99999999999999999999'), 'Too large');
  });

  test('email is optional but must look like an address', () {
    final v = Validators.email();
    expect(v(''), isNull);
    expect(v('owner@example.com'), isNull);
    expect(v('owner@example'), isNotNull);
    expect(v('owner example.com'), isNotNull);
    expect(Validators.email(required: true)(''), isNotNull);
  });

  test('usernameOrEmail takes a username, or a valid email once there is an @', () {
    final v = Validators.usernameOrEmail('Needed');
    expect(v(''), 'Needed');
    expect(v('  '), 'Needed');
    expect(v('amir'), isNull);
    expect(v('amir@gmail.com'), isNull);
    expect(v('amir@gmail'), 'Enter a valid email address');
    expect(v('@'), 'Enter a valid email address');
  });

  test('cnic is optional but must be 13 digits, dashes or spaces allowed', () {
    final v = Validators.cnic();
    expect(v(''), isNull);
    expect(v('35202-1234567-1'), isNull);
    expect(v('3520212345671'), isNull);
    expect(v('35202 1234567 1'), isNull);
    expect(v('\u06f3\u06f5\u06f2\u06f0\u06f2-1234567-1'), isNull); // ۳۵۲۰۲-...
    expect(v('35202-1234567'), isNotNull);
    expect(v('35202-1234567-12'), isNotNull);
    expect(v('3520A-1234567-1'), isNotNull);
  });

  test('phone needs 10 to 13 digits, or + / 00 and an international number', () {
    final v = Validators.phone();
    expect(v(''), isNotNull);
    for (final good in [
      '0300-1234567',
      '+92 300 1234567',
      '03001234567',
      '0092 300 1234567', // 14 digits with the 00
      '(042) 3576 1234',
      '+92 (300) 123-4567',
      '\u06f0\u06f3\u06f0\u06f0 1234567', // ۰۳۰۰ 1234567
    ]) {
      expect(v(good), isNull, reason: good);
    }
    for (final bad in [
      '12345',
      '12345678901234', // 14 digits without 00
      '009230012345678', // 15 with the 00
      '0300-12345ab',
      '+92',
      '++923001234567',
    ]) {
      expect(v(bad), 'Enter a valid phone number', reason: bad);
    }
    expect(Validators.phone(required: false)(''), isNull);
  });
}
