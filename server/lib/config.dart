import 'dart:io';

/// The server's settings, read from `server/.env`. A real environment
/// variable with the same name wins over the file, so a deployed server can
/// be configured without one. Secrets live only here: the file is
/// git-ignored, and the Flutter app never sees any of them.
class AppConfig {
  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUser;
  final String dbPassword;
  final bool dbSsl;
  final String redisHost;
  final int redisPort;

  /// Redis 6+ ACL user. Empty sends the password alone, which signs in as
  /// Redis's `default` user (what Redis Cloud gives every new database).
  final String redisUsername;
  final String redisPassword;

  /// Connect over TLS (a `rediss://` URL), which hosted Redis may require.
  final bool redisTls;
  final int serverPort;
  final String corsOrigin;

  /// Where "today" and every sales period begin at midnight.
  final String timeZone;

  const AppConfig({
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUser,
    required this.dbPassword,
    required this.dbSsl,
    required this.redisHost,
    required this.redisPort,
    required this.redisUsername,
    required this.redisPassword,
    required this.redisTls,
    required this.serverPort,
    required this.corsOrigin,
    required this.timeZone,
  });

  /// Reads [path] (relative to where the command runs, normally `server/`).
  /// Throws [ConfigException] with a fix-it message when a required value
  /// is missing or a port isn't a number.
  factory AppConfig.load([String path = '.env']) {
    final values = {...readEnvFile(path), ...Platform.environment};

    String optional(String key, String fallback) {
      final value = values[key]?.trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    String required(String key) {
      final value = values[key]?.trim() ?? '';
      if (value.isEmpty) {
        throw ConfigException('$key is not set. Copy .env.example to .env in the server folder and fill it in.');
      }
      return value;
    }

    int port(String key, int fallback) {
      final raw = optional(key, '$fallback');
      final value = int.tryParse(raw);
      if (value == null || value < 1 || value > 65535) {
        throw ConfigException('$key must be a port number from 1 to 65535, but it is "$raw".');
      }
      return value;
    }

    final redis = _RedisSettings.from(
      url: optional('REDIS_URL', ''),
      host: optional('REDIS_HOST', 'localhost'),
      port: port('REDIS_PORT', 6379),
      username: optional('REDIS_USERNAME', ''),
      password: values['REDIS_PASSWORD'] ?? '',
      tls: optional('REDIS_TLS', 'false').toLowerCase() == 'true',
    );

    return AppConfig(
      dbHost: optional('DB_HOST', 'localhost'),
      dbPort: port('DB_PORT', 5432),
      dbName: required('DB_NAME'),
      dbUser: required('DB_USER'),
      // Not trimmed: a password may legitimately start or end with a space.
      dbPassword: values['DB_PASSWORD'] ?? '',
      dbSsl: optional('DB_SSL', 'false').toLowerCase() == 'true',
      redisHost: redis.host,
      redisPort: redis.port,
      redisUsername: redis.username,
      redisPassword: redis.password,
      redisTls: redis.tls,
      serverPort: port('SERVER_PORT', 8080),
      corsOrigin: optional('CORS_ORIGIN', '*'),
      timeZone: optional('TIME_ZONE', 'Asia/Karachi'),
    );
  }
}

/// Where Redis is. A `REDIS_URL` (what the Redis Cloud console's "Connect"
/// button gives you: `redis://default:PASSWORD@HOST:PORT`, or `rediss://`
/// for TLS) wins over the separate REDIS_HOST/PORT/USERNAME/PASSWORD/TLS
/// values, which suit a local Redis.
class _RedisSettings {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool tls;

  const _RedisSettings(this.host, this.port, this.username, this.password, this.tls);

  factory _RedisSettings.from({
    required String url,
    required String host,
    required int port,
    required String username,
    required String password,
    required bool tls,
  }) {
    if (url.isEmpty) return _RedisSettings(host, port, username, password, tls);
    // Redis Cloud's "Connect" panel also offers a redis-cli command
    // (`redis-cli -u redis://... [--tls]`), which is easy to copy instead of
    // the bare URL, so the URL is taken out of whatever was pasted.
    // The URL holds the password, so no message below ever repeats it.
    final pastedUrl = RegExp(r'rediss?://\S+').firstMatch(url)?.group(0) ?? url;
    final cliTls = RegExp(r'(^|\s)--tls(\s|$)').hasMatch(url);
    final uri = Uri.tryParse(pastedUrl);
    if (uri == null || (uri.scheme != 'redis' && uri.scheme != 'rediss') || uri.host.isEmpty) {
      throw const ConfigException(
        'REDIS_URL must look like redis://default:PASSWORD@HOST:PORT (rediss:// for TLS).',
      );
    }
    final userInfo = uri.userInfo;
    final colon = userInfo.indexOf(':');
    try {
      return _RedisSettings(
        uri.host,
        uri.hasPort ? uri.port : 6379,
        // "redis://PASSWORD@HOST" (no colon) means a password alone.
        Uri.decodeComponent(colon < 0 ? '' : userInfo.substring(0, colon)),
        Uri.decodeComponent(colon < 0 ? userInfo : userInfo.substring(colon + 1)),
        uri.scheme == 'rediss' || cliTls,
      );
    } on ArgumentError {
      throw const ConfigException('REDIS_URL has a badly escaped character in its username or password.');
    }
  }
}

class ConfigException implements Exception {
  final String message;
  const ConfigException(this.message);

  @override
  String toString() => message;
}

/// A minimal `KEY=VALUE` reader: blank lines and `#` comments are skipped
/// and one pair of surrounding quotes is removed. A missing file reads as
/// empty, so environment variables alone can configure the server. The
/// byte-order mark Windows Notepad can put at the start is ignored, so the
/// first key isn't silently misread.
Map<String, String> readEnvFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  final result = <String, String>{};
  for (var line in file.readAsLinesSync()) {
    line = line.replaceFirst('﻿', '').trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final equals = line.indexOf('=');
    if (equals <= 0) continue;
    final key = line.substring(0, equals).trim();
    var value = line.substring(equals + 1).trim();
    final quoted = value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'")));
    if (quoted) value = value.substring(1, value.length - 1);
    result[key] = value;
  }
  return result;
}
