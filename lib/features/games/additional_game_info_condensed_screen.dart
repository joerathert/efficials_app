import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme.dart';
import '../../shared/services/user_session_service.dart';
import 'game_template.dart'; // Import the GameTemplate model

class AdditionalGameInfoCondensedScreen extends StatefulWidget {
  final Map<String, dynamic>? args;

  const AdditionalGameInfoCondensedScreen({Key? key, this.args})
      : super(key: key);

  @override
  _AdditionalGameInfoCondensedScreenState createState() =>
      _AdditionalGameInfoCondensedScreenState();
}

class _AdditionalGameInfoCondensedScreenState
    extends State<AdditionalGameInfoCondensedScreen> {
  int? _officialsRequired;
  final TextEditingController _gameFeeController = TextEditingController();
  final TextEditingController _opponentController = TextEditingController();
  bool _hireAutomatically = false;
  bool _isFromEdit = false;
  bool _isInitialized = false;
  bool _isAwayGame = false;
  GameTemplate? template; // Store the selected template

  final List<int> _officialsOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  Future<Map<String, dynamic>> _loadAssignerDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final sport = prefs.getString('assigner_sport');
    
    if (sport != null) {
      final defaultsKey = 'assigner_sport_defaults_${sport.toLowerCase()}';
      final defaultOfficials = prefs.getString('${defaultsKey}_officials');
      final defaultGameFee = prefs.getString('${defaultsKey}_game_fee');
      
      return {
        'officials': defaultOfficials != null ? int.tryParse(defaultOfficials) : null,
        'gameFee': defaultGameFee,
      };
    }
    
    return {};
  }

  void _showHireInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Hire Automatically', style: TextStyle(color: primaryTextColor)),
        content: const Text(
            'When checked, the system will automatically assign officials based on your preferences and availability. Uncheck to manually select officials.',
            style: TextStyle(color: primaryTextColor)),
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
      _initializeAsync();
    }
  }

  Future<void> _initializeAsync() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _isFromEdit = args['isEdit'] == true;
      _isAwayGame = args['isAwayGame'] == true || args['isAway'] == true;
      template = args['template'] as GameTemplate?; // Extract the template

      // Load assigner defaults (only for assigner flow, not for edit mode)
      Map<String, dynamic> defaults = {};
      final isAssignerFlow = args['isAssignerFlow'] == true;
      if (isAssignerFlow && !_isFromEdit) {
        defaults = await _loadAssignerDefaults();
      }

      // Pre-fill fields from the template if available, otherwise use args or Coach data, then defaults
      if (template != null) {
        _officialsRequired = template!.includeOfficialsRequired &&
                template!.officialsRequired != null
            ? template!.officialsRequired
            : (args['officialsRequired'] != null
                ? int.tryParse(args['officialsRequired'].toString())
                : defaults['officials']);
        _gameFeeController.text =
            template!.includeGameFee && template!.gameFee != null
                ? template!.gameFee!
                : (args['gameFee']?.toString() ?? defaults['gameFee'] ?? '');
        _hireAutomatically = template!.includeHireAutomatically &&
                template!.hireAutomatically != null
            ? template!.hireAutomatically!
            : (args['hireAutomatically'] as bool? ?? false);
      } else {
        _officialsRequired = args['officialsRequired'] != null
            ? int.tryParse(args['officialsRequired'].toString())
            : defaults['officials'];
        _gameFeeController.text = args['gameFee']?.toString() ?? defaults['gameFee'] ?? '';
        _hireAutomatically = args['hireAutomatically'] as bool? ?? false;
      }
      // Opponent field should only be populated from args during edit flow
      // Never pre-fill opponent for new games in assigner flow
      if (_isFromEdit) {
        _opponentController.text = args['opponent'] as String? ?? '';
      } else {
        _opponentController.text = '';
      }
    }
    
    // Auto-populate opponent field for away games with AD's school info
    if (_isAwayGame) {
      _populateOpponentForAwayGame();
    }
    
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _populateOpponentForAwayGame() async {
    try {
      final userSessionService = UserSessionService.instance;
      final currentUser = await userSessionService.getCurrentSchedulerUser();
      
      if (currentUser != null &&
          currentUser.schoolName != null &&
          currentUser.mascot != null &&
          currentUser.schoolName!.trim().isNotEmpty &&
          currentUser.mascot!.trim().isNotEmpty) {
        final schoolInfo = '${currentUser.schoolName!.trim()} ${currentUser.mascot!.trim()}';
        _opponentController.text = schoolInfo;
      }
    } catch (e) {
      debugPrint('Error populating opponent for away game: $e');
    }
  }

  void _handleContinue() {
    if (!_isAwayGame) {
      if (_officialsRequired == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select number of officials')),
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
      'levelOfCompetition': _isAwayGame ? null : args['levelOfCompetition'],
      'gender': _isAwayGame ? null : args['gender'],
      'officialsRequired': _isAwayGame ? 0 : _officialsRequired,
      'gameFee': _isAwayGame ? '0' : _gameFeeController.text.trim(),
      'opponent': _opponentController.text.trim(),
      'hireAutomatically': _isAwayGame ? false : _hireAutomatically,
      'isAway': _isAwayGame,
      'officialsHired': args['officialsHired'] ?? 0,
      'selectedOfficials':
          args['selectedOfficials'] ?? <Map<String, dynamic>>[],
      'template': template,
      'fromScheduleDetails': args['fromScheduleDetails'] ?? false,
      'scheduleId': args['scheduleId'],
      'scheduleName': args['scheduleName'],
    };

    if (_isFromEdit) {
      // When in edit mode, we need to navigate back to the edit screen
      // Pop back to the edit screen and then navigate to review
      Navigator.pushReplacementNamed(
        context,
        '/review_game_info',
        arguments: {
          ...updatedArgs,
          'isEdit': true,
          'isFromGameInfo': args['isFromGameInfo'] ?? false
        },
      );
    } else {
      Navigator.pushNamed(
        context,
        _isAwayGame ? '/review_game_info' : '/select_officials',
        arguments: updatedArgs,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Additional Game Info', style: appBarTextStyle),
        elevation: 0,
        centerTitle: true,
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
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      decoration:
                          textFieldDecoration('Required number of officials'),
                      style: textFieldTextStyle,
                      dropdownColor: darkSurface,
                      iconEnabledColor: efficialsYellow,
                      value: _officialsRequired,
                      hint: const Text('Required number of officials', style: TextStyle(color: efficialsGray)),
                      onChanged: (value) =>
                          setState(() => _officialsRequired = value),
                      items: _officialsOptions
                          .map((num) => DropdownMenuItem(
                              value: num, child: Text(num.toString(), style: textFieldTextStyle)))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _gameFeeController,
                      style: textFieldTextStyle,
                      decoration:
                          textFieldDecoration('Game Fee per Official').copyWith(
                        prefixText: '\$',
                        prefixStyle: const TextStyle(color: primaryTextColor, fontSize: 16),
                        hintText: 'Enter fee (e.g., 50 or 50.00)',
                      ),
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
                    enabled: !_isAwayGame,  // Disable for away games
                    style: TextStyle(
                        color: _isAwayGame ? Colors.grey : Colors.white,
                        fontSize: 16),
                    decoration: textFieldDecoration(_isAwayGame ? 'Opponent (Auto-filled)' : 'Opponent').copyWith(
                      hintText: _isAwayGame 
                          ? 'Will be auto-filled with your school name'
                          : 'Enter the visiting team name (e.g., "Collinsville Kahoks")',
                      hintStyle: const TextStyle(color: efficialsGray),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAwayGame
                        ? 'For away games, this will automatically be set to your school name'
                        : 'Enter the visiting team name and mascot that is coming to play you',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
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
                          fillColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return efficialsYellow;
                              }
                              return darkSurface;
                            },
                          ),
                        ),
                        const Text('Hire Automatically', style: TextStyle(color: primaryTextColor)),
                        IconButton(
                          icon: const Icon(Icons.help_outline,
                              color: efficialsYellow),
                          onPressed: _showHireInfoDialog,
                        ),
                      ],
                    ),
                  const SizedBox(height: 60),
                  Center(
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: elevatedButtonStyle(),
                      child:
                          const Text('Continue', style: signInButtonTextStyle),
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
