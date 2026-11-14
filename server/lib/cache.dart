import 'package:redis/redis.dart';

import 'config.dart';

/// The server's Redis connection. Redis only holds fast, short-lived data:
/// login sessions, the failed-login counter, cached sales totals and live
/// nozzle readings. Losing it signs people out and empties caches but never
/// loses business data, which lives in PostgreSQL.
class Cache {
  Cache(this._config);

  final AppConfig _config;
  RedisConnection? _connection;
  Future<Command>? _command;

  /// Opens the connection once and shares it: concurrent requests are
  /// pipelined over it, and Redis answers them in order.
  Future<Command> _open() => _command ??= _connect();

  /// Connects (over TLS for a `rediss://` URL) and signs in. A hosted Redis
  /// such as Redis Cloud is reached over the internet, so the connection
  /// attempt gives up after [_connectTimeout] instead of hanging a request.
  Future<Command> _connect() async {
    final connection = RedisConnection();
    final command = await (_config.redisTls
            ? connection.connectSecure(_config.redisHost, _config.redisPort)
            : connection.connect(_config.redisHost, _config.redisPort))
        .timeout(_connectTimeout);
    if (_config.redisPassword.isNotEmpty) {
      // With a username this is Redis 6+ ACL sign-in (`AUTH user password`);
      // without one, the password alone signs in as the `default` user.
      final reply = await command.send_object([
        'AUTH',
        if (_config.redisUsername.isNotEmpty) _config.redisUsername,
        _config.redisPassword,
      ]).timeout(_connectTimeout);
      if (reply is RedisError) {
        await connection.close();
        throw const CacheException(
          'Redis rejected the username or password. Check REDIS_URL (or REDIS_USERNAME and REDIS_PASSWORD) in .env.',
        );
      }
    }
    _connection = connection;
    return command;
  }

  static const _connectTimeout = Duration(seconds: 10);

  /// How long one command may take before its connection counts as dead.
  /// A connection the far end dropped without saying so (Redis Cloud closes
  /// idle ones) would otherwise leave the request waiting forever.
  static const _commandTimeout = Duration(seconds: 10);

  /// Sends one command. If the connection fails (typically because Redis
  /// Cloud closed it while the server sat idle), it is replaced and the
  /// command sent once more, so the first request after a quiet spell
  /// doesn't fail. An error reply from Redis (e.g. a wrong-type key) means
  /// the connection is fine, so it is passed on without a retry.
  Future<Object?> send(List<String> args) async {
    try {
      return await _sendOnce(args);
    } on CacheException {
      rethrow;
    } catch (_) {
      return _sendOnce(args);
    }
  }

  Future<Object?> _sendOnce(List<String> args) async {
    final Object? result;
    try {
      result = await (await _open()).send_object(args).timeout(_commandTimeout);
    } catch (_) {
      _drop();
      rethrow;
    }
    if (result is RedisError) throw CacheException('Redis ${args.first} failed: $result');
    return result;
  }

  /// Forgets the current connection, so the next command opens a new one.
  void _drop() {
    final connection = _connection;
    _command = null;
    _connection = null;
    // Closing a socket that is already gone can fail too; nothing to do then.
    connection?.close().catchError((Object _) {});
  }

  Future<String> ping() async => '${await send(['PING'])}';

  /// The `redis_version` line of `INFO server`, or null if Redis doesn't say.
  Future<String?> serverVersion() async {
    final info = '${await send(['INFO', 'server'])}';
    for (final line in info.split('\n')) {
      if (line.startsWith('redis_version:')) return line.substring('redis_version:'.length).trim();
    }
    return null;
  }

  Future<String?> get(String key) async {
    final value = await send(['GET', key]);
    return value?.toString();
  }

  Future<void> setFor(String key, String value, Duration ttl) =>
      send(['SET', key, value, 'EX', '${ttl.inSeconds}']);

  Future<void> delete(String key) => send(['DEL', key]);

  /// Adds one to a counter and returns the new value. The expiry is set when
  /// the counter is created, so it resets [ttl] after the first increment
  /// rather than every time.
  Future<int> increment(String key, Duration ttl) async {
    final value = int.parse('${await send(['INCR', key])}');
    if (value == 1) await send(['EXPIRE', key, '${ttl.inSeconds}']);
    return value;
  }

  /// Replaces a hash's fields and (re)sets its expiry.
  Future<void> setHash(String key, Map<String, String> fields, Duration ttl) async {
    await send(['HSET', key, for (final entry in fields.entries) ...[entry.key, entry.value]]);
    await send(['EXPIRE', key, '${ttl.inSeconds}']);
  }

  /// A hash's fields, or an empty map when the key doesn't exist.
  Future<Map<String, String>> getHash(String key) async {
    final reply = await send(['HGETALL', key]);
    if (reply is! List) return const {};
    return {
      for (var i = 0; i + 1 < reply.length; i += 2) '${reply[i]}': '${reply[i + 1]}',
    };
  }

  Future<void> close() async {
    final connection = _connection;
    _connection = null;
    _command = null;
    await connection?.close();
  }
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);

  @override
  String toString() => message;
}
