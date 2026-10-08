// Requires the `http` package. Add to pubspec.yaml:
//   dependencies:
//     http: ^1.2.2
// then run `flutter pub get`, or this file will fail to compile.
//
// SETUP (do this in your own Google Cloud project - I can't create or
// supply a key for you):
//   1. console.cloud.google.com -> create/select a project.
//   2. APIs & Services -> Library -> enable "Places API" (for
//      autocomplete + details) - and enable billing; Google requires a
//      billing account even within the free monthly quota.
//   3. APIs & Services -> Credentials -> Create API key.
//   4. IMPORTANT - restrict the key before shipping: under "Application
//      restrictions" pick Android (add your package name + SHA-1) or iOS
//      (add your bundle ID) rather than leaving it unrestricted, or
//      anyone who extracts it from your APK can run up your bill.
//   5. Paste the key below.
import 'dart:convert';
import 'package:http/http.dart' as http;

const String kGooglePlacesApiKey = 'PASTE_YOUR_GOOGLE_PLACES_API_KEY_HERE';

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

class GooglePlacesService {
  static const _base = 'https://maps.googleapis.com/maps/api/place';

  /// Returns address suggestions as the user types a station's location.
  /// [sessionToken] should be a fresh UUID per search session (autocomplete
  /// + the matching getPlaceDetails call) - Google bills autocomplete +
  /// details together as one cheaper "session" when you pass one.
  Future<List<PlacePrediction>> autocomplete(String input, {String? sessionToken}) async {
    if (input.trim().isEmpty) return [];
    if (kGooglePlacesApiKey == 'PASTE_YOUR_GOOGLE_PLACES_API_KEY_HERE') {
      throw StateError(
        'No Google Places API key set. See the setup steps at the top of '
        'google_places_service.dart.',
      );
    }

    final uri = Uri.parse('$_base/autocomplete/json').replace(queryParameters: {
      'input': input,
      'key': kGooglePlacesApiKey,
      if (sessionToken != null) 'sessiontoken': sessionToken,
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Places autocomplete failed: HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 'OK' && body['status'] != 'ZERO_RESULTS') {
      throw Exception('Places autocomplete error: ${body['status']} - ${body['error_message']}');
    }

    final predictions = (body['predictions'] as List<dynamic>? ?? []);
    return predictions
        .map((p) => PlacePrediction(
              description: p['description'] as String,
              placeId: p['place_id'] as String,
            ))
        .toList();
  }

  Future<PlaceDetails> getPlaceDetails(String placeId, {String? sessionToken}) async {
    final uri = Uri.parse('$_base/details/json').replace(queryParameters: {
      'place_id': placeId,
      'fields': 'formatted_address,geometry',
      'key': kGooglePlacesApiKey,
      if (sessionToken != null) 'sessiontoken': sessionToken,
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Place details failed: HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 'OK') {
      throw Exception('Place details error: ${body['status']}');
    }

    final result = body['result'] as Map<String, dynamic>;
    final location = result['geometry']['location'] as Map<String, dynamic>;

    return PlaceDetails(
      formattedAddress: result['formatted_address'] as String,
      latitude: (location['lat'] as num).toDouble(),
      longitude: (location['lng'] as num).toDouble(),
    );
  }
}
