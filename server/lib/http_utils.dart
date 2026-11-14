import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

/// A request the API refuses, with a message that is safe to show the user.
/// The error middleware turns it into `{"error": message}` with [status].
class ApiError implements Exception {
  final int status;
  final String message;
  const ApiError(this.status, this.message);

  @override
  String toString() => 'ApiError($status): $message';
}

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonResponse(Object? body, {int status = 200}) =>
    Response(status, body: jsonEncode(body), headers: _jsonHeaders);

/// An already-encoded JSON body, e.g. a cached response read from Redis.
Response rawJsonResponse(String body) => Response(200, body: body, headers: _jsonHeaders);

/// The request body as a JSON object; an empty body reads as `{}`.
Future<Map<String, dynamic>> readJson(Request request) async {
  final text = await request.readAsString();
  if (text.trim().isEmpty) return {};
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    throw const ApiError(400, 'The request body is not valid JSON.');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const ApiError(400, 'The request body must be a JSON object.');
  }
  return decoded;
}

String requireString(Map<String, dynamic> body, String key, {int maxLength = 200, bool trim = true}) {
  final value = body[key];
  if (value is! String) throw ApiError(422, '"$key" is required.');
  final text = trim ? value.trim() : value;
  if (text.isEmpty) throw ApiError(422, '"$key" is required.');
  if (text.length > maxLength) throw ApiError(422, '"$key" is too long (max $maxLength characters).');
  return text;
}

/// A trimmed string, or null when [key] is absent. An empty string stays
/// empty, so a client can clear an optional field.
String? optionalString(Map<String, dynamic> body, String key, {int maxLength = 200}) {
  final value = body[key];
  if (value == null) return null;
  if (value is! String) throw ApiError(422, '"$key" must be text.');
  final text = value.trim();
  if (text.length > maxLength) throw ApiError(422, '"$key" is too long (max $maxLength characters).');
  return text;
}

double requireNumber(Map<String, dynamic> body, String key, {required double min, required double max}) {
  final value = body[key];
  if (value is! num || !value.isFinite) throw ApiError(422, '"$key" must be a number.');
  if (value < min) throw ApiError(422, '"$key" must be at least ${formatThousands(min)}.');
  if (value > max) throw ApiError(422, '"$key" must be at most ${formatThousands(max)}.');
  return value.toDouble();
}

/// A whole number from [min] to [max]. JSON `3.0` counts as 3.
int requireInt(Map<String, dynamic> body, String key, {required int min, required int max}) {
  final value = body[key];
  if (value is! num || !value.isFinite || value != value.roundToDouble()) {
    throw ApiError(422, '"$key" must be a whole number.');
  }
  final number = value.toInt();
  if (number < min || number > max) throw ApiError(422, '"$key" must be from $min to $max.');
  return number;
}

/// A record id from the URL or the body. Ids are sent as strings (the app's
/// models keep ids as strings) but a bare number is accepted too. Anything
/// else is "not found", since no such record can exist.
int parseId(Object? raw) {
  final id = raw is int ? raw : int.tryParse('${raw ?? ''}');
  if (id == null || id <= 0) throw const ApiError(404, 'Not found.');
  return id;
}

/// "1512000" -> "1,512,000", rounded down: a limit named in a message must
/// itself pass the check.
String formatThousands(double value) {
  final digits = value.floor().abs().toString();
  final grouped = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return value < 0 ? '-$grouped' : grouped;
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
bool isValidEmail(String text) => _emailPattern.hasMatch(text);

/// Lets the Flutter web build (served from another port) call the API. The
/// API uses bearer tokens, not cookies, so allowing an origin doesn't let
/// another site act as a signed-in user.
Middleware cors(String origin) => (inner) => (request) async {
      final headers = {
        'access-control-allow-origin': origin,
        'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
        'access-control-allow-headers': 'authorization, content-type',
        'access-control-max-age': '600',
      };
      if (request.method == 'OPTIONS') return Response(204, headers: headers);
      final response = await inner(request);
      return response.change(headers: headers);
    };

/// Turns an [ApiError] into its JSON reply and anything unexpected into a
/// generic 500. The real error is logged on the server, never sent to the
/// client, because database errors can name tables, columns and values.
Middleware handleErrors() => (inner) => (request) async {
      try {
        return await inner(request);
      } on ApiError catch (error) {
        return jsonResponse({'error': error.message}, status: error.status);
      } catch (error, stack) {
        stderr.writeln('${DateTime.now().toIso8601String()} ${request.method} /${request.url.path} failed: $error\n$stack');
        return jsonResponse({'error': 'Something went wrong on the server.'}, status: 500);
      }
    };
