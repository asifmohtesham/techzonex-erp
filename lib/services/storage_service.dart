import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  static StorageService get to => Get.find();

  Database? _sqliteDb;
  SharedPreferences? _webPrefs;

  final String _tableName = 'config';
  final String _keyServerUrl = 'server_url';

  Future<StorageService> init() async {
    if (kIsWeb) {
      _webPrefs = await SharedPreferences.getInstance();
    } else {
      await _initSqlite();
    }
    return this;
  }

  Future<void> _initSqlite() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'techzonex_erp.db');

    _sqliteDb = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE $_tableName(key TEXT PRIMARY KEY, value TEXT)',
        );
      },
    );
  }

  /// Saves the Server URL to the appropriate storage
  Future<void> saveServerUrl(String url) async {
    if (kIsWeb) {
      await _webPrefs?.setString(_keyServerUrl, url);
    } else {
      await _sqliteDb?.insert(
        _tableName,
        {'key': _keyServerUrl, 'value': url},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Retrieves the Server URL
  Future<String?> getServerUrl() async {
    if (kIsWeb) {
      return _webPrefs?.getString(_keyServerUrl);
    } else {
      final List<Map<String, dynamic>> maps = await _sqliteDb!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: [_keyServerUrl],
      );
      if (maps.isNotEmpty) {
        return maps.first['value'] as String;
      }
      return null;
    }
  }
}