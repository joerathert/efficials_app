import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';
import 'game_template.dart'; // Import the GameTemplate model

class DateTimeScreen extends StatefulWidget {
  const DateTimeScreen({super.key});

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen>
    with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? sport;
  String? scheduleName;
  bool _isFromEdit = false;
  bool _isFromGameInfo = false;
  bool _isInitialized = false;
  GameTemplate? template; // Store the selected template
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
        _isFromGameInfo = args['isFromGameInfo'] == true;
        sport = args['sport'] as String?;
        scheduleName = args['scheduleName'] as String?;

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
            'didChangeDependencies - Initial Args: $args, Date: $_selectedDate, Time: $_selectedTime, Edit: $_isFromEdit, Sport: $sport, Template: $template, ScheduleName: $scheduleName');
      }
      _isInitialized = true;
      if (_selectedDate != null || _selectedTime != null) {
        _animationController.forward();
      }
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
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        if (_selectedTime == null) {
          _animationController.forward();
        }
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
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        if (_selectedDate == null) {
          _animationController.forward();
        }
        print('Time selected: $_selectedTime');
      });
    }
  }

  String _formatDateTime() {
    if (_selectedDate == null && _selectedTime == null) {
      return 'Select date and time';
    }
    if (_selectedDate == null) return 'Date not set';
    if (_selectedTime == null) {
      return DateFormat('EEEE, MMMM d, y').format(_selectedDate!);
    }
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
        title: const Text('Game Schedule', style: appBarTextStyle),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'When will the game be played?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: efficialsBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _animation,
                          child: Text(
                            _formatDateTime(),
                            style: TextStyle(
                              fontSize: 20,
                              color:
                                  _selectedDate != null && _selectedTime != null
                                      ? Colors.black87
                                      : Colors.grey[600],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSelectionButton(
                                icon: Icons.calendar_today,
                                label: _selectedDate != null
                                    ? 'Change Date'
                                    : 'Set Date',
                                isSelected: _selectedDate != null,
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSelectionButton(
                                icon: Icons.access_time,
                                label: _selectedTime != null
                                    ? 'Change Time'
                                    : 'Set Time',
                                isSelected: _selectedTime != null,
                                onPressed: () => _selectTime(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed:
                          (_selectedDate != null && _selectedTime != null)
                              ? () {
                                  final args = ModalRoute.of(context)!
                                      .settings
                                      .arguments as Map<String, dynamic>?;
                                  final updatedArgs = {
                                    ...?args,
                                    'date': _selectedDate,
                                    'time': _selectedTime,
                                    'template': template,
                                    'scheduleName': scheduleName,
                                  };
                                  print('Continue - Args: $updatedArgs');

                                  if (_isFromEdit) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/review_game_info',
                                      arguments: {
                                        ...updatedArgs,
                                        'isEdit': true,
                                        'isFromGameInfo': _isFromGameInfo,
                                      },
                                    );
                                  } else {
                                    Navigator.pushNamed(
                                      context,
                                      '/choose_location',
                                      arguments: updatedArgs,
                                    );
                                  }
                                }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: efficialsBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color:
                              (_selectedDate != null && _selectedTime != null)
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? efficialsBlue : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? efficialsBlue.withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? efficialsBlue : Colors.grey[600],
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? efficialsBlue : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
