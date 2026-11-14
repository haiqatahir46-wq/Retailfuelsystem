import 'dart:async';
import 'dart:io';

import 'package:rfms_server/api.dart';
import 'package:rfms_server/cache.dart';
import 'package:rfms_server/config.dart';
import 'package:rfms_server/database.dart';
import 'package:rfms_server/http_utils.dart';
import 'package:rfms_server/store.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Starts the API: `dart run bin/server.dart` from the server folder.
Future<void> main() async {
  final AppConfig config;
  try {
    config = AppConfig.load();
  } on ConfigException catch (error) {
    stderr.writeln(error);
    exitCode = 64;
    return;
  }

  final db = openPool(config);
  final cache = Cache(config);
  final handler = const Pipeline()
      .addMiddleware(cors(config.corsOrigin))
      .addMiddleware(logRequests())
      .addMiddleware(handleErrors())
      .addHandler(Api(Store(db), cache).handler);

  final HttpServer server;
  try {
    server = await shelf_io.serve(handler, InternetAddress.anyIPv4, config.serverPort);
  } on SocketException {
    // Almost always another copy of this server, still running from an
    // earlier terminal: say so, instead of a stack trace.
    stderr.writeln('Port ${config.serverPort} is already in use, so the server could not start.');
    stderr.writeln('Most likely the server is ALREADY RUNNING (from another terminal or an earlier start).');
    stderr.writeln('  Check: open http://localhost:${config.serverPort}/health - if it shows {"postgres":"ok","redis":"ok"}, it is running and you can use it.');
    stderr.writeln('  To restart it: stop the other one first (Ctrl+C in its terminal), then run this again.');
    stderr.writeln('  Or use another port: set SERVER_PORT=8081 in .env (and use http://localhost:8081).');
    await db.close();
    exitCode = 1;
    return;
  }
  stdout.writeln('PARCO Fuel System API on http://localhost:${server.port}  (GET /health checks PostgreSQL and Redis)');

  // Ctrl+C closes the database pool and Redis connection cleanly.
  late final StreamSubscription<ProcessSignal> stop;
  stop = ProcessSignal.sigint.watch().listen((_) async {
    await stop.cancel();
    await server.close();
    await db.close();
    await cache.close();
    exit(0);
  });
}
