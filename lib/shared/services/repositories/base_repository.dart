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
    debugPrint('Executing batchInsert on $table: ${data.length} rows');
    final db = await database;
    final batch = db.batch();
    for (final row in data) {
      batch.insert(table, row);
    }
    final result = await batch.commit();
    debugPrint('batchInsert completed on $table: ${result.length} rows inserted');
    return result.cast<int>();
  }

  Future<List<int>> batchUpdate(String table, List<Map<String, dynamic>> updates, String whereClause, List<List<dynamic>> whereArgsList) async {
    debugPrint('Executing batchUpdate on $table: ${updates.length} rows');
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < updates.length; i++) {
      batch.update(table, updates[i], where: whereClause, whereArgs: whereArgsList[i]);
    }
    final result = await batch.commit();
    debugPrint('batchUpdate completed on $table: ${result.length} rows updated');
    return result.cast<int>();
  }

  // Common CRUD operations that can be overridden
  Future<int> insert(String table, Map<String, dynamic> data) async {
    debugPrint('Executing insert on $table: $data');
    final db = await database;
    final result = await db.insert(table, data);
    debugPrint('Insert completed on $table: inserted ID $result');
    return result;
  }

  Future<int> update(String table, Map<String, dynamic> data, String whereClause, List<dynamic> whereArgs) async {
    debugPrint('Executing update on $table: $data where $whereClause with args $whereArgs');
    final db = await database;
    final result = await db.update(table, data, where: whereClause, whereArgs: whereArgs);
    debugPrint('Update completed on $table: $result rows affected');
    return result;
  }

  Future<int> delete(String table, String whereClause, List<dynamic> whereArgs) async {
    debugPrint('Executing delete on $table where $whereClause with args $whereArgs');
    final db = await database;
    final result = await db.delete(table, where: whereClause, whereArgs: whereArgs);
    debugPrint('Delete completed on $table: $result rows deleted');
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
    debugPrint('Executing query on $table where $where with args $whereArgs');
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
    debugPrint('Query completed on $table: ${result.length} rows returned');
    return result;
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    debugPrint('Executing rawQuery: $sql with args $arguments');
    final db = await database;
    final result = await db.rawQuery(sql, arguments);
    debugPrint('RawQuery completed: ${result.length} rows returned');
    return result;
  }

  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    debugPrint('Executing rawDelete: $sql with args $arguments');
    final db = await database;
    final result = await db.rawDelete(sql, arguments);
    debugPrint('RawDelete completed: $result rows deleted');
    return result;
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    debugPrint('Executing rawInsert: $sql with args $arguments');
    final db = await database;
    final result = await db.rawInsert(sql, arguments);
    debugPrint('RawInsert completed: inserted ID $result');
    return result;
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    debugPrint('Executing rawUpdate: $sql with args $arguments');
    final db = await database;
    final result = await db.rawUpdate(sql, arguments);
    debugPrint('RawUpdate completed: $result rows updated');
    return result;
  }
}