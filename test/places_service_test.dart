import 'dart:async';
import 'dart:convert';
import 'dart:io' show HandshakeException;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petrolpump_flutter/services/google_places_service.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

TypeMatcher<PlacesException> _placesError([Object? messageMatcher]) => isA<PlacesException>().having(
      (e) => e.message,
      'message',
      messageMatcher ?? isNotEmpty,
    );

/// Google's reply to a request with a bad key, project details and all.
const _googleDetail = 'API key not valid. Please pass a valid API key. '
    'Visit https://console.developers.google.com/apis/api/places.googleapis.com/overview?project=123456789012';

/// A service whose every request gets [status] with Google's error body.
GooglePlacesService _replying(int status) => GooglePlacesService(
      apiKey: 'k',
      client: MockClient((_) async => _json({
            'error': {'code': status, 'message': _googleDetail, 'status': 'SOME_STATUS'},
          }, status)),
    );

/// The message of the PlacesException [service]'s autocomplete throws.
Future<String> _messageFor(GooglePlacesService service) async {
  try {
    await service.autocomplete('Pattoki');
  } on PlacesException catch (e) {
    return e.message;
  }
  fail('autocomplete did not throw');
}

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
    test('Google\'s error text stays out of the message, in debugMessage only', () async {
      await expectLater(
        _replying(400).autocomplete('Pattoki'),
        throwsA(isA<PlacesException>()
            .having((e) => e.message, 'message', isNot(contains('API key not valid')))
            .having((e) => e.message, 'message', isNot(contains('123456789012')))
            .having((e) => e.message, 'message', isNot(contains('console')))
            .having((e) => e.toString(), 'toString', isNot(contains('123456789012')))
            .having((e) => e.debugMessage, 'debugMessage', allOf(contains('HTTP 400'), contains('API key not valid')))),
      );
    });

    test('each kind of HTTP error gets its own fixed message', () async {
      final setup = await _messageFor(_replying(400));
      expect(setup, contains('Google Places setup'));
      expect(await _messageFor(_replying(401)), setup);
      expect(await _messageFor(_replying(403)), setup);

      expect(await _messageFor(_replying(429)), contains('too many requests'));

      final server = await _messageFor(_replying(500));
      expect(server, contains('Google Places is having trouble'));
      expect(await _messageFor(_replying(502)), server);
      expect(await _messageFor(_replying(503)), server);

      // Anything else still reads sensibly, and only quotes the status.
      expect(await _messageFor(_replying(404)), 'Location search failed (HTTP 404). Please try again.');

      // Every one of them is different from the others and free of Google's text.
      final all = [setup, await _messageFor(_replying(429)), server];
      expect(all.toSet(), hasLength(3));
      for (final m in all) {
        expect(m, isNot(contains('API key not valid')));
      }
    });

    test('a non-200 without an error body still gives a readable message', () async {
      final service = GooglePlacesService(
        apiKey: 'k',
        client: MockClient((_) async => http.Response('<html>Bad gateway</html>', 502)),
      );
      await expectLater(
        service.autocomplete('Pattoki'),
        throwsA(_placesError(contains('Google Places is having trouble'))
            .having((e) => e.debugMessage, 'debugMessage', 'HTTP 502')),
      );
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
      await expectLater(service.autocomplete('Pattoki'), throwsA(_placesError(contains("Couldn't reach Google Places"))));
    });

    test('any other exception from the HTTP stack is the connection message, not a raw error', () async {
      for (final error in <Object>[
        const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
        StateError('socket closed'),
        Exception('something odd'),
      ]) {
        final service = GooglePlacesService(apiKey: 'k', client: MockClient((_) async => throw error));
        await expectLater(
          service.autocomplete('Pattoki'),
          throwsA(_placesError(contains("Couldn't reach Google Places"))
              .having((e) => e.debugMessage, 'debugMessage', contains('$error'))),
          reason: '$error',
        );
        await expectLater(service.getPlaceDetails('abc'), throwsA(_placesError()), reason: '$error');
      }
    });

    // testWidgets for its fake clock: the 10 s timeout passes instantly.
    testWidgets('a request that never answers times out after 10 s', (tester) async {
      final service = GooglePlacesService(
        apiKey: 'k',
        client: MockClient((_) => Completer<http.Response>().future),
      );
      Object? error;
      unawaited(service.autocomplete('Pattoki').then<void>((_) {}, onError: (Object e) => error = e));

      await tester.pump(const Duration(seconds: 9));
      expect(error, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(error, _placesError(contains('took too long')));
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
      expect(const PlacesException('Friendly text', debugMessage: 'secret detail').toString(), 'Friendly text');
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
