import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';
import 'game_template.dart'; // Import the GameTemplate model

class DateTimeScreen extends StatefulWidget {
  const DateTimeScreen({super.key});

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? sport;
  bool _isFromEdit = false;
  bool _isInitialized = false;
  GameTemplate? template; // Store the selected template

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _selectedDate = args['date'] as DateTime?;
        _selectedTime = args['time'] as TimeOfDay?;
        _isFromEdit = args['isEdit'] == true;
        sport = args['sport'] as String?;

        // Convert args['template'] from Map to GameTemplate if necessary
        template = args['template'] != null
            ? (args['template'] is GameTemplate
                ? args['template'] as GameTemplate?
                : GameTemplate.fromJson(
                    args['template'] as Map<String, dynamic>))
            : null;

        // If a template is provided and includes a time, pre-fill the time
        if (template != null &&
            template!.includeTime &&
            template!.time != null) {
          _selectedTime = template!.time;
        }
        print(
            'didChangeDependencies - Initial Args: $args, Date: $_selectedDate, Time: $_selectedTime, Edit: $_isFromEdit, Sport: $sport, Template: $template');
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
            primaryColor: efficialsBlue,
            colorScheme: ColorScheme.light(
              primary: efficialsBlue,
              onPrimary: Colors.white,
              surface: Colors.grey[200]!,
              onSurface: Colors.black,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        print('Date selected: $_selectedDate');
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
            primaryColor: efficialsBlue,
            colorScheme: ColorScheme.light(
              primary: efficialsBlue,
              onPrimary: Colors.white,
              surface: Colors.grey[200]!,
              onSurface: Colors.black,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        print('Time selected: $_selectedTime');
      });
    }
  }

  String _formatDateTime() {
    if (_selectedDate == null && _selectedTime == null)
      return 'Date and time not set';
    if (_selectedDate == null) return 'Date not set';
    if (_selectedTime == null)
      return DateFormat('EEEE, MMMM d, y').format(_selectedDate!);
    return '${DateFormat('EEEE, MMMM d, y').format(_selectedDate!)} at ${_selectedTime!.format(context)}';
  }

  @override
  Widget build(BuildContext context) {
    print(
        'build - Date: $_selectedDate, Time: $_selectedTime, Sport: $sport, Template: $template');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
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
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'When will the game be played?',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
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
                  Text(
                    _formatDateTime(),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 60),
                  Center(
                    child: ElevatedButton(
                      onPressed:
                          (_selectedDate != null && _selectedTime != null)
                              ? () {
                                  final args = ModalRoute.of(context)!
                                      .settings
                                      .arguments as Map<String, dynamic>;
                                  final nextArgs = {
                                    ...args,
                                    'date': _selectedDate,
                                    'time': _selectedTime,
                                    'sport': sport,
                                    'template': template,
                                    'fromScheduleDetails':
                                        args['fromScheduleDetails'] ??
                                            false, // Add flag
                                    'scheduleId':
                                        args['scheduleId'], // Add scheduleId
                                  };
                                  print(
                                      'Continue - Args: $nextArgs, Edit: $_isFromEdit');
                                  Navigator.pushNamed(
                                    context,
                                    _isFromEdit
                                        ? '/review_game_info'
                                        : '/choose_location',
                                    arguments: nextArgs,
                                  );
                                }
                              : null,
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
}
