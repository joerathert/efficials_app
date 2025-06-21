import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'game_template.dart'; // Import the GameTemplate model

class AdditionalGameInfoCondensedScreen extends StatefulWidget {
  final Map<String, dynamic>? args;

  const AdditionalGameInfoCondensedScreen({Key? key, this.args}) : super(key: key);

  @override
  _AdditionalGameInfoCondensedScreenState createState() => _AdditionalGameInfoCondensedScreenState();
}

class _AdditionalGameInfoCondensedScreenState extends State<AdditionalGameInfoCondensedScreen> {
  int? _officialsRequired;
  final TextEditingController _gameFeeController = TextEditingController();
  final TextEditingController _opponentController = TextEditingController();
  bool _hireAutomatically = false;
  bool _isFromEdit = false;
  bool _isInitialized = false;
  bool _isAwayGame = false;
  GameTemplate? template; // Store the selected template

  final List<int> _officialsOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  void _showHireInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hire Automatically'),
        content: const Text(
            'When checked, the system will automatically assign officials based on your preferences and availability. Uncheck to manually select officials.'),
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
        _isFromEdit = args['isEdit'] == true;
        _isAwayGame = args['isAwayGame'] == true;
        template = args['template'] as GameTemplate?; // Extract the template

        // Pre-fill fields from the template if available, otherwise use args or Coach data
        if (template != null) {
          _officialsRequired = template!.includeOfficialsRequired && template!.officialsRequired != null
              ? template!.officialsRequired
              : (args['officialsRequired'] != null ? int.tryParse(args['officialsRequired'].toString()) : null);
          _gameFeeController.text = template!.includeGameFee && template!.gameFee != null
              ? template!.gameFee!
              : (args['gameFee']?.toString() ?? '');
          _hireAutomatically = template!.includeHireAutomatically && template!.hireAutomatically != null
              ? template!.hireAutomatically!
              : (args['hireAutomatically'] as bool? ?? false);
        } else {
          _officialsRequired = args['officialsRequired'] != null
              ? int.tryParse(args['officialsRequired'].toString())
              : null;
          _gameFeeController.text = args['gameFee']?.toString() ?? '';
          _hireAutomatically = args['hireAutomatically'] as bool? ?? false;
        }
        _opponentController.text = args['opponent'] as String? ?? '';
      }
      _isInitialized = true;
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
          const SnackBar(content: Text('Please enter a valid game fee (e.g., 50 or 50.00)')),
        );
        return;
      }
      final fee = double.parse(feeText);
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
      'levelOfCompetition': args['grade'], // Pre-filled from SelectTeamScreen
      'gender': args['gender'], // Pre-filled from SelectTeamScreen
      'officialsRequired': _isAwayGame ? 0 : _officialsRequired,
      'gameFee': _isAwayGame ? '0' : _gameFeeController.text.trim(),
      'opponent': _opponentController.text.trim(),
      'hireAutomatically': _isAwayGame ? false : _hireAutomatically,
      'isAway': _isAwayGame,
      'officialsHired': args['officialsHired'] ?? 0,
      'selectedOfficials': args['selectedOfficials'] ?? <Map<String, dynamic>>[],
      'template': template,
    };

    print('AdditionalGameInfoCondensedScreen _handleContinue - Navigating to: ${_isAwayGame ? '/review_game_info' : '/select_officials'}');
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
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      decoration: textFieldDecoration('Required number of officials'),
                      value: _officialsRequired,
                      hint: const Text('Required number of officials'),
                      onChanged: (value) => setState(() => _officialsRequired = value),
                      items: _officialsOptions
                          .map((num) => DropdownMenuItem(value: num, child: Text(num.toString())))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _gameFeeController,
                      decoration: textFieldDecoration('Game Fee per Official').copyWith(
                        prefixText: '\$',
                        hintText: 'Enter fee (e.g., 50 or 50.00)',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        LengthLimitingTextInputFormatter(7), // Allow for "99999.99"
                      ],
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