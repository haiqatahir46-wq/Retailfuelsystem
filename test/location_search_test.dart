import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/navigation/select_station_flow.dart';
import 'package:petrolpump_flutter/screens/location_search_screen.dart';
import 'package:petrolpump_flutter/services/google_places_service.dart';
import 'package:petrolpump_flutter/state/app_session.dart';

/// A Places service whose every call waits on a [Completer] the test
/// completes, in any order, so slow and out-of-order replies can be staged.
class _FakePlaces implements GooglePlacesService {
  final searches = <(String, Completer<List<PlacePrediction>>)>[];
  final details = <(String, Completer<PlaceDetails>)>[];

  @override
  Future<List<PlacePrediction>> autocomplete(String input, {String? sessionToken}) {
    final reply = Completer<List<PlacePrediction>>();
    searches.add((input, reply));
    return reply.future;
  }

  @override
  Future<PlaceDetails> getPlaceDetails(String placeId, {String? sessionToken}) {
    final reply = Completer<PlaceDetails>();
    details.add((placeId, reply));
    return reply.future;
  }

  @override
  void close() {}
}

PlacePrediction _place(String description) => PlacePrediction(description: description, placeId: 'id-$description');

PlaceDetails _detailsOf(String address) => PlaceDetails(formattedAddress: address, latitude: 31, longitude: 74);

/// Past the search box's 400ms debounce, so the typed text is searched.
const _debounce = Duration(milliseconds: 450);

void main() {
  late _FakePlaces places;
  setUp(() => places = _FakePlaces());

  /// Opens the search on top of a plain page, so its own pop can be seen.
  Future<List<PlaceDetails>> openSearch(WidgetTester tester) async {
    final picked = <PlaceDetails>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LocationSearchScreen(service: places, onLocationSelected: picked.add),
                ),
              ),
              child: const Text('Open search'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open search'));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('a slow reply to an older search is dropped', (tester) async {
    await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'Lah');
    await tester.pump(_debounce);
    await tester.enterText(find.byType(TextField), 'Lahore');
    await tester.pump(_debounce);
    expect(places.searches.map((s) => s.$1), ['Lah', 'Lahore']);

    // The newer search answers first, then the older one.
    places.searches[1].$2.complete([_place('Lahore, Punjab')]);
    await tester.pump();
    places.searches[0].$2.complete([_place('Lahauri Gate')]);
    await tester.pump();
    expect(find.text('Lahore, Punjab'), findsOneWidget);
    expect(find.text('Lahauri Gate'), findsNothing);
  });

  testWidgets('a double tap on a result fetches its details once and closes once', (tester) async {
    final picked = await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'Pattoki');
    await tester.pump(_debounce);
    places.searches.single.$2.complete([_place('Pattoki, Kasur')]);
    await tester.pump();

    await tester.tap(find.text('Pattoki, Kasur'));
    await tester.tap(find.text('Pattoki, Kasur'));
    await tester.pump();
    expect(places.details, hasLength(1));

    places.details.single.$2.complete(_detailsOf('Main GT Road, Pattoki'));
    await tester.pumpAndSettle();
    expect(picked.map((d) => d.formattedAddress), ['Main GT Road, Pattoki']);
    expect(find.byType(LocationSearchScreen), findsNothing);
    expect(find.text('Open search'), findsOneWidget); // only the search was popped
  });

  testWidgets('an unexpected error shows the friendly message, not its own text', (tester) async {
    await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'Lahore');
    await tester.pump(_debounce);
    places.searches.single.$2.completeError(StateError('Bad state: internal detail'));
    await tester.pump();
    expect(find.text('Something went wrong with location search. Please try again.'), findsOneWidget);
    expect(find.textContaining('internal detail'), findsNothing);
  });

  testWidgets('a PlacesException shows its own message', (tester) async {
    await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'Lahore');
    await tester.pump(_debounce);
    places.searches.single.$2.completeError(const PlacesException('Location search is busy right now.'));
    await tester.pump();
    expect(find.text('Location search is busy right now.'), findsOneWidget);
  });

  testWidgets('Select Station -> edit sets the station\'s location from the picked place', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final session = AppSession()..signInDemo(email: 'owner@example.com');
    addTearDown(session.dispose);
    await tester.pumpWidget(
      AppSessionScope(session: session, child: MaterialApp(home: SelectStationFlow(placesService: places))),
    );

    // The second station's pencil.
    await tester.tap(find.byTooltip('Edit location').at(1));
    await tester.pumpAndSettle();
    expect(find.byType(LocationSearchScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Kasur');
    await tester.pump(_debounce);
    places.searches.single.$2.complete([_place('Kasur, Punjab')]);
    await tester.pump();
    await tester.tap(find.text('Kasur, Punjab'));
    await tester.pump();
    places.details.single.$2.complete(_detailsOf('Ferozepur Road, Kasur'));
    await tester.pumpAndSettle();

    // Back on Select Station, with the new location under the station's
    // unchanged name.
    expect(find.byType(LocationSearchScreen), findsNothing);
    expect(session.stationById('station-2')!.location, 'Ferozepur Road, Kasur');
    expect(session.stationById('station-2')!.name, 'Demo Station 2');
    expect(find.text('Ferozepur Road, Kasur'), findsOneWidget);
  });
}
