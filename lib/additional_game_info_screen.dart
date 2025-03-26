import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class AdditionalGameInfoScreen extends StatefulWidget {
  const AdditionalGameInfoScreen({super.key});

  @override
  _AdditionalGameInfoScreenState createState() => _AdditionalGameInfoScreenState();
}

class _AdditionalGameInfoScreenState extends State<AdditionalGameInfoScreen> {
  String? _levelOfCompetition;
  String? _gender;
  final TextEditingController _officialsRequiredController = TextEditingController();
  final TextEditingController _gameFeeController = TextEditingController();
  bool _hireAutomatically = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isFromEdit = false;
  bool _isInitialized = false;

  final List<String> _competitionLevels = [
    'Grade School',
    'Middle School',
    'Underclass',
    'JV',
    'Varsity',
    'College',
    'Adult'
  ];
  final List<String> _youthGenders = ['Boys', 'Girls', 'Co-ed'];
  final List<String> _adultGenders = ['Men', 'Women', 'Co-ed'];

  void _showHireInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hire Automatically'),
        content: const Text('When checked, the system will automatically assign officials based on your preferences and availability. Uncheck to manually select officials.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: efficialsBlue)),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        print('didChangeDependencies - Args: $args');
        _isFromEdit = args['isEdit'] == true;
        if (_isFromEdit) {
          _levelOfCompetition = args['levelOfCompetition'] as String?;
          _gender = args['gender'] as String?;
          _officialsRequiredController.text = args['officialsRequired'] as String? ?? '';
          _gameFeeController.text = args['gameFee'] as String? ?? '';
          _hireAutomatically = args['hireAutomatically'] as bool? ?? false;
        }
      }
      _isInitialized = true;
    }
  }

  void _handleContinue() {
    if (_levelOfCompetition == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a level and gender')),
      );
      return;
    }

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    print('handleContinue - isFromEdit: $_isFromEdit, args: $args');
    if (_isFromEdit) {
      Navigator.pushNamed(
        context,
        '/review_game_info',
        arguments: {
          ...args,
          'levelOfCompetition': _levelOfCompetition,
          'gender': _gender,
          'officialsRequired': _officialsRequiredController.text.trim(),
          'gameFee': _gameFeeController.text.trim(),
          'hireAutomatically': _hireAutomatically,
          'isEdit': true,
          'isFromGameInfo': args['isFromGameInfo'] ?? false, // Pass isFromGameInfo
        },
      );
    } else {
      print('Navigating to /select_officials with args: ${{
        ...args,
        'levelOfCompetition': _levelOfCompetition,
        'gender': _gender,
        'officialsRequired': _officialsRequiredController.text.trim(),
        'gameFee': _gameFeeController.text.trim(),
        'hireAutomatically': _hireAutomatically,
      }}');
      Navigator.pushNamed(context, '/select_officials', arguments: {
        ...args,
        'levelOfCompetition': _levelOfCompetition,
        'gender': _gender,
        'officialsRequired': _officialsRequiredController.text.trim(),
        'gameFee': _gameFeeController.text.trim(),
        'hireAutomatically': _hireAutomatically,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final scheduleName = args['scheduleName'] as String;
    final sport = args['sport'] as String;
    final location = args['location'] as String;
    final DateTime date = args['date'] as DateTime? ?? DateTime.now(); // Default to now if null
    final TimeOfDay time = args['time'] as TimeOfDay;

    final List<String> currentGenders = _levelOfCompetition == 'College' || _levelOfCompetition == 'Adult'
        ? _adultGenders
        : _youthGenders;

    if (_gender != null && !currentGenders.contains(_gender)) {
      _gender = null;
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Additional Game Info',
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: textFieldDecoration('Level of Competition'),
                    value: _levelOfCompetition,
                    onChanged: (value) => setState(() => _levelOfCompetition = value),
                    items: _competitionLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: textFieldDecoration('Gender'),
                    value: _gender,
                    onChanged: (value) => setState(() => _gender = value),
                    items: currentGenders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _officialsRequiredController,
                    decoration: textFieldDecoration('Number of Officials Required'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _gameFeeController,
                    decoration: textFieldDecoration('Game Fee per Official'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _hireAutomatically,
                        onChanged: (value) => setState(() => _hireAutomatically = value ?? false),
                        activeColor: efficialsBlue,
                      ),
                      const Text('Hire Automatically'),
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: efficialsBlue),
                        onPressed: _showHireInfoDialog,
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

  @override
  void dispose() {
    _officialsRequiredController.dispose();
    _gameFeeController.dispose();
    super.dispose();
  }
}