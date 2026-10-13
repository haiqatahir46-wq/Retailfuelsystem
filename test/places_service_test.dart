import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petrolpump_flutter/services/google_places_service.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

Matcher _placesError([Object? messageMatcher]) => isA<PlacesException>().having(
      (e) => e.message,
      'message',
      messageMatcher ?? isNotEmpty,
    );

void main() {
  group('autocomplete', () {
    test('posts the query to Places (New) and parses place predictions', () async {
      late http.Request sent;
      final service = GooglePlacesService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          sent = request;
          return _json({
            'suggestions': [
              {
                'placePrediction': {
                  'placeId': 'abc123',
                  'text': {'text': 'Pattoki, Kasur District, Pakistan'},
                },
              },
              // A search-phrase suggestion, not a place: skipped.
              {
                'queryPrediction': {
                  'text': {'text': 'petrol pumps near Pattoki'},
                },
              },
              // Missing an id: skipped rather than crashing.
              {
                'placePrediction': {
                  'text': {'text': 'No id'},
                },
              },
            ],
          });
        }),
      );

      final results = await service.autocomplete(' Pattoki ', sessionToken: 'session-1');

      expect(results, hasLength(1));
      expect(results.single.placeId, 'abc123');
      expect(results.single.description, 'Pattoki, Kasur District, Pakistan');

      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'https://places.googleapis.com/v1/places:autocomplete');
      expect(sent.headers['X-Goog-Api-Key'], 'test-key');
      expect(sent.headers['Content-Type'], startsWith('application/json'));
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['input'], 'Pattoki');
      expect(body['sessionToken'], 'session-1');
      expect(body['includedRegionCodes'], ['pk']);
    });

    test('no suggestions field means no results', () async {
      final service = GooglePlacesService(apiKey: 'k', client: MockClient((_) async => _json({})));
      expect(await service.autocomplete('zzzz'), isEmpty);
    });

    test('blank input returns nothing without a request', () async {
      var calls = 0;
      final service = GooglePlacesService(
        apiKey: 'k',
        client: MockClient((_) async {
          calls++;
          return _json({});
        }),
      );
      expect(await service.autocomplete('   '), isEmpty);
      expect(calls, 0);
    });
  });

  group('getPlaceDetails', () {
    test('requests only the needed fields and parses address + location', () async {
      late http.Request sent;
      final service = GooglePlacesService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          sent = request;
          return _json({
            'formattedAddress': 'Main Bazar, Pattoki, Pakistan',
            'location': {'latitude': 31.0215, 'longitude': 73.8500},
          });
        }),
      );

      final details = await service.getPlaceDetails('abc123', sessionToken: 'session-1');

      expect(details.formattedAddress, 'Main Bazar, Pattoki, Pakistan');
      expect(details.latitude, 31.0215);
      expect(details.longitude, 73.85);

      expect(sent.method, 'GET');
      expect(sent.url.host, 'places.googleapis.com');
      expect(sent.url.path, '/v1/places/abc123');
      expect(sent.url.queryParameters['sessionToken'], 'session-1');
      expect(sent.headers['X-Goog-Api-Key'], 'test-key');
      expect(sent.headers['X-Goog-FieldMask'], 'formattedAddress,location');
    });

    test('a response missing the location is a PlacesException', () async {
      final service = GooglePlacesService(
        apiKey: 'k',
        client: MockClient((_) async => _json({'formattedAddress': 'Somewhere'})),
      );
      await expectLater(service.getPlaceDetails('abc'), throwsA(_placesError()));
    });

    test('integer coordinates are accepted', () async {
      final service = GooglePlacesService(
        apiKey: 'k',
        client: MockClient((_) async => _json({
              'formattedAddress': 'Somewhere',
              'location': {'latitude': 31, 'longitude': 74},
            })),
      );
      final details = await service.getPlaceDetails('abc');
      expect(details.latitude, 31.0);
      expect(details.longitude, 74.0);
    });
  });

  group('errors', () {
    test('an error body surfaces Google\'s message', () async {
      final service = GooglePlacesService(
        apiKey: 'bad-key',
        client: MockClient((_) async => _json({
              'error': {'code': 400, 'message': 'API key not valid. Please pass a valid API key.', 'status': 'INVALID_ARGUMENT'},
            }, 400)),
      );
      await expectLater(
        service.autocomplete('Pattoki'),
        throwsA(_placesError(contains('API key not valid'))),
      );
    });

    test('a non-200 without an error body still gives a readable message', () async {
      final service = GooglePlacesService(
        apiKey: 'k',
        client: MockClient((_) async => http.Response('<html>Bad gateway</html>', 502)),
      );
      await expectLater(service.autocomplete('Pattoki'), throwsA(_placesError(contains('502'))));
    });

    test('malformed JSON is a PlacesException', () async {
      final service = GooglePlacesService(
        apiKey: 'k',
        client: MockClient((_) async => http.Response('{not json', 200)),
      );
      await expectLater(service.autocomplete('Pattoki'), throwsA(_placesError()));
      await expectLater(service.getPlaceDetails('abc'), throwsA(_placesError()));
    });

    test('JSON of the wrong shape is a PlacesException', () async {
      final service = GooglePlacesService(
        apiKey: 'k',
        client: MockClient((_) async => _json({'suggestions': 'oops'})),
      );
      await expectLater(service.autocomplete('Pattoki'), throwsA(_placesError()));

      final listBody = GooglePlacesService(apiKey: 'k', client: MockClient((_) async => _json([1, 2])));
      await expectLater(listBody.autocomplete('Pattoki'), throwsA(_placesError()));
    });

    test('a network failure is a PlacesException', () async {
      final service = GooglePlacesService(
        apiKey: 'k',
        client: MockClient((request) async => throw http.ClientException('offline', request.url)),
      );
      await expectLater(service.autocomplete('Pattoki'), throwsA(_placesError()));
    });

    test('a missing key is a PlacesException and sends nothing', () async {
      var calls = 0;
      final service = GooglePlacesService(
        apiKey: '',
        client: MockClient((_) async {
          calls++;
          return _json({});
        }),
      );
      await expectLater(service.autocomplete('Pattoki'), throwsA(_placesError(contains('PLACES_API_KEY'))));
      await expectLater(service.getPlaceDetails('abc'), throwsA(_placesError(contains('PLACES_API_KEY'))));
      expect(calls, 0);
    });

    test('PlacesException.toString is just the message', () {
      expect(const PlacesException('Friendly text').toString(), 'Friendly text');
    });
  });

  test('newPlacesSessionToken makes distinct version 4 UUIDs', () {
    final uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    final tokens = List.generate(20, (_) => newPlacesSessionToken());
    for (final t in tokens) {
      expect(t, matches(uuid));
    }
    expect(tokens.toSet(), hasLength(tokens.length));
  });
}
