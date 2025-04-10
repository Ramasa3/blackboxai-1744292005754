import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/content.dart';
import '../models/user.dart';
import '../models/subscription.dart';
import '../models/watch_party.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rstream.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        username TEXT NOT NULL,
        profile_image TEXT,
        role TEXT NOT NULL,
        subscription_plan TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Content table
    await db.execute('''
      CREATE TABLE content (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        thumbnail_url TEXT NOT NULL,
        stream_url TEXT NOT NULL,
        categories TEXT NOT NULL,
        rating REAL NOT NULL,
        duration INTEGER,
        release_year INTEGER,
        is_hd INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Watch history table
    await db.execute('''
      CREATE TABLE watch_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        content_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        completed INTEGER NOT NULL,
        watched_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (content_id) REFERENCES content (id) ON DELETE CASCADE
      )
    ''');

    // Watchlist table
    await db.execute('''
      CREATE TABLE watchlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        content_id TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (content_id) REFERENCES content (id) ON DELETE CASCADE
      )
    ''');

    // Downloads table
    await db.execute('''
      CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        quality TEXT NOT NULL,
        size INTEGER NOT NULL,
        status TEXT NOT NULL,
        progress REAL NOT NULL,
        downloaded_at INTEGER NOT NULL,
        FOREIGN KEY (content_id) REFERENCES content (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Watch parties table
    await db.execute('''
      CREATE TABLE watch_parties (
        id TEXT PRIMARY KEY,
        host_id TEXT NOT NULL,
        content_id TEXT NOT NULL,
        current_position INTEGER NOT NULL,
        is_playing INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (host_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (content_id) REFERENCES content (id) ON DELETE CASCADE
      )
    ''');

    // Watch party members table
    await db.execute('''
      CREATE TABLE watch_party_members (
        party_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        joined_at INTEGER NOT NULL,
        PRIMARY KEY (party_id, user_id),
        FOREIGN KEY (party_id) REFERENCES watch_parties (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Chat messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        party_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        sent_at INTEGER NOT NULL,
        FOREIGN KEY (party_id) REFERENCES watch_parties (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    // Content indexes
    await db.execute('CREATE INDEX idx_content_type ON content (type)');
    await db.execute('CREATE INDEX idx_content_categories ON content (categories)');
    await db.execute('CREATE INDEX idx_content_rating ON content (rating)');

    // Watch history indexes
    await db.execute('CREATE INDEX idx_watch_history_user ON watch_history (user_id)');
    await db.execute('CREATE INDEX idx_watch_history_content ON watch_history (content_id)');
    await db.execute('CREATE INDEX idx_watch_history_watched_at ON watch_history (watched_at)');

    // Watchlist indexes
    await db.execute('CREATE INDEX idx_watchlist_user ON watchlist (user_id)');
    await db.execute('CREATE INDEX idx_watchlist_content ON watchlist (content_id)');

    // Downloads indexes
    await db.execute('CREATE INDEX idx_downloads_user ON downloads (user_id)');
    await db.execute('CREATE INDEX idx_downloads_content ON downloads (content_id)');
    await db.execute('CREATE INDEX idx_downloads_status ON downloads (status)');

    // Watch party indexes
    await db.execute('CREATE INDEX idx_watch_parties_host ON watch_parties (host_id)');
    await db.execute('CREATE INDEX idx_watch_parties_content ON watch_parties (content_id)');
    await db.execute('CREATE INDEX idx_watch_party_members_party ON watch_party_members (party_id)');
    await db.execute('CREATE INDEX idx_watch_party_members_user ON watch_party_members (user_id)');
    await db.execute('CREATE INDEX idx_chat_messages_party ON chat_messages (party_id)');
    await db.execute('CREATE INDEX idx_chat_messages_user ON chat_messages (user_id)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  // User operations
  Future<void> saveUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // Content operations
  Future<void> saveContent(Content content) async {
    final db = await database;
    await db.insert(
      'content',
      content.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveContentBatch(List<Content> contents) async {
    final db = await database;
    final batch = db.batch();
    
    for (final content in contents) {
      batch.insert(
        'content',
        content.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<Content?> getContent(String contentId) async {
    final db = await database;
    final maps = await db.query(
      'content',
      where: 'id = ?',
      whereArgs: [contentId],
    );

    if (maps.isEmpty) return null;
    return Content.fromMap(maps.first);
  }

  Future<List<Content>> getContentByType(ContentType type) async {
    final db = await database;
    final maps = await db.query(
      'content',
      where: 'type = ?',
      whereArgs: [type.toString()],
    );

    return maps.map((map) => Content.fromMap(map)).toList();
  }

  // Watch history operations
  Future<void> saveWatchHistory(String userId, String contentId, Duration position) async {
    final db = await database;
    await db.insert(
      'watch_history',
      {
        'user_id': userId,
        'content_id': contentId,
        'position': position.inSeconds,
        'completed': 0,
        'watched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getWatchHistory(String userId) async {
    final db = await database;
    return db.query(
      'watch_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'watched_at DESC',
    );
  }

  // Watchlist operations
  Future<void> addToWatchlist(String userId, String contentId) async {
    final db = await database;
    await db.insert(
      'watchlist',
      {
        'user_id': userId,
        'content_id': contentId,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFromWatchlist(String userId, String contentId) async {
    final db = await database;
    await db.delete(
      'watchlist',
      where: 'user_id = ? AND content_id = ?',
      whereArgs: [userId, contentId],
    );
  }

  Future<List<Content>> getWatchlist(String userId) async {
    final db = await database;
    final watchlist = await db.rawQuery('''
      SELECT c.* FROM content c
      INNER JOIN watchlist w ON c.id = w.content_id
      WHERE w.user_id = ?
      ORDER BY w.added_at DESC
    ''', [userId]);

    return watchlist.map((map) => Content.fromMap(map)).toList();
  }

  // Watch party operations
  Future<void> saveWatchParty(WatchParty party) async {
    final db = await database;
    await db.insert(
      'watch_parties',
      party.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<WatchParty?> getWatchParty(String partyId) async {
    final db = await database;
    final maps = await db.query(
      'watch_parties',
      where: 'id = ?',
      whereArgs: [partyId],
    );

    if (maps.isEmpty) return null;
    return WatchParty.fromMap(maps.first);
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('users');
    await db.delete('content');
    await db.delete('watch_history');
    await db.delete('watchlist');
    await db.delete('downloads');
    await db.delete('watch_parties');
    await db.delete('watch_party_members');
    await db.delete('chat_messages');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
