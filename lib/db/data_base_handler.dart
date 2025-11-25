import 'package:laravelide/models/project_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DataBaseHandler {
  static final DataBaseHandler instance = DataBaseHandler._instance();
  static Database? _database;

  DataBaseHandler._instance();

  Future<Database> get db async {
    _database ??= await initDb();
    return _database!;
  }

  Future<Database> initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'laravelide.db');
    // print(path);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE projectpath (
      id INTEGER PRIMARY KEY,
      name TEXT,
      path TEXT,
      isCreated TEXT,
      platform TEXT,
      projectType TEXT
    )
  ''');
  }

  // Future<int> insertUser(ProjectModel user) async {
  //   Database db = await instance.db;
  //   return await db.insert('projectpath', user.toJson());
  // }

  Future<int> insertUser(ProjectModel user) async {
    final db = await instance.db;

    final existing = await db.query(
      'projectpath',
      where: 'path = ?',
      whereArgs: [user.path],
    );

    if (existing.isNotEmpty) {
      return -100;
    }
    return await db.insert('projectpath', user.toMap());
  }

  Future<List<ProjectModel>> queryAllUsers() async {
    final db = await instance.db;

    final result = await db.query('projectpath');
    return result.map((map) => ProjectModel.fromMap(map)).toList();
  }

  // Future<int> updateUser(User user) async {
  //   Database db = await instance.db;
  //   return await db.update(
  //     'gfg_users',
  //     user.toMap(),
  //     where: 'id = ?',
  //     whereArgs: [user.id],
  //   );
  // }

  Future<int> deleteUser(int id) async {
    Database db = await instance.db;
    return await db.delete('gfg_users', where: 'id = ?', whereArgs: [id]);
  }

  // Future<void> initializeUsers() async {
  //   List<User> usersToAdd = [
  //     User(username: 'John', email: 'john@example.com'),
  //     User(username: 'Jane', email: 'jane@example.com'),
  //     User(username: 'Alice', email: 'alice@example.com'),
  //     User(username: 'Bob', email: 'bob@example.com'),
  //   ];

  //   for (User user in usersToAdd) {
  //     await insertUser(user);
  //   }
  // }
}
