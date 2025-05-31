import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'flora_app.db');
    return await openDatabase(
      path,
      version: 3, // NAIKKAN VERSI DATABASE
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        var tableInfo = await db.rawQuery('PRAGMA table_info(users)');
        bool columnExists = tableInfo.any(
          (column) => column['name'] == 'fullName',
        );
        if (!columnExists) {
          await db.execute('ALTER TABLE users ADD COLUMN fullName TEXT');
        }
      } catch (e) {
        print("Error saat migrasi kolom fullName (mungkin sudah ada): $e");
      }
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_plant_image_urls(
          plant_id INTEGER PRIMARY KEY, 
          image_url TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_session(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_plant_image_urls(
        plant_id INTEGER PRIMARY KEY, 
        image_url TEXT NOT NULL
      )
    ''');
  }

  // --- Metode User & Sesi ---
  Future<int> registerUser(User user) async {
    final db = await database;
    try {
      return await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      print('Error registering user: $e');
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        print('Email already exists.');
      }
      return -1;
    }
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<void> setSessionValue(String key, String value) async {
    final db = await database;
    await db.insert('app_session', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSessionValue(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_session',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> deleteSessionValue(String key) async {
    final db = await database;
    await db.delete('app_session', where: 'key = ?', whereArgs: [key]);
  }
  // --- Akhir Metode User & Sesi ---

  // --- Metode untuk URL Gambar Lokal Tanaman ---
  Future<void> upsertLocalPlantImageUrl(int plantId, String imageUrl) async {
    final db = await database;
    await db.insert('local_plant_image_urls', {
      'plant_id': plantId,
      'image_url': imageUrl,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getLocalPlantImageUrl(int plantId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'local_plant_image_urls',
      columns: ['image_url'],
      where: 'plant_id = ?',
      whereArgs: [plantId],
    );

    if (maps.isNotEmpty) {
      return maps.first['image_url'] as String?;
    }
    return null;
  }

  Future<void> deleteLocalPlantImageUrl(int plantId) async {
    final db = await database;
    await db.delete(
      'local_plant_image_urls',
      where: 'plant_id = ?',
      whereArgs: [plantId],
    );
  }

  // --- Akhir Metode URL Gambar Lokal ---
}
