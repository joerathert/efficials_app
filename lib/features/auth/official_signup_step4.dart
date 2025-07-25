import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../shared/theme.dart';
import '../../shared/services/game_service.dart';
import '../../shared/models/database_models.dart';

class OfficialSignUpStep4 extends StatefulWidget {
  const OfficialSignUpStep4({super.key});

  @override
  _OfficialSignUpStep4State createState() => _OfficialSignUpStep4State();
}

class _OfficialSignUpStep4State extends State<OfficialSignUpStep4> {
  String? _selectedRate;
  
  late Map<String, dynamic> previousData;
  bool _isCreatingAccount = false;
  final GameService _gameService = GameService();
  
  final List<String> rateOptions = [
    '\$25',
    '\$30',
    '\$35',
    '\$40',
    '\$45',
    '\$50',
    '\$55',
    '\$60',
    '\$65',
    '\$70',
    '\$75',
    '\$80',
    '\$85',
    '\$90',
    '\$95',
    '\$100',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    previousData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    
    // Pre-select default rate for testing convenience
    if (_selectedRate == null) {
      setState(() {
        _selectedRate = '\$50';
      });
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _handleComplete() async {
    setState(() {
      _isCreatingAccount = true;
    });

    try {
      // Get rate per game from dropdown
      double? ratePerGame;
      if (_selectedRate != null) {
        ratePerGame = double.tryParse(_selectedRate!.replaceAll('\$', ''));
      }

      // Create OfficialUser account
      final officialUser = OfficialUser(
        email: previousData['email'],
        passwordHash: _hashPassword(previousData['password']),
        phone: previousData['phone'],
        firstName: previousData['firstName'],
        lastName: previousData['lastName'],
        emailVerified: false, // Will be verified later
        phoneVerified: false, // Will be verified later
        profileVerified: false, // Will be verified by admin
        status: 'active',
      );

      // TODO: Save officialUser to database using OfficialUserRepository
      // For now, we'll show success and navigate to a placeholder screen
      
      // Create Official profile entry
      final official = Official(
        name: '${previousData['firstName']} ${previousData['lastName']}',
        userId: 1, // TODO: Get current scheduler user ID who created this (for now)
        email: previousData['email'],
        phone: previousData['phone'],
        bio: null,
        isUserAccount: true,
        availabilityStatus: 'available',
        experienceYears: 0, // Will be calculated from individual sports
      );

      // TODO: Save official to database and get ID
      // TODO: Save sports certifications to official_sports table
      // TODO: Save availability preferences
      // TODO: Save notification preferences

      // For now, show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Official account created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to Official home screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/official_home',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingAccount = false;
        });
      }
    }
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
          onPressed: _isCreatingAccount ? null : () => Navigator.pop(context),
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
                'Profile & Verification',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 4 of 4: Complete Your Profile',
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
                      // Summary of registration
                      _buildRegistrationSummary(),
                      const SizedBox(height: 32),
                      DropdownButtonFormField<String>(
                        value: _selectedRate,
                        decoration: const InputDecoration(
                          labelText: 'Rate per Game (Optional)',
                          labelStyle: TextStyle(color: Colors.grey),
                          helperText: 'Your preferred fee per game (defaults to \$50)',
                          helperStyle: TextStyle(color: Colors.grey),
                          fillColor: darkSurface,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: darkSurface,
                        style: const TextStyle(color: Colors.white),
                        hint: const Text('Select rate', style: TextStyle(color: Colors.grey)),
                        items: rateOptions.map((rate) {
                          return DropdownMenuItem(
                            value: rate,
                            child: Text(rate),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRate = value;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: darkSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: efficialsYellow.withOpacity(0.3)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: efficialsYellow),
                                SizedBox(width: 8),
                                Text(
                                  'Account Verification',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: efficialsYellow,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              '• Your email will need to be verified\n'
                              '• Your profile will be reviewed by administrators\n'
                              '• You\'ll receive notification when approved\n'
                              '• You can then start receiving game assignments',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isCreatingAccount ? null : _handleComplete,
                          style: elevatedButtonStyle(),
                          child: _isCreatingAccount
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Creating Account...', style: signInButtonTextStyle),
                                  ],
                                )
                              : const Text('Complete Registration', style: signInButtonTextStyle),
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

  Widget _buildRegistrationSummary() {
    final selectedSports = previousData['selectedSports'] as Map<String, Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registration Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Name:', '${previousData['firstName']} ${previousData['lastName']}'),
          _buildSummaryRow('Email:', previousData['email']),
          if (previousData['phone']?.isNotEmpty == true)
            _buildSummaryRow('Phone:', previousData['phone']),
          _buildSummaryRow('Location:', '${previousData['city']}, ${previousData['state']}'),
          _buildSummaryRow('Max Travel:', '${previousData['maxTravelDistance']} miles'),
          _buildSummaryRow('Sports:', selectedSports.keys.join(', ')),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}