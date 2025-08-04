import 'package:flutter/material.dart';
import '../../shared/theme.dart';

class OfficialSignUpStep2 extends StatefulWidget {
  const OfficialSignUpStep2({super.key});

  @override
  _OfficialSignUpStep2State createState() => _OfficialSignUpStep2State();
}

class _OfficialSignUpStep2State extends State<OfficialSignUpStep2> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _maxDistanceController = TextEditingController();
  
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _appNotifications = true;

  late Map<String, dynamic> previousData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    previousData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  }

  void _handleContinue() {
    // For testing purposes, provide defaults if fields are empty
    final address = _addressController.text.trim().isNotEmpty 
        ? _addressController.text.trim() 
        : '123 Main St';
    final city = _cityController.text.trim().isNotEmpty 
        ? _cityController.text.trim() 
        : 'Chicago';
    final state = _stateController.text.trim().isNotEmpty 
        ? _stateController.text.trim() 
        : 'IL';
    final zipCode = _zipController.text.trim().isNotEmpty 
        ? _zipController.text.trim() 
        : '60601';
    final maxDistanceText = _maxDistanceController.text.trim().isNotEmpty 
        ? _maxDistanceController.text.trim() 
        : '25';

    // Validate max distance if provided
    final maxDistance = double.tryParse(maxDistanceText);
    if (maxDistance == null || maxDistance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid maximum travel distance')),
      );
      return;
    }

    final updatedData = {
      ...previousData,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'maxTravelDistance': maxDistance,
      'emailNotifications': _emailNotifications,
      'smsNotifications': _smsNotifications,
      'appNotifications': _appNotifications,
    };

    Navigator.pushNamed(context, '/official_signup_step3', arguments: updatedData);
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Location & Preferences',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 2 of 4: Work Preferences',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Home Address',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _addressController,
                        decoration: textFieldDecoration('Street Address'),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _cityController,
                              decoration: textFieldDecoration('City'),
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _stateController,
                              decoration: textFieldDecoration('State'),
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _zipController,
                              decoration: textFieldDecoration('ZIP'),
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Travel Preferences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _maxDistanceController,
                        decoration: textFieldDecoration('Max Travel Distance (miles)'),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Notification Preferences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Email Notifications', style: TextStyle(color: Colors.white)),
                        value: _emailNotifications,
                        onChanged: (value) => setState(() => _emailNotifications = value ?? true),
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      CheckboxListTile(
                        title: const Text('SMS Notifications', style: TextStyle(color: Colors.white)),
                        value: _smsNotifications,
                        onChanged: (value) => setState(() => _smsNotifications = value ?? false),
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      CheckboxListTile(
                        title: const Text('App Notifications', style: TextStyle(color: Colors.white)),
                        value: _appNotifications,
                        onChanged: (value) => setState(() => _appNotifications = value ?? true),
                        activeColor: efficialsYellow,
                        checkColor: efficialsBlack,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _maxDistanceController.dispose();
    super.dispose();
  }
}