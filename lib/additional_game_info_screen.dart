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
  int? _officialsRequired; // No default value, starts as null
  final TextEditingController _gameFeeController = TextEditingController();
  final TextEditingController _opponentController = TextEditingController();
  bool _hireAutomatically = false;
  bool _isFromEdit = false;
  bool _isInitialized = false;
  bool _isAwayGame = false;

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
  final List<int> _officialsOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];

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
        _isAwayGame = args['isAwayGame'] == true;
        if (_isFromEdit) {
          _levelOfCompetition = args['levelOfCompetition'] as String?;
          _gender = args['gender'] as String?;
          _officialsRequired = int.tryParse(args['officialsRequired']?.toString() ?? '');
          _gameFeeController.text = args['gameFee'] as String? ?? '';
          _opponentController.text = args['opponent'] as String? ?? '';
          _hireAutomatically = args['hireAutomatically'] as bool? ?? false;
        }
      }
      _isInitialized = true;
    }
  }

  void _handleContinue() {
    if (!_isAwayGame) {
      if (_levelOfCompetition == null || _gender == null || _officialsRequired == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a level, gender, and number of officials')),
        );
        return;
      }
      if (_gameFeeController.text.trim().isEmpty || !RegExp(r'^\d+$').hasMatch(_gameFeeController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid game fee (numbers only)')),
        );
        return;
      }
    }

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final updatedArgs = {
      ...args,
      'id': args['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'levelOfCompetition': _isAwayGame ? null : _levelOfCompetition,
      'gender': _isAwayGame ? null : _gender,
      'officialsRequired': _isAwayGame ? 0 : _officialsRequired,
      'gameFee': _isAwayGame ? '0' : _gameFeeController.text.trim(),
      'opponent': _opponentController.text.trim(),
      'hireAutomatically': _isAwayGame ? false : _hireAutomatically,
      'isAway': _isAwayGame,
      'officialsHired': args['officialsHired'] ?? 0,
      'selectedOfficials': args['selectedOfficials'] ?? <Map<String, dynamic>>[],
    };

    print('handleContinue - Args: $updatedArgs, Edit: $_isFromEdit');
    Navigator.pushNamed(
      context,
      _isAwayGame || _hireAutomatically ? '/review_game_info' : '/select_officials',
      arguments: _isFromEdit
          ? {...updatedArgs, 'isEdit': true, 'isFromGameInfo': args['isFromGameInfo'] ?? false}
          : updatedArgs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final List<String> currentGenders = _levelOfCompetition == 'College' || _levelOfCompetition == 'Adult'
        ? _adultGenders
        : _youthGenders;

    if (_gender != null && !currentGenders.contains(_gender)) {
      _gender = null;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Additional Game Info', style: appBarTextStyle),
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
                  if (!_isAwayGame) ...[
                    DropdownButtonFormField<String>(
                      decoration: textFieldDecoration('Level of Competition'),
                      value: _levelOfCompetition,
                      hint: const Text('Select level'),
                      onChanged: (value) => setState(() => _levelOfCompetition = value),
                      items: _competitionLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: textFieldDecoration('Gender'),
                      value: _gender,
                      hint: const Text('Select gender'),
                      onChanged: (value) => setState(() => _gender = value),
                      items: currentGenders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      decoration: textFieldDecoration('Number of Officials Required'),
                      value: _officialsRequired,
                      hint: const Text('Number of Officials Required'),
                      onChanged: (value) => setState(() => _officialsRequired = value),
                      items: _officialsOptions.map((num) => DropdownMenuItem(value: num, child: Text(num.toString()))).toList(),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _gameFeeController,
                      decoration: textFieldDecoration('Game Fee per Official'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 20),
                  ],
                  TextField(
                    controller: _opponentController,
                    decoration: textFieldDecoration('Opponent'),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 20),
                  if (!_isAwayGame)
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
    _gameFeeController.dispose();
    _opponentController.dispose();
    super.dispose();
  }
}