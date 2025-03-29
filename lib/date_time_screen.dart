import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';

class DateTimeScreen extends StatefulWidget {
  const DateTimeScreen({super.key});

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isFromEdit = false;
  Map<String, dynamic> _args = {};
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _args = args;
        _selectedDate = args['date'] as DateTime?;
        _selectedTime = args['time'] as TimeOfDay?;
        _isFromEdit = args['isEdit'] == true;
      }
      _isInitialized = true;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: efficialsBlue,
              onPrimary: Colors.white,
              surface: Colors.grey[200]!,
              onSurface: Colors.black,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black),
              headlineSmall: TextStyle(color: Colors.black),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: efficialsBlue,
              onPrimary: Colors.white,
              surface: Colors.grey[200]!,
              onSurface: Colors.black,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black),
              headlineSmall: TextStyle(color: Colors.black),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDateTime() {
    if (_selectedDate == null) return '';
    final date = DateFormat('EEEE, MMMM d, y').format(_selectedDate!);
    return _selectedTime != null ? '$date at ${_selectedTime!.format(context)}' : date;
  }

  @override
  Widget build(BuildContext context) {
    final isContinueEnabled = _selectedDate != null && _selectedTime != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Date/Time', style: appBarTextStyle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'When will the game be played?',
                    style: headlineStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        style: elevatedButtonStyle(),
                        child: Text(
                          _selectedDate != null ? 'Change Date' : 'Set Date',
                          style: signInButtonTextStyle,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _selectTime(context),
                        style: elevatedButtonStyle(),
                        child: Text(
                          _selectedTime != null ? 'Change Time' : 'Set Time',
                          style: signInButtonTextStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_selectedDate != null || _selectedTime != null)
                    Text(
                      _formatDateTime(),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  const SizedBox(height: 60),
                  Center(
                    child: ElevatedButton(
                      onPressed: isContinueEnabled
                          ? () {
                              if (_isFromEdit) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/review_game_info',
                                  arguments: {
                                    ..._args,
                                    'date': _selectedDate,
                                    'time': _selectedTime,
                                  },
                                );
                              } else {
                                Navigator.pushNamed(
                                  context,
                                  '/choose_location',
                                  arguments: {
                                    ..._args,
                                    'date': _selectedDate,
                                    'time': _selectedTime,
                                  },
                                );
                              }
                            }
                          : null,
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
}