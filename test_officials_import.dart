// Simple test to verify our officials data works correctly
import 'lib/utils/officials_data.dart';

void main() {
  print('Testing OfficialsDataProvider...');
  
  final officials = OfficialsDataProvider.getAllOfficials();
  
  print('Total officials loaded: ${officials.length}');
  
  if (officials.isNotEmpty) {
    print('First few officials:');
    for (int i = 0; i < 5 && i < officials.length; i++) {
      final official = officials[i];
      print('  ${i + 1}. ${official.displayName} -> ${official.email}');
    }
    
    print('\nLast few officials:');
    final start = officials.length - 3;
    for (int i = start; i < officials.length; i++) {
      final official = officials[i];
      print('  ${i + 1}. ${official.displayName} -> ${official.email}');
    }
    
    print('\n✅ Officials data provider working correctly!');
  } else {
    print('❌ No officials loaded');
  }
}