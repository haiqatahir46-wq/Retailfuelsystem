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

/// The number typed in [text], or null if it isn't one. Commas and spaces
/// are ignored. Only plain decimal notation counts, so "1e5", "NaN" and
/// "Infinity" are rejected, and so is anything too big to be finite.
/// Negative numbers give null unless [allowNegative].
double? parseNumber(String text, {bool allowNegative = false}) {
  final cleaned = text.replaceAll(_separators, '');
  if (!_decimal.hasMatch(cleaned)) return null;
  final value = double.tryParse(cleaned);
  if (value == null || !value.isFinite) return null;
  if (!allowNegative && value < 0) return null;
  return value;
}

/// The whole number typed in [text] (commas and spaces ignored), or null if
/// it isn't one or is too big for an int. Negative numbers give null unless
/// [allowNegative].
int? parseWholeNumber(String text, {bool allowNegative = false}) {
  final cleaned = text.replaceAll(_separators, '');
  if (!_wholeNumber.hasMatch(cleaned)) return null;
  final value = int.tryParse(cleaned);
  if (value == null || (!allowNegative && value < 0)) return null;
  return value;
}

/// Form validators. Each returns a [FormFieldValidator]: null when the value
/// is fine, otherwise the message shown under the field.
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

  /// A number above 0 (commas allowed), and no more than [max] when given.
  /// [maxMessage] replaces the default message for a value over [max].
  static FormFieldValidator<String> positiveNumber({double? max, String? maxMessage}) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return 'Enter an amount';
      final number = parseNumber(text, allowNegative: true);
      if (number == null) return 'Enter a number, e.g. 5,000';
      if (number <= 0) return 'Must be more than 0';
      if (max != null && number > max) return maxMessage ?? 'Must be no more than ${formatThousands(max)}';
      return null;
    };
  }

  /// A whole number from [min] to [max] (commas allowed). When not
  /// [required], a blank field passes; the caller reads it as its default.
  static FormFieldValidator<String> intInRange(int min, int max, {bool required = true}) {
    return wholeNumber(min: min, max: max, required: required);
  }

  /// A whole number of at least [min], and no more than [max] when given.
  /// When not [required], a blank field passes.
  static FormFieldValidator<String> wholeNumber({int min = 0, int? max, bool required = true}) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return required ? 'This field is required' : null;
      final cleaned = text.replaceAll(_separators, '');
      if (!_wholeNumber.hasMatch(cleaned)) return 'Enter a whole number';
      final number = int.tryParse(cleaned);
      final range = max == null ? 'Enter $min or more' : 'Enter a number from $min to $max';
      if (number == null || number < min || (max != null && number > max)) return range;
      return null;
    };
  }

  /// An email address; a blank field passes unless [required].
  static FormFieldValidator<String> email({bool required = false}) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return required ? 'This field is required' : null;
      return _email.hasMatch(text) ? null : 'Enter a valid email address';
    };
  }

  /// A Pakistani CNIC: 13 digits, with or without the dashes
  /// (35202-1234567-1). A blank field passes unless [required].
  static FormFieldValidator<String> cnic({bool required = false}) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return required ? 'This field is required' : null;
      return RegExp(r'^\d{13}$').hasMatch(text.replaceAll('-', '')) ? null : 'Enter the 13-digit CNIC';
    };
  }

  /// A phone number: 10 to 13 digits, optionally starting with +, with
  /// dashes and spaces allowed (0300-1234567, +92 300 1234567). A blank
  /// field fails unless not [required].
  static FormFieldValidator<String> phone({bool required = true}) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return required ? 'This field is required' : null;
      final digits = text.replaceAll(RegExp(r'[\s-]'), '');
      return RegExp(r'^\+?\d{10,13}$').hasMatch(digits) ? null : 'Enter a valid phone number';
    };
  }

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
