import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme.dart';
import 'game_template.dart'; // Import the GameTemplate model

class AdditionalGameInfoScreen extends StatefulWidget {
  const AdditionalGameInfoScreen({super.key});

  @override
  _AdditionalGameInfoScreenState createState() =>
      _AdditionalGameInfoScreenState();
}

class _AdditionalGameInfoScreenState extends State<AdditionalGameInfoScreen> {
  String? _levelOfCompetition;
  String? _gender;
  int? _officialsRequired;
  List<String> _currentGenders = ['Boys', 'Girls', 'Co-ed'];
  final TextEditingController _gameFeeController = TextEditingController();
  final TextEditingController _opponentController = TextEditingController();
  bool _hireAutomatically = false;
  bool _isFromEdit = false;
  bool _isInitialized = false;
  bool _isAwayGame = false;
  GameTemplate? template; // Store the selected template

  final List<String> _competitionLevels = [
    '6U',
    '7U',
    '8U',
    '9U',
    '10U',
    '11U',
    '12U',
    '13U',
    '14U',
    '15U',
    '16U',
    '17U',
    '18U',
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
      _currentGenders = _youthGenders;
    } else {
      _currentGenders =
          (_levelOfCompetition == 'College' || _levelOfCompetition == 'Adult')
              ? _adultGenders
              : _youthGenders;
    }
  }

  void _showHireInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Hire Automatically', 
            style: TextStyle(color: efficialsYellow, fontSize: 20, fontWeight: FontWeight.bold)),
        content: const Text(
          'When checked, the system will automatically assign officials based on your preferences and availability. Uncheck to manually select officials.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _isFromEdit = args['isEdit'] == true;
        _isAwayGame = args['isAwayGame'] == true;
        template = args['template'] as GameTemplate?; // Extract the template

        // Pre-fill fields from the template if available, otherwise use args
        if (template != null) {
          _levelOfCompetition = template!.includeLevelOfCompetition &&
                  template!.levelOfCompetition != null
              ? template!.levelOfCompetition
              : args['levelOfCompetition'] as String?;
          _updateCurrentGenders();
          _gender = template!.includeGender && template!.gender != null
              ? template!.gender
              : (args['gender'] as String?);
          if (_gender != null && !_currentGenders.contains(_gender)) {
            _gender = null;
          }
          _officialsRequired = template!.includeOfficialsRequired &&
                  template!.officialsRequired != null
              ? template!.officialsRequired
              : (args['officialsRequired'] != null
                  ? int.tryParse(args['officialsRequired'].toString())
                  : null);
          _gameFeeController.text =
              template!.includeGameFee && template!.gameFee != null
                  ? template!.gameFee!
                  : (args['gameFee']?.toString() ?? '');
          _hireAutomatically = template!.includeHireAutomatically &&
                  template!.hireAutomatically != null
              ? template!.hireAutomatically!
              : (args['hireAutomatically'] as bool? ?? false);
        } else {
          _levelOfCompetition = args['levelOfCompetition'] as String?;
          _updateCurrentGenders();
          final genderArg = args['gender'] as String?;
          _gender = (genderArg != null && _currentGenders.contains(genderArg))
              ? genderArg
              : null;
          _officialsRequired = args['officialsRequired'] != null
              ? int.tryParse(args['officialsRequired'].toString())
              : null;
          _gameFeeController.text = args['gameFee']?.toString() ?? '';
          _hireAutomatically = args['hireAutomatically'] as bool? ?? false;
        }
        // Opponent field should never be populated from templates initially
        // But should preserve existing opponent value from args (e.g., during edit flow)
        _opponentController.text = args['opponent'] as String? ?? '';
        
        // Validate that _officialsRequired is a valid option
        if (_officialsRequired != null && !_officialsOptions.contains(_officialsRequired)) {
          _officialsRequired = null;
        }
        
        // Clear game fee if it's "0" (from away game) so hint text shows
        if (_gameFeeController.text == '0' || _gameFeeController.text == '0.0' || _gameFeeController.text == '0.00') {
          _gameFeeController.text = '';
        }
      }
      _isInitialized = true;
    }
  }

  void _handleContinue() {
    if (!_isAwayGame) {
      if (_levelOfCompetition == null ||
          _gender == null ||
          _officialsRequired == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please select a level, gender, and number of officials')),
        );
        return;
      }
      final feeText = _gameFeeController.text.trim();
      if (feeText.isEmpty || !RegExp(r'^\d+(\.\d+)?$').hasMatch(feeText)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please enter a valid game fee (e.g., 50 or 50.00)')),
        );
        return;
      }
      final fee = double.parse(feeText);
      if (fee < 1 || fee > 99999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Game fee must be between 1 and 99,999')),
        );
        return;
      }
    }

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
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
      'selectedOfficials':
          args['selectedOfficials'] ?? <Map<String, dynamic>>[],
      'template': template,
      'sport': template?.includeSport == true ? template?.sport : args['sport'],
      'fromScheduleDetails': args['fromScheduleDetails'] ?? false,
      'scheduleId': args['scheduleId'],
      'scheduleName': args['scheduleName'],
    };

    Navigator.pushNamed(
      context,
      _isAwayGame ? '/review_game_info' : '/select_officials',
      arguments: _isFromEdit
          ? {
              ...updatedArgs,
              'isEdit': true,
              'isFromGameInfo': args['isFromGameInfo'] ?? false
            }
          : updatedArgs,
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateCurrentGenders();
    if (_gender != null && !_currentGenders.contains(_gender)) {
      _gender = null;
    }

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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Additional Game Info',
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
                      if (!_isAwayGame) ...[
                        DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Level of competition'),
                          value: _levelOfCompetition,
                          hint: const Text('Level of competition',
                              style: TextStyle(color: efficialsGray)),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          dropdownColor: darkSurface,
                          onChanged: (value) {
                            setState(() {
                              _levelOfCompetition = value;
                              _updateCurrentGenders();
                              if (_gender != null &&
                                  !_currentGenders.contains(_gender)) {
                                _gender = null;
                              }
                            });
                          },
                          items: _competitionLevels
                              .map((level) => DropdownMenuItem(
                                  value: level,
                                  child: Text(level,
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          decoration: textFieldDecoration('Gender'),
                          value: _gender,
                          hint: const Text('Select gender',
                              style: TextStyle(color: efficialsGray)),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          dropdownColor: darkSurface,
                          onChanged: (value) => setState(() => _gender = value),
                          items: _currentGenders
                              .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender,
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<int>(
                          decoration:
                              textFieldDecoration('Required number of officials'),
                          value: _officialsRequired,
                          hint: const Text('Required number of officials',
                              style: TextStyle(color: efficialsGray)),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          dropdownColor: darkSurface,
                          onChanged: (value) =>
                              setState(() => _officialsRequired = value),
                          items: _officialsOptions
                              .map((num) => DropdownMenuItem(
                                  value: num,
                                  child: Text(num.toString(),
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _gameFeeController,
                          decoration:
                              textFieldDecoration('Game Fee per Official').copyWith(
                            prefixText: '\$',
                            prefixStyle: const TextStyle(color: Colors.white),
                            hintText: 'Enter fee (e.g., 50 or 50.00)',
                            hintStyle: const TextStyle(color: efficialsGray),
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            LengthLimitingTextInputFormatter(
                                7), // Allow for "99999.99"
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextField(
                        controller: _opponentController,
                        decoration: textFieldDecoration('Opponent'),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 20),
                      if (!_isAwayGame)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _hireAutomatically,
                              onChanged: (value) => setState(
                                  () => _hireAutomatically = value ?? false),
                              activeColor: efficialsYellow,
                              checkColor: efficialsBlack,
                            ),
                            const Text('Hire Automatically',
                                style: TextStyle(color: Colors.white)),
                            IconButton(
                              icon: const Icon(Icons.help_outline,
                                  color: efficialsYellow),
                              onPressed: _showHireInfoDialog,
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
                  child: const Text('Continue', style: signInButtonTextStyle),
                ),
              ],
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
