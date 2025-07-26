import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/database_models.dart';
import 'base_repository.dart';

class TemplateRepository extends BaseRepository {
  static const String _tableName = 'user_settings';
  static const String _templateAssociationPrefix = 'schedule_template_';

  // Get template association for a schedule
  Future<String?> getByScheduleName(int userId, String scheduleName) async {
    try {
      final db = await database;
      final key = '${_templateAssociationPrefix}${scheduleName.toLowerCase()}';
      
      final result = await db.query(
        _tableName,
        where: 'user_id = ? AND key = ?',
        whereArgs: [userId, key],
      );

      if (result.isNotEmpty) {
        final templateData = jsonDecode(result.first['value'] as String);
        return templateData['name'] as String?;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting template association for schedule "$scheduleName": $e');
      return null;
    }
  }

  // Set template association for a schedule
  Future<bool> setAssociation(int userId, String scheduleName, String templateName, Map<String, dynamic> templateData) async {
    try {
      final db = await database;
      final key = '${_templateAssociationPrefix}${scheduleName.toLowerCase()}';
      final value = jsonEncode({
        'name': templateName,
        'data': templateData,
      });

      // Check if association already exists
      final existing = await db.query(
        _tableName,
        where: 'user_id = ? AND key = ?',
        whereArgs: [userId, key],
      );

      if (existing.isNotEmpty) {
        // Update existing association
        await db.update(
          _tableName,
          {'value': value},
          where: 'user_id = ? AND key = ?',
          whereArgs: [userId, key],
        );
      } else {
        // Create new association
        await db.insert(_tableName, {
          'user_id': userId,
          'key': key,
          'value': value,
        });
      }

      debugPrint('Set template association: "$scheduleName" -> "$templateName"');
      return true;
    } catch (e) {
      debugPrint('Error setting template association for schedule "$scheduleName": $e');
      return false;
    }
  }

  // Remove template association for a schedule
  Future<bool> removeAssociation(int userId, String scheduleName) async {
    try {
      final db = await database;
      final key = '${_templateAssociationPrefix}${scheduleName.toLowerCase()}';
      
      final result = await db.delete(
        _tableName,
        where: 'user_id = ? AND key = ?',
        whereArgs: [userId, key],
      );

      debugPrint('Removed template association for schedule "$scheduleName"');
      return result > 0;
    } catch (e) {
      debugPrint('Error removing template association for schedule "$scheduleName": $e');
      return false;
    }
  }

  // Get all template associations for a user
  Future<Map<String, String>> getAllAssociations(int userId) async {
    try {
      final db = await database;
      
      final result = await db.query(
        _tableName,
        where: 'user_id = ? AND key LIKE ?',
        whereArgs: [userId, '${_templateAssociationPrefix}%'],
      );

      final associations = <String, String>{};
      
      for (final row in result) {
        final key = row['key'] as String;
        final scheduleName = key.substring(_templateAssociationPrefix.length);
        
        try {
          final templateData = jsonDecode(row['value'] as String);
          final templateName = templateData['name'] as String?;
          
          if (templateName != null) {
            associations[scheduleName] = templateName;
          }
        } catch (e) {
          debugPrint('Error parsing template data for key "$key": $e');
        }
      }

      return associations;
    } catch (e) {
      debugPrint('Error getting all template associations: $e');
      return {};
    }
  }

  // Update template association when schedule name changes
  Future<bool> updateScheduleName(int userId, String oldScheduleName, String newScheduleName) async {
    try {
      final db = await database;
      final oldKey = '${_templateAssociationPrefix}${oldScheduleName.toLowerCase()}';
      final newKey = '${_templateAssociationPrefix}${newScheduleName.toLowerCase()}';
      
      // Get the existing association
      final result = await db.query(
        _tableName,
        where: 'user_id = ? AND key = ?',
        whereArgs: [userId, oldKey],
      );

      if (result.isNotEmpty) {
        final value = result.first['value'] as String;
        
        await withTransaction((txn) async {
          // Insert with new key
          await txn.insert(_tableName, {
            'user_id': userId,
            'key': newKey,
            'value': value,
          });
          
          // Delete old key
          await txn.delete(
            _tableName,
            where: 'user_id = ? AND key = ?',
            whereArgs: [userId, oldKey],
          );
        });

        debugPrint('Updated template association key: "$oldScheduleName" -> "$newScheduleName"');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error updating schedule name in template associations: $e');
      return false;
    }
  }

  // Get template data for a schedule (full data, not just name)
  Future<Map<String, dynamic>?> getTemplateData(int userId, String scheduleName) async {
    try {
      final db = await database;
      final key = '${_templateAssociationPrefix}${scheduleName.toLowerCase()}';
      
      final result = await db.query(
        _tableName,
        where: 'user_id = ? AND key = ?',
        whereArgs: [userId, key],
      );

      if (result.isNotEmpty) {
        final templateData = jsonDecode(result.first['value'] as String);
        return templateData['data'] as Map<String, dynamic>?;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting template data for schedule "$scheduleName": $e');
      return null;
    }
  }

  // Remove all template associations for a user (for cleanup)
  Future<bool> removeAllAssociations(int userId) async {
    try {
      final db = await database;
      
      final result = await db.delete(
        _tableName,
        where: 'user_id = ? AND key LIKE ?',
        whereArgs: [userId, '${_templateAssociationPrefix}%'],
      );

      debugPrint('Removed all template associations for user $userId: $result associations');
      return true;
    } catch (e) {
      debugPrint('Error removing all template associations: $e');
      return false;
    }
  }
}