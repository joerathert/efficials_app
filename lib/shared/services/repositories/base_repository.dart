import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

abstract class BaseRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<Database> get database async => await _databaseHelper.database;

  // Transaction wrapper
  Future<void> withTransaction(Function(Transaction) callback) async {
    final db = await database;
    await db.transaction((txn) async {
      await callback(txn);
    });
  }

  // Batch operations
  Future<List<int>> batchInsert(String table, List<Map<String, dynamic>> data) async {
    final db = await database;
    final batch = db.batch();
    for (final row in data) {
      batch.insert(table, row);
    }
    final result = await batch.commit();
    return result.cast<int>();
  }

  Future<List<int>> batchUpdate(String table, List<Map<String, dynamic>> updates, String whereClause, List<List<dynamic>> whereArgsList) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < updates.length; i++) {
      batch.update(table, updates[i], where: whereClause, whereArgs: whereArgsList[i]);
    }
    final result = await batch.commit();
    return result.cast<int>();
  }

  // Common CRUD operations that can be overridden
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    final result = await db.insert(table, data);
    return result;
  }

  Future<int> update(String table, Map<String, dynamic> data, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    final result = await db.update(table, data, where: whereClause, whereArgs: whereArgs);
    return result;
  }

  Future<int> delete(String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    final result = await db.delete(table, where: whereClause, whereArgs: whereArgs);
    return result;
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final result = await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    final result = await db.rawQuery(sql, arguments);
    return result;
  }

  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    final result = await db.rawDelete(sql, arguments);
    return result;
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    final result = await db.rawInsert(sql, arguments);
    return result;
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    final result = await db.rawUpdate(sql, arguments);
    return result;
  }
}