import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'handlers/todo_handler.dart';

Router createRouter(TodoHandler handler) {
  final router = Router();

  router.get('/api/todos', handler.getAll);
  router.get('/api/todos/<id>', handler.getById);
  router.post('/api/todos', handler.create);
  router.put('/api/todos/<id>', handler.update);
  router.delete('/api/todos/<id>', handler.delete);

  // Health check
  router.get('/api/health', (Request request) {
    return Response.ok('{"status":"ok"}',
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}
