import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:todo_server/database.dart';
import 'package:todo_server/repository/todo_repository.dart';
import 'package:todo_server/handlers/todo_handler.dart';
import 'package:todo_server/router.dart';

Future<void> main() async {
  final databaseUrl = Platform.environment['DATABASE_URL'] ??
      'postgres://todo:todo@localhost:5432/todo_dev';
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // Initialize database
  final db = Database(connectionString: databaseUrl);
  await db.initialize();
  print('Database connected and initialized.');

  // Create repository and handler
  final repository = ServerTodoRepository(db);
  final handler = TodoHandler(repository);

  // Build router
  final apiRouter = createRouter(handler);

  // Serve static Flutter web build if available
  Handler staticHandler;
  final publicDir = Directory('public');
  if (publicDir.existsSync()) {
    staticHandler = createStaticHandler('public', defaultDocument: 'index.html');
  } else {
    staticHandler = (Request req) => Response.notFound('Not found');
  }

  // CORS middleware
  Middleware cors() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  // Combine: API routes take priority, then static files
  final cascade = Cascade().add(apiRouter.call).add(staticHandler);

  final pipeline = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(cors())
      .addHandler(cascade.handler);

  final server = await io.serve(pipeline, InternetAddress.anyIPv4, port);
  print('Server running on http://${server.address.host}:${server.port}');

  // Graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down...');
    await db.close();
    await server.close();
    exit(0);
  });
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};
