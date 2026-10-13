// Station location search, backed by Google's Places API (New):
//   autocomplete: POST https://places.googleapis.com/v1/places:autocomplete
//   details:      GET  https://places.googleapis.com/v1/places/{placeId}
//
// SETUP (in your own Google Cloud project - no key ships with the app):
//   1. console.cloud.google.com -> create/select a project.
//   2. APIs & Services -> Library -> enable "Places API (New)". Keep a
//      billing account attached; Google requires one even within the free
//      monthly quota.
//   3. APIs & Services -> Credentials -> Create API key.
//   4. Restrict the key: under "API restrictions" allow only
//      "Places API (New)", so a leaked key can't be spent on anything else.
//   5. Run the app with the key passed in at build time, never pasted into
//      source:
//        flutter run --dart-define=PLACES_API_KEY=your-key
//
// Android/iOS "application restrictions" (package name + SHA-1, bundle id)
// do NOT protect this key: they only apply to Google's own Maps SDKs, and
// this service makes plain HTTPS calls, so anyone who pulls the key out of
// the app binary can use it. The long-term fix is a small backend proxy
// (e.g. a Supabase Edge Function) that holds the key and forwards these two
// requests; the app would then call the proxy instead of Google.
//
// The web build can't use this at all: Google's Places web service isn't
// callable from a browser, so on web every call throws a PlacesException
// saying so. The same proxy would make it work there too.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Supplied at build time with --dart-define=PLACES_API_KEY=...; empty when
/// it wasn't.
const String kPlacesApiKey = String.fromEnvironment('PLACES_API_KEY');

/// A location-search failure with a [message] that's safe to show the user
/// as-is (no stack traces, no "Bad state: ..." prefixes).
class PlacesException implements Exception {
  final String message;

  const PlacesException(this.message);

  @override
  String toString() => message;
}

class PlacePrediction {
  final String description;
  final String placeId;

  const PlacePrediction({required this.description, required this.placeId});
}

class PlaceDetails {
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const PlaceDetails({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });
}

/// A fresh Places session token: a random (version 4) UUID. Google bills
/// the autocomplete requests and the one details request that follows them
/// as a single session when they share a token, so a screen creates one
/// per search and a new one after the user picks a result.
String newPlacesSessionToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Every failure surfaces as a [PlacesException], never a raw parsing or
/// network error.
class GooglePlacesService {
  /// [client] lets tests supply a fake (e.g. `MockClient` from
  /// package:http/testing.dart); [apiKey] defaults to [kPlacesApiKey]. A
  /// client passed in is the caller's to close; one created here is closed
  /// by [close].
  GooglePlacesService({http.Client? client, String apiKey = kPlacesApiKey})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _apiKey = apiKey;

  final http.Client _client;
  final bool _ownsClient;
  final String _apiKey;

  static const _host = 'places.googleapis.com';
  static const _timeout = Duration(seconds: 10);
  static const _malformedMessage = 'Location search sent back an unexpected response. Please try again.';

  /// Releases the HTTP connection. Call from the owning State's dispose.
  void close() {
    if (_ownsClient) _client.close();
  }

  /// Address suggestions (limited to Pakistan) as the user types a
  /// station's location. Pass the same [sessionToken] to every call in one
  /// search and to the [getPlaceDetails] call that ends it.
  Future<List<PlacePrediction>> autocomplete(String input, {String? sessionToken}) async {
    final query = input.trim();
    if (query.isEmpty) return const [];
    _checkUsable();

    final body = await _send(
      () => _client.post(
        Uri.https(_host, '/v1/places:autocomplete'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: jsonEncode({
          'input': query,
          'sessionToken': ?sessionToken,
          'includedRegionCodes': ['pk'],
        }),
      ),
    );

    // Places (New) leaves "suggestions" out entirely when nothing matches.
    final suggestions = body['suggestions'];
    if (suggestions == null) return const [];
    if (suggestions is! List) throw const PlacesException(_malformedMessage);

    final results = <PlacePrediction>[];
    for (final suggestion in suggestions) {
      // Query predictions (search phrases rather than places) and anything
      // missing an id or a text are skipped; they can't be selected.
      if (suggestion is! Map) continue;
      final prediction = suggestion['placePrediction'];
      if (prediction is! Map) continue;
      final placeId = prediction['placeId'];
      final text = prediction['text'];
      final description = text is Map ? text['text'] : null;
      if (placeId is String && placeId.isNotEmpty && description is String) {
        results.add(PlacePrediction(description: description, placeId: placeId));
      }
    }
    return results;
  }

  /// The address and coordinates of one suggestion. Passing the search's
  /// [sessionToken] here closes that billing session.
  Future<PlaceDetails> getPlaceDetails(String placeId, {String? sessionToken}) async {
    _checkUsable();

    final body = await _send(
      () => _client.get(
        Uri(
          scheme: 'https',
          host: _host,
          pathSegments: ['v1', 'places', placeId],
          queryParameters: sessionToken == null ? null : {'sessionToken': sessionToken},
        ),
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'formattedAddress,location',
        },
      ),
    );

    final address = body['formattedAddress'];
    final location = body['location'];
    final latitude = location is Map ? location['latitude'] : null;
    final longitude = location is Map ? location['longitude'] : null;
    if (address is! String || latitude is! num || longitude is! num) {
      throw const PlacesException(_malformedMessage);
    }
    return PlaceDetails(
      formattedAddress: address,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }

  void _checkUsable() {
    if (kIsWeb) {
      throw const PlacesException(
        "Location search isn't available in the web version yet, because "
        "Google's Places web service can't be called from a browser. "
        'Please use the Android or iOS app to set a location.',
      );
    }
    if (_apiKey.isEmpty) {
      throw const PlacesException(
        "Location search isn't set up yet: no Places API key was provided. "
        'Run the app with --dart-define=PLACES_API_KEY=<your key>.',
      );
    }
  }

  /// Runs [request] with a timeout and returns its JSON object body, turning
  /// every way it can fail into a [PlacesException].
  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw const PlacesException('Location search took too long to respond. Check your connection and try again.');
    } on http.ClientException {
      throw const PlacesException("Couldn't reach Google Places. Check your internet connection and try again.");
    }

    // Decode the bytes as UTF-8 ourselves: response.body falls back to
    // Latin-1 when the server omits a charset, which would garble Urdu
    // place names.
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode != 200) {
      final apiMessage = _apiErrorMessage(decoded);
      throw PlacesException(
        apiMessage != null
            ? 'Location search failed: $apiMessage'
            : 'Location search failed (HTTP ${response.statusCode}). Please try again.',
      );
    }
    if (decoded is! Map<String, dynamic>) throw const PlacesException(_malformedMessage);
    return decoded;
  }

  /// Google's own explanation from an error body
  /// (`{"error": {"message": "..."}}`), if there is one.
  static String? _apiErrorMessage(Object? decoded) {
    if (decoded is! Map) return null;
    final error = decoded['error'];
    if (error is! Map) return null;
    final message = error['message'];
    return message is String && message.trim().isNotEmpty ? message.trim() : null;
  }
}
