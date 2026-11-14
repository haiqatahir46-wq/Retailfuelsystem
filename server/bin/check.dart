import 'dart:io';

import 'package:rfms_server/cache.dart';
import 'package:rfms_server/config.dart';
import 'package:rfms_server/database.dart';

/// Tests both connections and checks the tables: `dart run bin/check.dart`
/// from the server folder. It changes nothing. It lists every table in the
/// database and reports any table or column the API needs that is missing,
/// which `dart run bin/migrate.dart` adds.
Future<void> main() async {
  final AppConfig config;
  try {
    config = AppConfig.load();
  } on ConfigException catch (error) {
    stderr.writeln(error);
    exitCode = 64;
    return;
  }

  final postgresOk = await _checkPostgres(config);
  stdout.writeln();
  final redisOk = await _checkRedis(config);
  if (!postgresOk || !redisOk) exitCode = 1;
}

Future<bool> _checkPostgres(AppConfig config) async {
  final where = '${config.dbHost}:${config.dbPort}/${config.dbName} as ${config.dbUser}';
  try {
    final connection = await openConnection(config);
    try {
      final version = (await connection.execute('SHOW server_version')).first[0];
      stdout.writeln('PostgreSQL: connected to $where (version $version)');

      final rows = await connection.execute('''
        SELECT c.table_name, c.column_name, c.data_type, c.is_nullable
        FROM information_schema.columns c
        JOIN information_schema.tables t
          ON t.table_schema = c.table_schema AND t.table_name = c.table_name
        WHERE t.table_type = 'BASE TABLE' AND c.table_schema = '$appSchema'
        ORDER BY c.table_name, c.ordinal_position''');
      final tables = <String, List<String>>{};
      for (final row in rows) {
        final nullable = row[3] == 'YES' ? '' : ' not null';
        tables.putIfAbsent(row[0] as String, () => []).add('${row[1]} ${row[2]}$nullable');
      }

      stdout.writeln('\nTables in $appSchema (${tables.length}):');
      for (final entry in tables.entries) {
        stdout.writeln('  ${entry.key} (${entry.value.length} columns)');
      }

      final problems = <String>[];
      for (final entry in requiredColumns.entries) {
        final columns = tables[entry.key]?.map((c) => c.split(' ').first).toSet();
        if (columns == null) {
          problems.add('missing table ${entry.key}');
          continue;
        }
        final missing = entry.value.where((column) => !columns.contains(column)).toList();
        if (missing.isNotEmpty) problems.add('${entry.key} is missing: ${missing.join(', ')}');
      }
      if (problems.isEmpty) {
        stdout.writeln('\nEverything the API needs is there (${requiredColumns.length} tables).');
      } else {
        stdout.writeln('\nMissing for the API (${problems.length}):');
        for (final problem in problems) {
          stdout.writeln('  - $problem');
        }
        stdout.writeln('Add them with: dart run bin/migrate.dart   (add --seed for demo data)');
      }
      return true;
    } finally {
      await connection.close();
    }
  } catch (error) {
    stdout.writeln('PostgreSQL: could NOT connect to $where');
    stdout.writeln('  $error');
    stdout.writeln('  Check DB_HOST, DB_PORT, DB_NAME, DB_USER and DB_PASSWORD in .env, and that the database exists.');
    return false;
  }
}

Future<bool> _checkRedis(AppConfig config) async {
  final where = '${config.redisHost}:${config.redisPort}${config.redisTls ? ' (TLS)' : ''}';
  final cache = Cache(config);
  try {
    final pong = await cache.ping();
    final version = await cache.serverVersion();
    stdout.writeln('Redis: connected to $where (version ${version ?? 'unknown'}, PING -> $pong)');
    return true;
  } catch (error) {
    stdout.writeln('Redis: could NOT connect to $where');
    stdout.writeln('  $error');
    stdout.writeln('  Check REDIS_URL in .env (the redis://... URL from the Redis Cloud console), or');
    stdout.writeln('  REDIS_HOST, REDIS_PORT and REDIS_PASSWORD for a local Redis. If the database has');
    stdout.writeln('  TLS turned on, the URL must start with rediss:// (two s\'s).');
    return false;
  } finally {
    await cache.close();
  }
}
