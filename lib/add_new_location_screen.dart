import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

const List<String> usStates = [
  'AL',
  'AK',
  'AZ',
  'AR',
  'CA',
  'CO',
  'CT',
  'DE',
  'FL',
  'GA',
  'HI',
  'ID',
  'IL',
  'IN',
  'IA',
  'KS',
  'KY',
  'LA',
  'ME',
  'MD',
  'MA',
  'MI',
  'MN',
  'MS',
  'MO',
  'MT',
  'NE',
  'NV',
  'NH',
  'NJ',
  'NM',
  'NY',
  'NC',
  'ND',
  'OH',
  'OK',
  'OR',
  'PA',
  'RI',
  'SC',
  'SD',
  'TN',
  'TX',
  'UT',
  'VT',
  'VA',
  'WA',
  'WV',
  'WI',
  'WY'
];

class AddNewLocationScreen extends StatefulWidget {
  const AddNewLocationScreen({super.key});

  @override
  State<AddNewLocationScreen> createState() => _AddNewLocationScreenState();
}

class _AddNewLocationScreenState extends State<AddNewLocationScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  bool _isValidState(String state) => usStates.contains(state.toUpperCase());

  void _handleContinue() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim().toUpperCase();
    final zip = _zipCodeController.text.trim();

    if (name.isEmpty ||
        address.isEmpty ||
        city.isEmpty ||
        state.isEmpty ||
        zip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (state.length != 2 || !_isValidState(state)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 2-letter state code')),
      );
      return;
    }
    if (zip.length != 5 || !RegExp(r'^\d{5}$').hasMatch(zip)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 5-digit zip code')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString('saved_locations');
    final locations = locationsJson != null && locationsJson.isNotEmpty
        ? List<Map<String, dynamic>>.from(jsonDecode(locationsJson))
        : [];
    if (locations.any(
        (loc) => loc['name'].toString().toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A location with this name already exists')),
      );
      return;
    }

    final newLocation = {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'id': DateTime.now().millisecondsSinceEpoch,
    };
    Navigator.pop(context, newLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add New Location', style: appBarTextStyle),
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
                    style:
                        const TextStyle(fontSize: 18, color: primaryTextColor),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _addressController,
                    decoration: textFieldDecoration('Address'),
                    style:
                        const TextStyle(fontSize: 18, color: primaryTextColor),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _cityController,
                    decoration: textFieldDecoration('City'),
                    style:
                        const TextStyle(fontSize: 18, color: primaryTextColor),
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
                          style: const TextStyle(
                              fontSize: 18, color: primaryTextColor),
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 2,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z]'))
                          ],
                          buildCounter: (context,
                                  {required currentLength,
                                  required maxLength,
                                  required isFocused}) =>
                              null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextField(
                          controller: _zipCodeController,
                          decoration: textFieldDecoration('Zip Code'),
                          style: const TextStyle(
                              fontSize: 18, color: primaryTextColor),
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          buildCounter: (context,
                                  {required currentLength,
                                  required maxLength,
                                  required isFocused}) =>
                              null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Center(
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: elevatedButtonStyle(),
                      child: const Text('Continue', style: buttonTextStyle),
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
