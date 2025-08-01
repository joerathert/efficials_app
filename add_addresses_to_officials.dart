import 'package:flutter/foundation.dart';
import 'lib/shared/services/database_helper.dart';
import 'dart:math';

void main() async {
  print('🏠 Adding addresses to all officials...');
  
  try {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    
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
      
      // Vandalia area (~60 miles)
      '3737 Gallatin St, Vandalia, IL 62471',
      '3838 Kennedy Blvd, Vandalia, IL 62471',
      '3939 St Clair St, Vandalia, IL 62471',
      '4040 Johnson Ave, Vandalia, IL 62471',
      '4141 Fourth St, Vandalia, IL 62471',
      
      // Centralia area (~75 miles)
      '4242 Broadway St, Centralia, IL 62801',
      '4343 Locust St, Centralia, IL 62801',
      '4444 South Elm St, Centralia, IL 62801',
      '4545 East McCord St, Centralia, IL 62801',
      '4646 North Poplar St, Centralia, IL 62801',
      
      // Effingham area (~85 miles)
      '4747 Jefferson Ave, Effingham, IL 62401',
      '4848 Fayette Ave, Effingham, IL 62401',
      '4949 Henrietta St, Effingham, IL 62401',
      '5050 South Third St, Effingham, IL 62401',
      '5151 West Temple Ave, Effingham, IL 62401',
      
      // Mattoon area (~95 miles)
      '5252 Broadway Ave, Mattoon, IL 61938',
      '5353 Richmond Ave, Mattoon, IL 61938',  
      '5454 Charleston Ave, Mattoon, IL 61938',
      '5555 DeWitt Ave, Mattoon, IL 61938',
      '5656 South 19th St, Mattoon, IL 61938',
      
      // Charleston area (~90 miles)
      '5757 Lincoln Ave, Charleston, IL 61920',
      '5858 University Dr, Charleston, IL 61920',
      '5959 Fourth St, Charleston, IL 61920',
      '6060 Division St, Charleston, IL 61920',
      '6161 Monroe Ave, Charleston, IL 61920',
      
      // Taylorville area (~80 miles)
      '6262 Main St, Taylorville, IL 62568',
      '6363 Springfield Rd, Taylorville, IL 62568',
      '6464 Webster St, Taylorville, IL 62568',
      '6565 North Street, Taylorville, IL 62568',
      '6666 West Spresser St, Taylorville, IL 62568',
      
      // Hillsboro area (~65 miles)
      '6767 Vandalia St, Hillsboro, IL 62049',
      '6868 South Main St, Hillsboro, IL 62049',
      '6969 East Tremont St, Hillsboro, IL 62049',
      '7070 North Main St, Hillsboro, IL 62049',
      '7171 School St, Hillsboro, IL 62049',
      
      // Carlinville area (~40 miles)
      '7272 North Side Square, Carlinville, IL 62626',
      '7373 East Main St, Carlinville, IL 62626',
      '7474 South West St, Carlinville, IL 62626',
      '7575 College Ave, Carlinville, IL 62626',
      '7676 Oak St, Carlinville, IL 62626',
      
      // Springfield area (~95 miles)
      '7777 South Grand Ave, Springfield, IL 62703',
      '7878 West Jefferson St, Springfield, IL 62702',
      '7979 North MacArthur Blvd, Springfield, IL 62702',
      '8080 East Washington St, Springfield, IL 62701',
      '8181 South Sixth St, Springfield, IL 62703',
      
      // Red Bud area (~45 miles)
      '8282 South Main St, Red Bud, IL 62278',
      '8383 Market St, Red Bud, IL 62278',
      '8484 North Main St, Red Bud, IL 62278',
      '8585 Fourth St, Red Bud, IL 62278',
      '8686 Locust St, Red Bud, IL 62278',
      
      // Waterloo area (~40 miles)
      '8787 Main St, Waterloo, IL 62298',
      '8888 North Market St, Waterloo, IL 62298',
      '8989 Rogers St, Waterloo, IL 62298',
      '9090 Mill St, Waterloo, IL 62298',
      '9191 Fourth St, Waterloo, IL 62298',
      
      // Columbia area (~35 miles)
      '9292 Main St, Columbia, IL 62236',
      '9393 Route 3, Columbia, IL 62236',
      '9494 Gum St, Columbia, IL 62236',
      '9595 Palmer Rd, Columbia, IL 62236',
      '9696 Baumgartner Rd, Columbia, IL 62236',
    ];
    
    // Get all officials
    final officials = await db.query('officials');
    print('📊 Found ${officials.length} officials to update');
    
    final random = Random();
    int updatedCount = 0;
    
    // Update each official with a random address from approved locations
    for (final official in officials) {
      final officialId = official['id'];
      final officialName = official['name'];
      
      // Skip if official already has an address
      final existingAddress = await db.query(
        'officials',
        columns: ['address'],
        where: 'id = ? AND address IS NOT NULL AND address != ""',
        whereArgs: [officialId],
      );
      
      if (existingAddress.isNotEmpty) {
        print('⏭️ Skipping ${officialName} - already has address');
        continue;
      }
      
      // Assign a random address from our approved list
      final randomAddress = approvedAddresses[random.nextInt(approvedAddresses.length)];
      
      // Update the official's address
      await db.update(
        'officials',
        {'address': randomAddress},
        where: 'id = ?',
        whereArgs: [officialId],
      );
      
      updatedCount++;
      print('✅ Updated ${officialName}: $randomAddress');
    }
    
    print('🎉 Successfully added addresses to $updatedCount officials!');
    print('📍 All addresses are within 100 miles of Edwardsville, IL');
    print('🏠 Addresses distributed across ${approvedAddresses.length} approved locations');
  
  } catch (e) {
    print('❌ Error adding addresses: $e');
  }
}