// Quick validation script to test our officials creation logic
// This tests the parsing and validation logic without requiring the full Flutter app

import 'lib/create_officials_from_csv.dart';

void main() {
  final creator = OfficialCreator();
  
  // Test sample data from your CSV
  final testData = '''Level of Certification,Years of Experience,Last Name,First Name,Address,City,ZIP,Cell Phone
Certified,8,Aldridge,Brandon,2627 Columbia Lakes Drive Unit 2D,Columbia,62236,618-719-4373
Registered,3,Angleton,Darrell,800 Alton St,Alton,62002,618-792-9995
Recognized,11,Baird,Robert,1217 W Woodfield Dr,Alton,62002,618-401-4016''';

  print('=== TESTING CSV PARSING ===');
  
  // Test CSV parsing
  final lines = testData.trim().split('\n');
  final dataLines = lines.where((line) => 
    !line.toLowerCase().contains('certification') && 
    !line.toLowerCase().contains('experience') &&
    line.trim().isNotEmpty
  ).toList();
  
  print('Found ${dataLines.length} data lines (excluding header)');
  
  for (int i = 0; i < dataLines.length; i++) {
    final line = dataLines[i];
    final validation = creator.validateOfficialData(line);
    
    print('\nLine ${i + 1}: $line');
    print('Validation result:');
    print('  Name: ${validation['firstName']} ${validation['lastName']}');
    print('  Certification: ${validation['certification']}');
    print('  Experience: ${validation['experience']} years');
    print('  City: ${validation['city']}');
    print('  Phone: ${validation['phone']}');
    print('  Valid male name: ${validation['validName']}');
    print('  Valid location: ${validation['validLocation']}');
    print('  Generated email: ${validation['email']}');
    
    if (validation['valid']) {
      print('  ✅ VALID - Would be created');
    } else {
      print('  ❌ INVALID - Would be skipped');
      if (validation['reason'] != null) {
        print('    Reason: ${validation['reason']}');
      }
    }
  }
  
  print('\n=== VALIDATION COMPLETE ===');
  print('Ready to test in the Flutter app!');
}