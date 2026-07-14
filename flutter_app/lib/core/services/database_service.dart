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
      onUpgrade: _onUpgrade,
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加回收站支持（isDeleted 字段已存在，无需修改）
    }
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
    bool includeDeleted = false,
  }) async {
    final db = await database;

    String? where;
    List<Object>? whereArgs;

    if (includeDeleted) {
      // 包含已删除的文档
      if (favoriteOnly == true) {
        where = 'isFavorite = ?';
        whereArgs = [1];
      }
    } else {
      // 默认不包含已删除的文档
      if (favoriteOnly == true) {
        where = 'isDeleted = ? AND isFavorite = ?';
        whereArgs = [0, 1];
      } else {
        where = 'isDeleted = ?';
        whereArgs = [0];
      }
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
      {'isDeleted': 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreDocument(String id) async {
    final db = await database;
    return await db.update(
      _tableName,
      {'isDeleted': 0, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> permanentDeleteDocument(String id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> emptyRecycleBin() async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'isDeleted = ?',
      whereArgs: [1],
    );
  }

  Future<List<Document>> getRecycleBinDocuments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isDeleted = ?',
      whereArgs: [1],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Document.fromMap(map)).toList();
  }

  Future<int> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      _tableName,
      {
        'isFavorite': isFavorite ? 1 : 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
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

  Future<int> getDocumentCount({bool includeDeleted = false}) async {
    final db = await database;
    final where = includeDeleted ? null : 'isDeleted = 0';
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName${where != null ? " WHERE $where" : ""}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<String>> getAllTags() async {
    final documents = await getAllDocuments();
    final tags = <String>{};
    for (final doc in documents) {
      tags.addAll(doc.tags);
    }
    return tags.toList()..sort();
  }
}
