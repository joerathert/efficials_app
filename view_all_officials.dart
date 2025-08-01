import 'package:flutter/foundation.dart';
import 'lib/shared/services/database_helper.dart';

/// Utility script to view all officials in the database
/// Run this from your project root directory
class OfficialsViewer {
  
  /// Display all officials with their complete information
  Future<void> viewAllOfficials() async {
    try {
      final db = await DatabaseHelper().database;
      
      // Get all officials with comprehensive data
      final officials = await db.rawQuery('''
        SELECT 
          o.id,
          o.name,
          o.email,
          o.phone,
          o.city,
          o.state,
          o.availability_status,
          o.experience_years,
          o.official_user_id,
          o.user_id,
          o.is_user_account,
          o.created_at,
          ou.first_name as user_first_name,
          ou.last_name as user_last_name,
          ou.profile_verified,
          ou.email_verified,
          ou.phone_verified,
          ou.status as user_status
        FROM officials o
        LEFT JOIN official_users ou ON o.official_user_id = ou.id
        ORDER BY o.name ASC
      ''');

      print('=' * 80);
      print('OFFICIALS DATABASE - COMPLETE VIEW');
      print('Total Officials Found: ${officials.length}');
      print('=' * 80);
      
      if (officials.isEmpty) {
        print('❌ No officials found in the database!');
        print('💡 You may need to create test users first.');
        return;
      }

      for (int i = 0; i < officials.length; i++) {
        final official = officials[i];
        final num = (i + 1).toString().padLeft(3, ' ');
        
        print('\n$num. ${official['name']}');
        print('     ID: ${official['id']}');
        print('     Email: ${official['email'] ?? 'Not provided'}');
        print('     Phone: ${official['phone'] ?? 'Not provided'}');
        
        // Location info
        final city = official['city'];
        final state = official['state'];
        String location = 'Not provided';
        if (city != null && city.toString().isNotEmpty && city != 'null') {
          location = city.toString();
          if (state != null && state.toString().isNotEmpty && state != 'null') {
            location += ', $state';
          }
        }
        print('     Location: $location');
        
        print('     Availability: ${official['availability_status'] ?? 'Unknown'}');
        print('     Experience: ${official['experience_years'] ?? 'Not specified'} years');
        
        // User account info
        if (official['official_user_id'] != null) {
          print('     App Account: Yes (User ID: ${official['official_user_id']})');
          print('     Account Name: ${official['user_first_name']} ${official['user_last_name']}');
          print('     Profile Verified: ${official['profile_verified'] == 1 ? 'Yes' : 'No'}');
          print('     Email Verified: ${official['email_verified'] == 1 ? 'Yes' : 'No'}');
          print('     Phone Verified: ${official['phone_verified'] == 1 ? 'Yes' : 'No'}');
          print('     Status: ${official['user_status'] ?? 'Unknown'}');
        } else {
          print('     App Account: No (Database-only official)');
        }
        
        print('     Created: ${official['created_at'] ?? 'Unknown'}');
      }
      
      print('\n' + '=' * 80);
      await _showSportCertifications();
      await _showListMemberships();
      await _showSummaryStats();
      
    } catch (e) {
      print('❌ Error viewing officials: $e');
    }
  }

  /// Show sport certifications for all officials
  Future<void> _showSportCertifications() async {
    try {
      final db = await DatabaseHelper().database;
      
      final certifications = await db.rawQuery('''
        SELECT 
          o.name as official_name,
          s.name as sport_name,
          os.certification_level,
          os.years_experience,
          os.competition_levels,
          os.is_primary
        FROM official_sports os
        JOIN officials o ON os.official_id = o.id
        JOIN sports s ON os.sport_id = s.id
        ORDER BY o.name ASC, os.is_primary DESC, s.name ASC
      ''');

      print('\nSPORT CERTIFICATIONS');
      print('-' * 50);
      
      if (certifications.isEmpty) {
        print('❌ No sport certifications found!');
        return;
      }

      String currentOfficial = '';
      for (final cert in certifications) {
        if (cert['official_name'] != currentOfficial) {
          currentOfficial = cert['official_name'] as String;
          print('\n🏆 $currentOfficial:');
        }
        
        final isPrimary = cert['is_primary'] == 1 ? ' (PRIMARY)' : '';
        final sport = cert['sport_name'];
        final level = cert['certification_level'];
        final years = cert['years_experience'];
        final levels = cert['competition_levels'];
        
        print('   • $sport$isPrimary');
        print('     Level: $level | Experience: $years years');
        print('     Competition Levels: $levels');
      }
      
    } catch (e) {
      print('❌ Error viewing sport certifications: $e');
    }
  }

  /// Show official list memberships
  Future<void> _showListMemberships() async {
    try {
      final db = await DatabaseHelper().database;
      
      final memberships = await db.rawQuery('''
        SELECT 
          o.name as official_name,
          ol.name as list_name,
          s.name as sport_name
        FROM official_list_members olm
        JOIN officials o ON olm.official_id = o.id
        JOIN official_lists ol ON olm.list_id = ol.id
        LEFT JOIN sports s ON ol.sport_id = s.id
        ORDER BY o.name ASC, s.name ASC, ol.name ASC
      ''');

      print('\nOFFICIAL LIST MEMBERSHIPS');
      print('-' * 50);
      
      if (memberships.isEmpty) {
        print('❌ No list memberships found!');
        print('💡 Officials need to be added to lists to be assigned to Advanced Method games.');
        return;
      }

      String currentOfficial = '';
      for (final membership in memberships) {
        if (membership['official_name'] != currentOfficial) {
          currentOfficial = membership['official_name'] as String;
          print('\n📋 $currentOfficial:');
        }
        
        final listName = membership['list_name'];
        final sportName = membership['sport_name'] ?? 'No Sport';
        print('   • $listName ($sportName)');
      }
      
    } catch (e) {
      print('❌ Error viewing list memberships: $e');
    }
  }

  /// Show summary statistics
  Future<void> _showSummaryStats() async {
    try {
      final db = await DatabaseHelper().database;
      
      // Total counts
      final totalOfficials = (await db.rawQuery('SELECT COUNT(*) as count FROM officials')).first['count'] as int;
      final withAppAccounts = (await db.rawQuery('SELECT COUNT(*) as count FROM officials WHERE official_user_id IS NOT NULL')).first['count'] as int;
      final withoutAppAccounts = totalOfficials - withAppAccounts;
      
      // Sport participation
      final sportStats = await db.rawQuery('''
        SELECT s.name, COUNT(os.official_id) as official_count
        FROM sports s
        LEFT JOIN official_sports os ON s.id = os.sport_id
        GROUP BY s.id, s.name
        ORDER BY official_count DESC
      ''');

      // List participation
      final listStats = await db.rawQuery('''
        SELECT ol.name, COUNT(olm.official_id) as member_count
        FROM official_lists ol
        LEFT JOIN official_list_members olm ON ol.id = olm.list_id
        GROUP BY ol.id, ol.name
        ORDER BY member_count DESC
      ''');

      print('\nSUMMARY STATISTICS');
      print('-' * 50);
      print('📊 Total Officials: $totalOfficials');
      print('📱 With App Accounts: $withAppAccounts');
      print('📄 Database-Only: $withoutAppAccounts');
      
      print('\n🏆 Sport Participation:');
      for (final sport in sportStats) {
        print('   ${sport['name']}: ${sport['official_count']} officials');
      }
      
      print('\n📋 List Memberships:');
      if (listStats.isEmpty) {
        print('   No official lists found');
      } else {
        for (final list in listStats) {
          print('   ${list['name']}: ${list['member_count']} members');
        }
      }
      
    } catch (e) {
      print('❌ Error generating summary stats: $e');
    }
  }

  /// Search for specific officials by name or email
  Future<void> searchOfficials(String searchTerm) async {
    try {
      final db = await DatabaseHelper().database;
      
      final officials = await db.rawQuery('''
        SELECT 
          o.id,
          o.name,
          o.email,
          o.phone,
          o.city,
          o.state,
          o.availability_status
        FROM officials o
        WHERE 
          LOWER(o.name) LIKE LOWER(?) OR 
          LOWER(o.email) LIKE LOWER(?)
        ORDER BY o.name ASC
      ''', ['%$searchTerm%', '%$searchTerm%']);

      print('=' * 60);
      print('SEARCH RESULTS FOR: "$searchTerm"');
      print('Found ${officials.length} matching officials');
      print('=' * 60);
      
      for (final official in officials) {
        print('\n• ${official['name']}');
        print('  Email: ${official['email']}');
        print('  Phone: ${official['phone']}');
        print('  Location: ${official['city'] ?? 'N/A'}, ${official['state'] ?? 'N/A'}');
        print('  Status: ${official['availability_status']}');
      }
      
    } catch (e) {
      print('❌ Error searching officials: $e');
    }
  }
}

/// Usage examples:
/// 
/// To view all officials:
/// final viewer = OfficialsViewer();
/// await viewer.viewAllOfficials();
/// 
/// To search for specific officials:
/// await viewer.searchOfficials('Smith');
/// await viewer.searchOfficials('john@example.com');

void main() async {
  print('🔍 Officials Database Viewer');
  print('This tool will show you all officials in your database.');
  print('Make sure you have officials data in your database first.\n');
  
  final viewer = OfficialsViewer();
  await viewer.viewAllOfficials();
  
  print('\n✅ Done! You can also call:');
  print('   - viewer.searchOfficials("name or email") to search');
  print('   - Run this script anytime to view your officials data');
}