import 'package:flutter/material.dart';
import 'theme.dart'; // Import the custom theme

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;

  void _handleSignIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }
    print('Sign In attempted with: $email, $password');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign In not implemented yet')),
    );
  }

  void _handleSignUp() {
    Navigator.pushNamed(context, '/role_selection'); // Navigate to role selection
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Welcome to Efficials!'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: textFieldDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: textFieldDecoration(
                  'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                obscureText: !_showPassword,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _handleSignIn,
                style: elevatedButtonStyle(),
                child: const Text('Sign In', style: signInButtonTextStyle),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: secondaryTextStyle,
                  ),
                  GestureDetector(
                    onTap: _handleSignUp,
                    child: const Text(
                      'Sign up',
                      style: linkTextStyle,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text('© 2025 Efficials', style: footerTextStyle),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}