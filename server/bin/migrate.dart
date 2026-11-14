import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:rfms_server/config.dart';
import 'package:rfms_server/database.dart';

/// Brings the database's tables up to date: `dart run bin/migrate.dart`
/// from the server folder. Each file in migrations/ runs once, in name
/// order, inside a transaction (all of it applies or none of it does), and
/// is recorded in the schema_migrations table, so running this again only
/// applies new files.
///
///   --seed         also load the demo data (seed/demo.sql); does nothing
///                  if it's already loaded
///   --remove-demo  delete the demo owner and everything that belongs to
///                  them (seed/remove_demo.sql); nothing else is touched
Future<void> main(List<String> args) async {
  final AppConfig config;
  try {
    config = AppConfig.load();
  } on ConfigException catch (error) {
    stderr.writeln(error);
    exitCode = 64;
    return;
  }

  final connection = await openConnection(config);
  try {
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS $appSchema.schema_migrations (
        version    varchar(200) PRIMARY KEY,
        applied_at timestamp NOT NULL DEFAULT now()
      )''');
    final applied = {
      for (final row in await connection.execute('SELECT version FROM $appSchema.schema_migrations')) row[0] as String,
    };

    final files = Directory('migrations')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.sql'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    var ran = 0;
    for (final file in files) {
      final version = file.uri.pathSegments.last;
      if (applied.contains(version)) continue;
      final sql = await file.readAsString();
      await connection.runTx((tx) async {
        // Simple mode runs a whole file of statements at once.
        await tx.execute(sql, queryMode: QueryMode.simple);
        await tx.execute(
          Sql.named('INSERT INTO $appSchema.schema_migrations (version) VALUES (@version)'),
          parameters: {'version': version},
        );
      });
      stdout.writeln('Applied $version');
      ran++;
    }
    stdout.writeln(ran == 0 ? 'Tables are up to date.' : 'Applied $ran migration(s).');

    if (args.contains('--remove-demo')) {
      await connection.runTx((tx) async {
        await tx.execute(await File('seed/remove_demo.sql').readAsString(), queryMode: QueryMode.simple);
      });
      stdout.writeln('Demo data removed (if it was there).');
    }
    if (args.contains('--seed')) {
      await connection.runTx((tx) async {
        await tx.execute(await File('seed/demo.sql').readAsString(), queryMode: QueryMode.simple);
      });
      stdout.writeln('Demo data ready. Sign in as owner@parco.example / demo1234.');
    }
  } catch (error) {
    stderr.writeln('Failed: $error');
    stderr.writeln('Nothing from the failing step was kept (it runs in a transaction).');
    exitCode = 1;
  } finally {
    await connection.close();
  }
}
