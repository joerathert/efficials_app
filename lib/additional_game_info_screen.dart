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
  int? _officialsRequired;
  List<String> _currentGenders = ['Boys', 'Girls', 'Co-ed']; // Initialize with default value
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

  void _updateCurrentGenders() {
    if (_levelOfCompetition == null) {
      print('Warning: _levelOfCompetition is null, defaulting to _youthGenders');
      _currentGenders = _youthGenders;
    } else {
      _currentGenders = (_levelOfCompetition == 'College' || _levelOfCompetition == 'Adult')
          ? _adultGenders
          : _youthGenders;
    }
  }

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
        // Ensure _levelOfCompetition is never null for non-away games
        _levelOfCompetition = args['levelOfCompetition'] as String? ?? (_isAwayGame ? null : 'Grade School');
        print('didChangeDependencies - _levelOfCompetition: $_levelOfCompetition, _isAwayGame: $_isAwayGame');
        // Update _currentGenders
        _updateCurrentGenders();
        // Validate gender against currentGenders
        String? initialGender = args['gender'] as String?;
        if (initialGender != null && _currentGenders.contains(initialGender)) {
          _gender = initialGender;
        } else {
          _gender = null;
        }
        print('didChangeDependencies - _gender: $_gender, _currentGenders: $_currentGenders');
        _officialsRequired = args['officialsRequired'] != null
            ? int.tryParse(args['officialsRequired'].toString()) ?? (_isAwayGame ? 0 : 1)
            : (_isAwayGame ? 0 : 1);
        _gameFeeController.text = args['gameFee']?.toString() ?? '';
        _opponentController.text = args['opponent'] as String? ?? '';
        _hireAutomatically = args['hireAutomatically'] as bool? ?? false;
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
      final feeText = _gameFeeController.text.trim();
      if (feeText.isEmpty || !RegExp(r'^\d+$').hasMatch(feeText)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid game fee (numbers only)')),
        );
        return;
      }
      final fee = int.parse(feeText);
      if (fee < 1 || fee > 99999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game fee must be between 1 and 99,999')),
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
    print('build - Start: _levelOfCompetition: $_levelOfCompetition, _currentGenders: $_currentGenders, _gender: $_gender');
    // Validate _gender against currentGenders as a fallback
    if (_gender != null && !_currentGenders.contains(_gender)) {
      print('build - Resetting _gender because it is not in _currentGenders');
      _gender = null;
    }
    // Log the items lists for both dropdowns
    final levelItems = _competitionLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList();
    print('build - Level of Competition Dropdown Items: $levelItems');
    print('build - _currentGenders before Gender Dropdown: $_currentGenders');
    final genderItems = _currentGenders.isNotEmpty
        ? _currentGenders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList()
        : [const DropdownMenuItem(value: 'Boys', child: Text('Boys'))];
    print('build - Gender Dropdown Items: $genderItems');

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
                    if (!_isInitialized || _levelOfCompetition == null || _currentGenders.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      DropdownButtonFormField<String>(
                        decoration: textFieldDecoration('Level of Competition'),
                        value: _levelOfCompetition,
                        hint: const Text('Select level'),
                        onChanged: (value) {
                          setState(() {
                            _levelOfCompetition = value;
                            // Update _currentGenders when level changes
                            _updateCurrentGenders();
                            if (_gender != null && !_currentGenders.contains(_gender)) {
                              _gender = null;
                            }
                          });
                        },
                        items: _competitionLevels.isNotEmpty
                            ? _competitionLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList()
                            : [const DropdownMenuItem(value: 'Grade School', child: Text('Grade School'))],
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        decoration: textFieldDecoration('Gender'),
                        value: _gender,
                        hint: const Text('Select gender'),
                        onChanged: (value) => setState(() => _gender = value),
                        items: _currentGenders.isNotEmpty
                            ? _currentGenders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList()
                            : [const DropdownMenuItem(value: 'Boys', child: Text('Boys'))],
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
                        decoration: textFieldDecoration('Game Fee per Official').copyWith(
                          prefixText: '\$',
                          hintText: 'Enter fee (e.g., 50)',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
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