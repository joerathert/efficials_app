import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'create_officials_from_csv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database factory for desktop/command line usage
  databaseFactory = databaseFactoryFfi;
  
  final creator = OfficialCreator();
  
  // Test with first 3 officials from your data
  final testCsv = '''Level of Certification,Years of Experience,Last Name,First Name,Address,City,ZIP,Cell Phone
Certified,8,Aldridge,Brandon,2627 Columbia Lakes Drive Unit 2D,Columbia,62236,618-719-4373
Registered,3,Angleton,Darrell,800 Alton St,Alton,62002,618-792-9995
Recognized,11,Baird,Robert,1217 W Woodfield Dr,Alton,62002,618-401-4016''';
  
  try {
    print('=== TESTING OFFICIALS CREATION ===');
    print('Testing with 3 sample officials...');
    
    final officialIds = await creator.createOfficialsFromCsv(testCsv);
    
    print('\n=== RESULTS ===');
    print('Created ${officialIds.length} officials successfully!');
    print('Official IDs: $officialIds');
    
    if (officialIds.length == 3) {
      print('\n✅ Test PASSED - All 3 officials created successfully');
      print('Expected emails generated:');
      print('- baldridge@test.com (Brandon Aldridge)');
      print('- dangleton@test.com (Darrell Angleton)');
      print('- rbaird@test.com (Robert Baird)');
      print('\nReady to process all 123 officials!');
    } else {
      print('\n❌ Test FAILED - Expected 3 officials, got ${officialIds.length}');
    }
    
  } catch (e, stackTrace) {
    print('\n❌ ERROR during testing: $e');
    print('Stack trace: $stackTrace');
  }
}