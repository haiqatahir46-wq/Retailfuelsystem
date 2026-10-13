var _counter = 0;

/// A new id for something created in the app (a station, a staff member, a
/// purchase order), e.g. `newId('station')` -> 'station-MG7K2Q1X-3'.
///
/// The timestamp (milliseconds, base 36) keeps ids apart across app runs and
/// the counter keeps them apart within one, even for two calls in the same
/// millisecond. That replaces the old `list.length + 1` ids, which repeated
/// as soon as a list started from demo data: the first station added was
/// 'station-2', which already belonged to a demo station with its own sales.
///
/// Every id has two dashes after the prefix, so it can never equal a demo
/// id such as 'station-1' or 's1', and a new station never picks up a demo
/// station's data. Once a backend exists, ids come from the database instead.
String newId(String prefix) {
  _counter++;
  final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
  return '$prefix-$stamp-$_counter';
}
