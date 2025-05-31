// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

// --- Order Models (conceptual, used as Maps for DB interaction) ---
// Order: orderId (TEXT PK), userId (INTEGER), orderDate (TEXT ISO8601),
//        totalAmount (REAL), shippingAddress (TEXT), status (TEXT)
// OrderItem: orderItemId (INTEGER PK AI), orderId (TEXT FK), plantId (INTEGER),
//            plantName (TEXT), quantity (INTEGER), priceAtPurchase (REAL)

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const _dbVersion = 6; // Already version 6 from previous update

  var uuid = const Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'flora_app.db');
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTablesV4(db);
    await _onUpgrade(db, 4, version);
  }

  Future<void> _createTablesV4(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        imageUrl TEXT 
        -- address column added in v6 via _onUpgrade
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion");
    if (oldVersion < 2) {
      try {
        var tableInfoUsers = await db.rawQuery('PRAGMA table_info(users)');
        bool fullNameColumnExists = tableInfoUsers.any(
          (column) => column['name'] == 'fullName',
        );
        if (!fullNameColumnExists) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN fullName TEXT NOT NULL DEFAULT ""',
          );
          print("Added fullName column to users (oldVersion < 2)");
        }
      } catch (e) {
        print("Error migrating fullName (oldVersion < 2): $e");
      }
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_plant_image_urls(
          plant_id INTEGER PRIMARY KEY, 
          image_url TEXT NOT NULL
        )
      ''');
      print("Created local_plant_image_urls table (oldVersion < 3)");
    }
    if (oldVersion < 4) {
      try {
        var tableInfoUsers = await db.rawQuery('PRAGMA table_info(users)');
        bool imageUrlColumnExists = tableInfoUsers.any(
          (column) => column['name'] == 'imageUrl',
        );
        if (!imageUrlColumnExists) {
          await db.execute('ALTER TABLE users ADD COLUMN imageUrl TEXT');
          print("Added imageUrl column to users (oldVersion < 4)");
        }
      } catch (e) {
        print("Error migrating imageUrl (oldVersion < 4): $e");
      }
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_orders (
          orderId TEXT PRIMARY KEY,
          userId INTEGER NOT NULL,
          orderDate TEXT NOT NULL,
          totalAmount REAL NOT NULL,
          shippingAddress TEXT, 
          status TEXT NOT NULL, 
          FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS order_items (
          orderItemId INTEGER PRIMARY KEY AUTOINCREMENT,
          orderId TEXT NOT NULL,
          plantId INTEGER, 
          plantName TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          priceAtPurchase REAL NOT NULL,
          FOREIGN KEY (orderId) REFERENCES user_orders(orderId) ON DELETE CASCADE
        )
      ''');
      print(
        "Database upgraded to version 5: user_orders and order_items tables created.",
      );
    }
    if (oldVersion < 6) {
      try {
        var tableInfoUsers = await db.rawQuery('PRAGMA table_info(users)');
        bool addressColumnExists = tableInfoUsers.any(
          (column) => column['name'] == 'address',
        );
        if (!addressColumnExists) {
          await db.execute('ALTER TABLE users ADD COLUMN address TEXT');
          print("Added address column to users table (oldVersion < 6)");
        }
      } catch (e) {
        print("Error adding address column (oldVersion < 6): $e");
      }
    }
  }

  // --- Metode User & Sesi ---
  Future<int> registerUser(User user) async {
    final db = await database;
    try {
      Map<String, dynamic> userMap = user.toMap();
      if (userMap['fullName'] == null || userMap['fullName'].isEmpty) {
        userMap['fullName'] = 'New User';
      }
      return await db.insert(
        'users',
        userMap,
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

  Future<User?> getUserById(int id) async {
    // Helper to get user by ID
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUserById(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
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

  Future<String> insertOrder({
    required int userId,
    required double totalAmount,
    String? shippingAddress, // This can be explicitly passed for overriding
    required String status,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;
    final String orderId = uuid.v4();
    final String orderDate = DateTime.now().toIso8601String();

    String finalShippingAddress = 'Alamat tidak diatur'; // Default fallback

    // If a specific shippingAddress is provided by the caller, use it.
    // Otherwise, fetch the user's primary address.
    if (shippingAddress != null &&
        shippingAddress != 'Alamat Pengiriman Default (Contoh)' &&
        shippingAddress !=
            'Alamat Pengiriman Default (Contoh dari Keranjang)') {
      finalShippingAddress = shippingAddress;
    } else {
      // Fetch user's primary address from users table
      final user = await getUserById(userId); // Using the new helper
      if (user != null && user.address != null && user.address!.isNotEmpty) {
        finalShippingAddress = user.address!;
      }
    }

    await db.transaction((txn) async {
      await txn.insert('user_orders', {
        'orderId': orderId,
        'userId': userId,
        'orderDate': orderDate,
        'totalAmount': totalAmount,
        'shippingAddress': finalShippingAddress, // Use determined address
        'status': status,
      });

      for (var item in items) {
        await txn.insert('order_items', {
          'orderId': orderId,
          'plantId': item['plantId'],
          'plantName': item['plantName'],
          'quantity': item['quantity'],
          'priceAtPurchase': item['priceAtPurchase'],
        });
      }
    });
    print(
      'Order $orderId inserted successfully for user $userId with address: $finalShippingAddress',
    );
    return orderId;
  }

  Future<List<Map<String, dynamic>>> getOrdersForUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'user_orders',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'orderDate DESC',
    );
    print('Fetched ${result.length} orders for user $userId.');
    return result;
  }

  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final db = await database;
    final result = await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );
    print('Fetched ${result.length} items for order $orderId.');
    return result;
  }
}
