import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Map<String, dynamic>? location;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      print('EditLocationScreen - Arguments received: $args');
      if (args != null) {
        // Check if args is the location directly or wrapped in a 'location' key
        if (args.containsKey('location')) {
          location = args['location'] as Map<String, dynamic>?;
          print('EditLocationScreen - Using wrapped location: $location');
        } else {
          location = args;
          print('EditLocationScreen - Using direct location: $location');
        }
        if (location != null && location!.containsKey('name')) {
          _nameController.text = location!['name']?.toString() ?? '';
          _addressController.text = location!['address']?.toString() ?? '';
          _cityController.text = location!['city']?.toString() ?? '';
          _stateController.text = location!['state']?.toString() ?? '';
          _zipCodeController.text = location!['zip']?.toString() ?? '';
          print('EditLocationScreen - Fields populated: name=${_nameController.text}, address=${_addressController.text}, city=${_cityController.text}, state=${_stateController.text}, zip=${_zipCodeController.text}');
        } else {
          print('EditLocationScreen - Location is null or missing name');
        }
      } else {
        print('EditLocationScreen - No arguments received');
      }
      _isInitialized = true;
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
      'id': location?['id'],
    };
    Navigator.of(context).pop(updatedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Icon(
          Icons.sports,
          color: efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Edit Location',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: efficialsYellow,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: darkSurface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: textFieldDecoration('Location Name'),
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _addressController,
                        decoration: textFieldDecoration('Address'),
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _cityController,
                        decoration: textFieldDecoration('City'),
                        style: const TextStyle(fontSize: 16, color: Colors.white),
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
                              style: const TextStyle(fontSize: 16, color: Colors.white),
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
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              buildCounter: (context, {required currentLength, required maxLength, required isFocused}) => null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _handleContinue,
                  style: elevatedButtonStyle(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  ),
                  child: const Text('Save Changes', style: signInButtonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}