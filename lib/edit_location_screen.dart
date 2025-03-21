import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'theme.dart';

// List of 50 US states (abbreviations)
const List<String> usStates = [
  'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
  'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
  'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
  'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
  'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
];

class EditLocationScreen extends StatefulWidget {
  const EditLocationScreen({super.key});

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  int? locationId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      locationId = args['locationId'] as int?;
      _loadLocationData();
    }
  }

  Future<void> _loadLocationData() async {
    if (locationId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String? locationsJson = prefs.getString('saved_locations');
    if (locationsJson != null) {
      final List<Map<String, dynamic>> locations = List<Map<String, dynamic>>.from(jsonDecode(locationsJson));
      final location = locations.firstWhere((loc) => loc['id'] == locationId, orElse: () => {});
      if (location.isNotEmpty) {
        setState(() {
          _nameController.text = location['name'] as String? ?? '';
          _addressController.text = location['address'] as String? ?? '';
          _cityController.text = location['city'] as String? ?? '';
          _stateController.text = location['state'] as String? ?? '';
          _zipCodeController.text = location['zip'] as String? ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  bool _isValidState(String state) {
    return usStates.contains(state.toUpperCase());
  }

  void _handleContinue() {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim().toUpperCase();
    final zip = _zipCodeController.text.trim();

    if (name.isEmpty || address.isEmpty || city.isEmpty || state.isEmpty || zip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (state.length != 2 || !_isValidState(state)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 2-letter state code')),
      );
      return;
    }
    if (zip.length != 5 || !RegExp(r'^\d{5}$').hasMatch(zip)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 5-digit zip code')),
      );
      return;
    }

    final updatedLocation = {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
    };
    print('EditLocationScreen - Returning: $updatedLocation');
    Navigator.of(context).pop(updatedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Location',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: textFieldDecoration('Location Name'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _addressController,
                    decoration: textFieldDecoration('Address'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _cityController,
                    decoration: textFieldDecoration('City'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _stateController,
                          decoration: textFieldDecoration('State'),
                          style: const TextStyle(fontSize: 18),
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 2,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))],
                          keyboardType: TextInputType.text,
                          buildCounter: (context, {required currentLength, required maxLength, required isFocused}) => null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextField(
                          controller: _zipCodeController,
                          decoration: textFieldDecoration('Zip Code'),
                          style: const TextStyle(fontSize: 18),
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          buildCounter: (context, {required currentLength, required maxLength, required isFocused}) => null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Center(
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: elevatedButtonStyle(),
                      child: const Text('Continue', style: signInButtonTextStyle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}