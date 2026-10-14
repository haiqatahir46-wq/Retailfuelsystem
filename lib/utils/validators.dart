import 'package:flutter/widgets.dart';
import '../models/sales.dart';

// Shared parsing and validation for every form in the app, so "20,000"
// means the same thing on Threshold, Create Reorder, Add Station and Logs,
// and every field rejects the same bad input with the same message.

/// Thousands separators and spaces, which people type because the app shows
/// numbers that way ("20,000 L").
final _separators = RegExp(r'[,\s]');

/// Plain decimal notation only: no exponent ("1e5"), hex, "NaN" or
/// "Infinity", which double.tryParse would otherwise accept.
final _decimal = RegExp(r'^-?(\d+\.?\d*|\.\d+)$');
final _wholeNumber = RegExp(r'^-?\d+$');

/// Arabic-Indic (U+0660-0669) and Extended Arabic-Indic, i.e. Urdu
/// (U+06F0-06F9), digits. An Urdu keyboard types these, so they're read as
/// the ASCII digits they stand for.
final _easternDigit = RegExp('[٠-٩۰-۹]');

/// [text] with every Arabic-Indic or Urdu digit replaced by its ASCII
/// digit ("۲۰۰" -> "200"). Everything else is left as it is. Every number,
/// phone and CNIC check goes through this first.
String normaliseDigits(String text) {
  return text.replaceAllMapped(_easternDigit, (m) {
    final code = m[0]!.codeUnitAt(0);
    return String.fromCharCode(0x30 + code - (code >= 0x06F0 ? 0x06F0 : 0x0660));
  });
}

/// [text] ready to parse as a number: digits made ASCII, then separators
/// and spaces dropped.
String _cleanNumber(String text) => normaliseDigits(text).replaceAll(_separators, '');

/// The number typed in [text], or null if it isn't one. Commas and spaces
/// are ignored, and Arabic-Indic / Urdu digits count. Only plain decimal
/// notation counts, so "1e5", "NaN" and "Infinity" are rejected, and so is
/// anything too big to be finite. Negative numbers give null unless
/// [allowNegative].
double? parseNumber(String text, {bool allowNegative = false}) {
  final cleaned = _cleanNumber(text);
  if (!_decimal.hasMatch(cleaned)) return null;
  final value = double.tryParse(cleaned);
  if (value == null || !value.isFinite) return null;
  if (!allowNegative && value < 0) return null;
  return value;
}

/// The whole number typed in [text] (commas and spaces ignored, Arabic-Indic
/// / Urdu digits allowed), or null if it isn't one or is too big for an
/// int. Negative numbers give null unless [allowNegative].
int? parseWholeNumber(String text, {bool allowNegative = false}) {
  final cleaned = _cleanNumber(text);
  if (!_wholeNumber.hasMatch(cleaned)) return null;
  final value = int.tryParse(cleaned);
  if (value == null || (!allowNegative && value < 0)) return null;
  return value;
}

/// A limit as a message shows it: rounded DOWN to a whole number, with
/// thousands separators. Limits are compared exactly, so rounding one up
/// would name a number the field then rejects: with 17,999.6 L of room,
/// "Only 18,000 L..." would turn away the 18,000 it suggests, whereas
/// "Only 17,999 L..." is always accepted.
String formatLimit(double limit) => formatThousands(limit.floorToDouble());

/// Whether [text] (trimmed) looks like an email address: something@domain.tld,
/// with no spaces and one '@'. The one email rule, shared by
/// [Validators.email] and AppSession.signInDemo.
bool isValidEmail(String text) => _email.hasMatch(text.trim());

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// What may sit between a phone number's digits: spaces, dashes and
/// brackets ("(042) 3576-1234").
final _phoneSeparators = RegExp(r'[\s\-()]');

/// A phone number once its separators are gone: 10 to 13 digits
/// (0300 1234567), or an international number written with + (+92 300
/// 1234567) or with 00 (0092 300 1234567, up to 14 digits with the 00).
final _phone = RegExp(r'^(\+\d{10,13}|00\d{10,12}|\d{10,13})$');

final _cnicSeparators = RegExp(r'[\s-]');
final _cnic = RegExp(r'^\d{13}$');

/// Form validators. Each returns a [FormFieldValidator]: null when the value
/// is fine, otherwise the message shown under the field.
///
/// The number validators keep their messages distinct, so the owner knows
/// what to fix: "Enter a number, e.g. 5,000" for something that isn't one,
/// "Can't be negative", and "Too large (max X)" over the field's limit
/// (or, with no limit, too big to hold at all).
abstract final class Validators {
  /// Something other than spaces must be typed.
  static FormFieldValidator<String> requiredText([String message = 'This field is required']) {
    return (value) => (value ?? '').trim().isEmpty ? message : null;
  }

  /// Required, and at least [length] characters long (e.g. a password).
  static FormFieldValidator<String> minLength(int length, {String? message}) {
    return (value) {
      final text = value ?? '';
      if (text.isEmpty) return 'This field is required';
      if (text.length < length) return message ?? 'Must be at least $length characters';
      return null;
    };
  }

  /// Why [text] (not blank) isn't a usable amount up to [max], or null if
  /// it is one: not a number, negative, or over [max] ([maxMessage], or
  /// "Too large (max X)").
  static String? _amountProblem(String text, {double? max, String? maxMessage}) {
    final tooLarge = max == null ? 'Too large' : maxMessage ?? 'Too large (max ${formatLimit(max)})';
    final cleaned = _cleanNumber(text);
    final number = parseNumber(cleaned, allowNegative: true);
    if (number == null) {
      // Plain digits that still don't parse are too many to be finite.
      if (!_decimal.hasMatch(cleaned)) return 'Enter a number, e.g. 5,000';
      return cleaned.startsWith('-') ? "Can't be negative" : tooLarge;
    }
    if (number < 0) return "Can't be negative";
    if (max != null && number > max) return tooLarge;
    return null;
  }

  /// A number above 0 (commas allowed), at least [min] and no more than
  /// [max] when given. [maxMessage] replaces the default message for a
  /// value over [max]; it should name the limit with [formatLimit].
  static FormFieldValidator<String> positiveNumber({double? min, double? max, String? maxMessage}) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return 'Enter an amount';
      final problem = _amountProblem(text, max: max, maxMessage: maxMessage);
      if (problem != null) return problem;
      final number = parseNumber(text)!;
      if (number <= 0) return 'Must be more than 0';
      if (min != null && number < min) return 'Must be at least ${formatThousands(min)}';
      return null;
    };
  }

  /// A number from 0 up (commas allowed), and no more than [max] when
  /// given. When not [required], a blank field passes; the caller reads it
  /// as 0.
  static FormFieldValidator<String> nonNegativeNumber({double? max, bool required = false}) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return required ? 'Enter an amount' : null;
      return _amountProblem(text, max: max);
    };
  }

  /// A whole number from [min] to [max] (commas allowed). When not
  /// [required], a blank field passes; the caller reads it as its default.
  static FormFieldValidator<String> intInRange(int min, int max, {bool required = true}) {
    return wholeNumber(min: min, max: max, required: required);
  }

  /// A whole number of at least [min], and no more than [max] when given.
  /// When not [required], a blank field passes. Reads the text the same
  /// way as [parseWholeNumber], so whatever passes, that parses.
  static FormFieldValidator<String> wholeNumber({int min = 0, int? max, bool required = true}) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return required ? 'This field is required' : null;
      final cleaned = _cleanNumber(text);
      if (!_wholeNumber.hasMatch(cleaned)) return 'Enter a whole number';
      final negative = cleaned.startsWith('-');
      final tooLarge = max == null ? 'Too large' : 'Too large (max ${formatThousands(max.toDouble())})';
      final number = int.tryParse(cleaned);
      // Digits only, yet no int: too many digits to hold at all.
      if (number == null) return negative && min >= 0 ? "Can't be negative" : tooLarge;
      if (number < 0 && min >= 0) return "Can't be negative";
      if (max != null && number > max) return tooLarge;
      if (number < min) return max == null ? 'Enter $min or more' : 'Enter a number from $min to $max';
      return null;
    };
  }

  /// An email address; a blank field passes unless [required].
  static FormFieldValidator<String> email({bool required = false}) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return required ? 'This field is required' : null;
      return isValidEmail(text) ? null : 'Enter a valid email address';
    };
  }

  /// A username or an email address, required ([message] when blank).
  /// Anything with an '@' in it is meant as an email, so it must be a valid
  /// one ("amir@gmail" is a typo, not a username).
  static FormFieldValidator<String> usernameOrEmail([String message = 'This field is required']) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return message;
      if (text.contains('@') && !isValidEmail(text)) return 'Enter a valid email address';
      return null;
    };
  }

  /// A Pakistani CNIC: 13 digits, with or without the dashes or spaces
  /// (35202-1234567-1, 35202 1234567 1). A blank field passes unless
  /// [required].
  static FormFieldValidator<String> cnic({bool required = false}) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return required ? 'This field is required' : null;
      final digits = normaliseDigits(text).replaceAll(_cnicSeparators, '');
      return _cnic.hasMatch(digits) ? null : 'Enter the 13-digit CNIC';
    };
  }

  /// A phone number: 10 to 13 digits, or an international one starting
  /// with + or 00 (+92 300 1234567, 0092 300 1234567), with spaces, dashes
  /// and brackets allowed between them (0300-1234567, (042) 3576 1234). A
  /// blank field fails unless not [required].
  static FormFieldValidator<String> phone({bool required = true}) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return required ? 'This field is required' : null;
      final compact = normaliseDigits(text).replaceAll(_phoneSeparators, '');
      return _phone.hasMatch(compact) ? null : 'Enter a valid phone number';
    };
  }
}
