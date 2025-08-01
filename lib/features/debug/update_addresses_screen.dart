import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/database_helper.dart';
import 'dart:math';

class UpdateAddressesScreen extends StatefulWidget {
  const UpdateAddressesScreen({super.key});

  @override
  State<UpdateAddressesScreen> createState() => _UpdateAddressesScreenState();
}

class _UpdateAddressesScreenState extends State<UpdateAddressesScreen> {
  bool _isUpdating = false;
  bool _isComplete = false;
  String _statusMessage = '';
  List<String> _updateLog = [];

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
    
    // Additional approved locations
    '4747 Jefferson Ave, Effingham, IL 62401',
    '4848 Fayette Ave, Effingham, IL 62401',
    '4949 Henrietta St, Effingham, IL 62401',
    '5050 South Third St, Effingham, IL 62401',
    '5151 West Temple Ave, Effingham, IL 62401',
    '5252 Broadway Ave, Mattoon, IL 61938',
    '5353 Richmond Ave, Mattoon, IL 61938',
    '5454 Charleston Ave, Mattoon, IL 61938',
    '5555 DeWitt Ave, Mattoon, IL 61938',
    '5656 South 19th St, Mattoon, IL 61938',
    '5757 Lincoln Ave, Charleston, IL 61920',
    '5858 University Dr, Charleston, IL 61920',
    '5959 Fourth St, Charleston, IL 61920',
    '6060 Division St, Charleston, IL 61920',
    '6161 Monroe Ave, Charleston, IL 61920',
    '6262 Main St, Taylorville, IL 62568',
    '6363 Springfield Rd, Taylorville, IL 62568',
    '6464 Webster St, Taylorville, IL 62568',
    '6565 North Street, Taylorville, IL 62568',
    '6666 West Spresser St, Taylorville, IL 62568',
    '6767 Vandalia St, Hillsboro, IL 62049',
    '6868 South Main St, Hillsboro, IL 62049',
    '6969 East Tremont St, Hillsboro, IL 62049',
    '7070 North Main St, Hillsboro, IL 62049',
    '7171 School St, Hillsboro, IL 62049',
    '7272 North Side Square, Carlinville, IL 62626',
    '7373 East Main St, Carlinville, IL 62626',
    '7474 South West St, Carlinville, IL 62626',
    '7575 College Ave, Carlinville, IL 62626',
    '7676 Oak St, Carlinville, IL 62626',
    '7777 South Grand Ave, Springfield, IL 62703',
    '7878 West Jefferson St, Springfield, IL 62702',
    '7979 North MacArthur Blvd, Springfield, IL 62702',
    '8080 East Washington St, Springfield, IL 62701',
    '8181 South Sixth St, Springfield, IL 62703',
    '8282 South Main St, Red Bud, IL 62278',
    '8383 Market St, Red Bud, IL 62278',
    '8484 North Main St, Red Bud, IL 62278',
    '8585 Fourth St, Red Bud, IL 62278',
    '8686 Locust St, Red Bud, IL 62278',
    '8787 Main St, Waterloo, IL 62298',
    '8888 North Market St, Waterloo, IL 62298',
    '8989 Rogers St, Waterloo, IL 62298',
    '9090 Mill St, Waterloo, IL 62298',
    '9191 Fourth St, Waterloo, IL 62298',
    '9292 Main St, Columbia, IL 62236',
    '9393 Route 3, Columbia, IL 62236',
    '9494 Gum St, Columbia, IL 62236',
    '9595 Palmer Rd, Columbia, IL 62236',
    '9696 Baumgartner Rd, Columbia, IL 62236',
  ];

  Future<void> _updateAddresses() async {
    setState(() {
      _isUpdating = true;
      _isComplete = false;
      _statusMessage = 'Starting address update...';
      _updateLog.clear();
    });

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      
      // First, add address column if it doesn't exist
      try {
        await db.execute('ALTER TABLE officials ADD COLUMN address TEXT');
        _addLog('✅ Added address column to officials table');
      } catch (e) {
        _addLog('ℹ️ Address column already exists');
      }
      
      // Get all officials
      final officials = await db.query('officials');
      _addLog('📊 Found ${officials.length} officials to update');
      
      final random = Random();
      int updatedCount = 0;
      
      // Update each official with a random address from approved locations
      for (final official in officials) {
        final officialId = official['id'];
        final officialName = official['name'];
        
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
        _addLog('✅ Updated $officialName: $randomAddress');
        
        // Update UI periodically
        if (updatedCount % 10 == 0) {
          setState(() {
            _statusMessage = 'Updated $updatedCount officials...';
          });
        }
      }
      
      setState(() {
        _statusMessage = '🎉 Successfully added addresses to $updatedCount officials!';
        _isComplete = true;
      });
      _addLog('📍 All addresses are within 100 miles of Edwardsville, IL');
      _addLog('🏠 Addresses distributed across ${approvedAddresses.length} approved locations');
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Error adding addresses: $e';
      });
      _addLog('❌ Error: $e');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _updateLog.add(message);
    });
    print(message); // Also print to debug console
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Update Official Addresses',
          style: TextStyle(color: efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: efficialsBlack,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Address Update Tool',
                      style: TextStyle(
                        color: efficialsWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will add realistic addresses within 100 miles of Edwardsville, IL to all officials in the database.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _updateAddresses,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isComplete ? Colors.green : efficialsYellow,
                          foregroundColor: efficialsBlack,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isUpdating
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(efficialsBlack),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Updating Addresses...')
                                ],
                              )
                            : Text(_isComplete ? 'Update Complete!' : 'Start Address Update'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_statusMessage.isNotEmpty)
              Card(
                color: efficialsBlack,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isComplete ? Icons.check_circle : Icons.info,
                        color: _isComplete ? Colors.green : efficialsYellow,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _isComplete ? Colors.green : efficialsWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            if (_updateLog.isNotEmpty)
              Expanded(
                child: Card(
                  color: efficialsBlack,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Update Log',
                          style: TextStyle(
                            color: efficialsWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _updateLog.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                _updateLog[index],
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}