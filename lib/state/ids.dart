var _counter = 0;

/// A new id for something created in the app (a station, a staff member),
/// e.g. `newId('station')` -> 'station-MG7K2Q1X-3'. Purchase orders get a
/// human-readable number from [nextPoNumber] instead.
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

/// 'PO-2026-0063' -> its sequence number, 63. The year is ignored.
final _poNumber = RegExp(r'^PO-\d{4}-(\d+)$');

/// The PO number for a new order, in the same `PO-<year>-<seq>` form as the
/// demo orders (e.g. 'PO-2026-0064'), where an owner reads and quotes it.
///
/// The sequence carries on after the highest one in [existing], whatever its
/// year, so the new number is above every existing one and can't repeat
/// any of them. Pass every order the owner has, demo and placed this
/// session, across all their stations. Numbers in another form are skipped;
/// with none in this form the sequence starts at 0001. The year is [now]'s,
/// and the sequence is zero-padded to 4 digits (it simply grows past 9999).
///
/// Once a backend exists, the database's own sequence replaces this.
String nextPoNumber(Iterable<String> existing, DateTime now) {
  var highest = 0;
  for (final number in existing) {
    final match = _poNumber.firstMatch(number);
    final seq = match == null ? null : int.tryParse(match.group(1)!);
    if (seq != null && seq > highest) highest = seq;
  }
  return 'PO-${now.year}-${(highest + 1).toString().padLeft(4, '0')}';
}
