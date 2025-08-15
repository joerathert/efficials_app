import 'package:flutter/material.dart';
// import '../../create_officials_from_csv.dart'; // File removed

class CreateOfficialsScreen extends StatefulWidget {
  const CreateOfficialsScreen({super.key});

  @override
  State<CreateOfficialsScreen> createState() => _CreateOfficialsScreenState();
}

class _CreateOfficialsScreenState extends State<CreateOfficialsScreen> {
  final TextEditingController _csvController = TextEditingController();
  // final OfficialCreator _creator = OfficialCreator(); // Class removed
  bool _isProcessing = false;
  String _result = '';
  
  // Sample data for quick testing
  final String _testData = '''Level of Certification,Years of Experience,Last Name,First Name,Address,City,ZIP,Cell Phone
Certified,8,Aldridge,Brandon,2627 Columbia Lakes Drive Unit 2D,Columbia,62236,618-719-4373
Registered,3,Angleton,Darrell,800 Alton St,Alton,62002,618-792-9995
Recognized,11,Baird,Robert,1217 W Woodfield Dr,Alton,62002,618-401-4016''';

  @override
  void initState() {
    super.initState();
    _csvController.text = _testData; // Pre-fill with test data
  }

  Future<void> _testWithSampleData() async {
    setState(() {
      _isProcessing = true;
      _result = 'Testing with 3 sample officials...';
    });

    try {
      // final ids = await _creator.createOfficialsFromCsv(_testData); // OfficialCreator class removed
      final ids = <int>[]; // Placeholder
      
      setState(() {
        _result = '''❌ Test functionality disabled!
OfficialCreator class was removed during cleanup.

Would have created test officials:
- baldridge@test.com (Brandon Aldridge)
- dangleton@test.com (Darrell Angleton) 
- rbaird@test.com (Robert Baird)

All officials are registered for Football sport.
Ready to process all officials!''';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processAllOfficials() async {
    if (_csvController.text.trim().isEmpty) {
      setState(() {
        _result = '❌ Please paste CSV data first';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _result = 'Processing all officials...';
    });

    try {
      // final ids = await _creator.createOfficialsFromCsv(_csvController.text); // OfficialCreator class removed
      final ids = <int>[]; // Placeholder
      
      setState(() {
        _result = '''❌ Functionality disabled!
OfficialCreator class was removed during cleanup.

To re-enable this feature, you would need to:
• Restore the create_officials_from_csv.dart file
• Implement the OfficialCreator class
• Have valid male names only

Official IDs: ${ids.take(10).join(', ')}${ids.length > 10 ? '...' : ''}''';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Football Officials from CSV'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 CSV Data Format Expected:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Level of Certification,Years of Experience,Last Name,First Name,Address,City,ZIP,Cell Phone',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '✅ Creates officials for Football sport only\n✅ Validates male names and Edwardsville IL area locations\n✅ Generates emails: firstletter+lastname@test.com',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _csvController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste your CSV data here...',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _testWithSampleData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test with 3 Officials'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processAllOfficials,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Process All Officials'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (_result.isNotEmpty)
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _result,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }
}