import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Initialize FFI for desktop platforms
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('=== DEBUG USER DATA ===');
  
  try {
    // Open the database
    final dbPath = 'efficials.db';
    final db = await openDatabase(dbPath);
    
    print('Database opened successfully');
    
    // Check if the users table exists
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='users';");
    print('Users table exists: ${tables.isNotEmpty}');
    
    if (tables.isNotEmpty) {
      // Get all users
      final users = await db.query('users');
      print('Found ${users.length} users in database:');
      
      for (var user in users) {
        print('');
        print('User ID: ${user['id']}');
        print('Scheduler Type: ${user['scheduler_type']}');
        print('School Name: "${user['school_name']}"');
        print('Mascot: "${user['mascot']}"');
        print('First Name: "${user['first_name']}"');
        print('Last Name: "${user['last_name']}"');
        print('Email: "${user['email']}"');
        print('Setup Completed: ${user['setup_completed']}');
        print('---');
      }
      
      // Check user_sessions table
      final sessions = await db.query('user_sessions');
      print('');
      print('Found ${sessions.length} active sessions:');
      for (var session in sessions) {
        print('Session - User ID: ${session['user_id']}, Type: ${session['user_type']}, Email: ${session['email']}');
      }
    } else {
      print('Users table does not exist!');
    }
    
    await db.close();
    print('Database closed');
    
  } catch (e) {
    print('Error: $e');
  }
}