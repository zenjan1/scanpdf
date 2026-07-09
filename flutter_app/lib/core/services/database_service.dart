import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:scanpdf/core/constants/app_constants.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'documents';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        pageCount INTEGER NOT NULL,
        tags TEXT,
        filePath TEXT NOT NULL,
        thumbnailPath TEXT,
        isFavorite INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0,
        cloudId TEXT,
        syncStatus TEXT DEFAULT 'local'
      )
    ''');
  }

  // Document Operations
  Future<int> insertDocument(Document document) async {
    final db = await database;
    return await db.insert(
      _tableName,
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Document>> getAllDocuments({
    bool? favoriteOnly,
    String? sortBy,
    bool ascending = false,
  }) async {
    final db = await database;

    String? where;
    List<Object>? whereArgs;

    if (favoriteOnly == true) {
      where = 'isDeleted = ? AND isFavorite = ?';
      whereArgs = [0, 1];
    } else {
      where = 'isDeleted = ?';
      whereArgs = [0];
    }

    final orderField = sortBy ?? 'updatedAt';
    final orderDirection = ascending ? 'ASC' : 'DESC';
    final orderBy = '$orderField $orderDirection';

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
    return maps.map((map) => Document.fromMap(map)).toList();
  }

  Future<int> updateDocument(Document document) async {
    final db = await database;
    return await db.update(
      _tableName,
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<int> deleteDocument(String id) async {
    final db = await database;
    return await db.update(
      _tableName,
      {'isDeleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      _tableName,
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Document>> searchDocuments(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'title LIKE ? AND isDeleted = 0',
      whereArgs: ['%$query%'],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Document.fromMap(map)).toList();
  }
}
