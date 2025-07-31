import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/verification_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? token;
  
  const EmailVerificationScreen({
    super.key,
    this.token,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final VerificationService _verificationService = VerificationService();
  
  bool _isVerifying = true;
  bool _verificationSuccess = false;
  String _message = '';
  
  @override
  void initState() {
    super.initState();
    _verifyToken();
  }
  
  Future<void> _verifyToken() async {
    if (widget.token == null || widget.token!.isEmpty) {
      setState(() {
        _isVerifying = false;
        _verificationSuccess = false;
        _message = 'Invalid verification link. No token provided.';
      });
      return;
    }
    
    try {
      final success = await _verificationService.verifyEmail(widget.token!);
      
      setState(() {
        _isVerifying = false;
        _verificationSuccess = success;
        _message = success 
            ? 'Your email has been verified successfully!'
            : 'Verification failed. The link may be invalid or expired.';
      });
    } catch (e) {
      print('Error verifying email: $e');
      setState(() {
        _isVerifying = false;
        _verificationSuccess = false;
        _message = 'An error occurred during verification. Please try again.';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Email Verification',
          style: TextStyle(color: efficialsYellow),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isVerifying) ...[
                const CircularProgressIndicator(color: efficialsYellow),
                const SizedBox(height: 24),
                const Text(
                  'Verifying your email...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ] else ...[
                Icon(
                  _verificationSuccess ? Icons.check_circle : Icons.error,
                  size: 80,
                  color: _verificationSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  _verificationSuccess ? 'Verification Successful!' : 'Verification Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _verificationSuccess ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to login or profile screen
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/welcome', // Or appropriate route
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: efficialsYellow,
                    foregroundColor: efficialsBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    _verificationSuccess ? 'Continue to App' : 'Back to Login',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}