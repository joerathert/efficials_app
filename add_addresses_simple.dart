import 'dart:io';
import 'dart:math';

void main() async {
  print('🏠 Adding addresses to all officials...');
  
  // Since we can't run Flutter/SQLite directly, let's create SQL statements
  // that you can run in your app's debug console or database browser
  
  // Approved locations within 100 miles of Edwardsville, IL
  final approvedAddresses = [
    // Edwardsville area (0-15 miles)
    '123 Main St, Edwardsville, IL 62025',
    '456 University Dr, Edwardsville, IL 62026',
    '789 Center Grove Rd, Edwardsville, IL 62025',
    '321 Troy Dr, Edwardsville, IL 62025',
    '654 Governors Pkwy, Edwardsville, IL 62025',
    
    // Alton area (~15 miles)
    '111 Broadway St, Alton, IL 62002',
    '222 State St, Alton, IL 62002',
    '333 College Ave, Alton, IL 62002',
    '444 Washington Ave, Alton, IL 62002',
    '555 Ridge St, Alton, IL 62002',
    
    // Collinsville area (~20 miles)
    '777 Main St, Collinsville, IL 62234',
    '888 Center St, Collinsville, IL 62234',
    '999 Vandalia St, Collinsville, IL 62234',
    '1010 Morrison Ave, Collinsville, IL 62234',
    '1111 Clay St, Collinsville, IL 62234',
    
    // Belleville area (~25 miles)
    '1212 West Main St, Belleville, IL 62220',
    '1313 North Illinois St, Belleville, IL 62221',
    '1414 East Washington St, Belleville, IL 62220',
    '1515 South Belt West, Belleville, IL 62220',
    '1616 Carlyle Ave, Belleville, IL 62221',
    
    // Glen Carbon area (~8 miles)
    '1717 Main St, Glen Carbon, IL 62034',
    '1818 Old Troy Rd, Glen Carbon, IL 62034',
    '1919 Meridian St, Glen Carbon, IL 62034',
    '2020 Blue Ridge Dr, Glen Carbon, IL 62034',
    '2121 Forest Rd, Glen Carbon, IL 62034',
    
    // Highland area (~35 miles)
    '2222 Main St, Highland, IL 62249',
    '2323 Broadway St, Highland, IL 62249',
    '2424 Laurel St, Highland, IL 62249',
    '2525 Poplar St, Highland, IL 62249',
    '2626 Walnut St, Highland, IL 62249',
    
    // Greenville area (~45 miles)
    '2727 Main St, Greenville, IL 62246',
    '2828 College Ave, Greenville, IL 62246',
    '2929 Harris Ave, Greenville, IL 62246',
    '3030 Fourth St, Greenville, IL 62246',
    '3131 Prairie St, Greenville, IL 62246',
    
    // Litchfield area (~50 miles)
    '3232 State St, Litchfield, IL 62056',
    '3333 Union Ave, Litchfield, IL 62056',
    '3434 Route 16, Litchfield, IL 62056',
    '3535 Walnut St, Litchfield, IL 62056',
    '3636 Jefferson St, Litchfield, IL 62056',
    
    // Additional locations for variety
    '3737 Gallatin St, Vandalia, IL 62471',
    '3838 Kennedy Blvd, Vandalia, IL 62471',
    '3939 St Clair St, Vandalia, IL 62471',
    '4040 Johnson Ave, Vandalia, IL 62471',
    '4141 Fourth St, Vandalia, IL 62471',
    '4242 Broadway St, Centralia, IL 62801',
    '4343 Locust St, Centralia, IL 62801',
    '4444 South Elm St, Centralia, IL 62801',
    '4545 East McCord St, Centralia, IL 62801',
    '4646 North Poplar St, Centralia, IL 62801',
    '4747 Jefferson Ave, Effingham, IL 62401',
    '4848 Fayette Ave, Effingham, IL 62401',
    '4949 Henrietta St, Effingham, IL 62401',
    '5050 South Third St, Effingham, IL 62401',
    '5151 West Temple Ave, Effingham, IL 62401',
  ];
  
  final random = Random();
  final sqlStatements = StringBuffer();
  
  // Generate UPDATE statements for officials IDs 1-100
  sqlStatements.writeln('-- SQL statements to add addresses to officials');
  sqlStatements.writeln('-- Run these in your Flutter app or database browser');
  sqlStatements.writeln('');
  
  for (int i = 1; i <= 100; i++) {
    final randomAddress = approvedAddresses[random.nextInt(approvedAddresses.length)];
    sqlStatements.writeln("UPDATE officials SET address = '$randomAddress' WHERE id = $i;");
  }
  
  // Write SQL statements to file
  await File('/mnt/c/Users/Efficials/efficials_app/update_addresses.sql').writeAsString(sqlStatements.toString());
  
  print('✅ Generated SQL statements in update_addresses.sql');
  print('📄 You can run these statements to add addresses to all officials');
  print('📍 All addresses are within 100 miles of Edwardsville, IL');
  print('🏠 Generated ${approvedAddresses.length} different addresses');
  print('');
  print('💡 To apply these updates:');
  print('   1. Copy the SQL statements from update_addresses.sql');
  print('   2. Run them through your database interface or Flutter app');
}