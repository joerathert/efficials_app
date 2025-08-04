import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/auth_service.dart';
import '../../utils/officials_data.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final result = await AuthService.login(email, password);

    if (!mounted) return;

    if (result.success) {
      if (result.userType == 'scheduler') {
        // CRITICAL: Also update SharedPreferences for backwards compatibility
        final prefs = await SharedPreferences.getInstance();
        String schedulerTypeForPrefs = result.schedulerType!;
        // Convert database format to SharedPreferences format
        if (schedulerTypeForPrefs == 'athletic_director') {
          schedulerTypeForPrefs = 'Athletic Director';
        }
        await prefs.setString('schedulerType', schedulerTypeForPrefs);

        if (mounted) _navigateToSchedulerHome(result.schedulerType!);
      } else if (result.userType == 'official') {
        if (mounted) _navigateToOfficialHome();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  void _navigateToSchedulerHome(String schedulerType) {
    switch (schedulerType) {
      case 'athletic_director':
        Navigator.pushReplacementNamed(context, '/athletic_director_home');
        break;
      case 'assigner':
        Navigator.pushReplacementNamed(context, '/assigner_home');
        break;
      case 'coach':
        Navigator.pushReplacementNamed(context, '/coach_home');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown scheduler type')),
        );
    }
  }

  void _navigateToOfficialHome() {
    Navigator.pushReplacementNamed(context, '/official_home');
  }

  void _quickLogin(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
    _handleSignIn();
  }

  void _handleSignUp() {
    Navigator.pushNamed(
        context, '/role_selection'); // Navigate to role selection
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: efficialsYellow,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to your account to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
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
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: textFieldDecoration('Enter your email'),
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        style: const TextStyle(color: primaryTextColor),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        decoration: textFieldDecoration(
                          'Enter your password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: secondaryTextColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: !_showPassword,
                        style: const TextStyle(color: primaryTextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _handleSignIn,
                  style: elevatedButtonStyle(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                  ),
                  child: const Text('Sign In', style: signInButtonTextStyle),
                ),
                const SizedBox(height: 30),
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
                const SizedBox(height: 30),

                // Quick Access for Testing
                if (kDebugMode)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: darkSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quick Access (Testing)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: efficialsYellow,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                  context, '/database_test'),
                              child: const Icon(
                                Icons.settings,
                                color: efficialsYellow,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _quickLogin('ad@test.com', 'test123'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('AD',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _quickLogin('assigner@test.com', 'test123'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('Assigner',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _quickLogin('coach@test.com', 'test123'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('Coach',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Football Officials Quick Access (Generated from Real Data)
                        ..._buildOfficialButtons(),
                        const SizedBox(height: 8),
                        Text(
                          'Tap ⚙️ to create all 123 real football officials first',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
                const Text('© 2025 Efficials', style: footerTextStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOfficialButtons() {
    final officials = OfficialsDataProvider.getAllOfficials();
    List<Widget> widgets = [];
    
    // Display ALL 123 officials (41 rows of 3 buttons each)
    final displayOfficials = officials;
    
    for (int i = 0; i < displayOfficials.length; i += 3) {
      final rowOfficials = displayOfficials.skip(i).take(3).toList();
      
      widgets.add(const SizedBox(height: 8));
      
      List<Widget> rowButtons = [];
      for (int j = 0; j < rowOfficials.length; j++) {
        if (j > 0) rowButtons.add(const SizedBox(width: 8));
        rowButtons.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () => _quickLogin(rowOfficials[j].email, 'test123'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                rowOfficials[j].displayName,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        );
      }
      
      widgets.add(Row(children: rowButtons));
    }
    
    return widgets;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
