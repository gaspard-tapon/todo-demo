import 'package:postgres/postgres.dart';

class Database {
  final String connectionString;
  late final Pool _pool;

  Database({required this.connectionString});

  Future<void> initialize() async {
    final endpoint = _parseConnectionString(connectionString);
    _pool = Pool.withEndpoints(
      [endpoint],
      settings: PoolSettings(
        maxConnectionCount: 5,
        sslMode: SslMode.disable,
      ),
    );

    await _pool.execute('''
      CREATE TABLE IF NOT EXISTS todos (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        title TEXT NOT NULL,
        description TEXT,
        is_completed BOOLEAN NOT NULL DEFAULT false,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    ''');
  }

  Future<Result> execute(String query, [Map<String, dynamic>? parameters]) {
    if (parameters != null) {
      return _pool.execute(Sql.named(query), parameters: parameters);
    }
    return _pool.execute(query);
  }

  Future<void> close() async {
    await _pool.close();
  }

  static Endpoint _parseConnectionString(String connStr) {
    // Format: postgres://user:password@host:port/database
    final uri = Uri.parse(connStr);
    return Endpoint(
      host: uri.host,
      port: uri.port != 0 ? uri.port : 5432,
      database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'todo',
      username: uri.userInfo.contains(':')
          ? uri.userInfo.split(':').first
          : uri.userInfo,
      password: uri.userInfo.contains(':')
          ? uri.userInfo.split(':').last
          : null,
    );
  }
}
