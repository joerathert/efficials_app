import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme.dart';
import 'game_template.dart';
import '../../shared/services/repositories/template_repository.dart';
import '../../shared/services/repositories/user_repository.dart';

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
  GameTemplate? template;
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  final TemplateRepository _templateRepository = TemplateRepository();
  final UserRepository _userRepository = UserRepository();

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

        // If no template provided but scheduleName exists, try to load from DB
        if (template == null && scheduleName != null) {
          _loadTemplateFromDatabase();
        }

        // If a template is provided and includes date/time, pre-fill them
        if (template != null) {
          if (template!.includeDate && template!.date != null) {
            final templateDate = template!.date!;
            if (templateDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
              _selectedDate = templateDate;
            }
          }
          if (template!.includeTime && template!.time != null) {
            _selectedTime = template!.time;
          }
        }
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
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            primaryColor: efficialsYellow,
            colorScheme: const ColorScheme.dark(
              primary: efficialsYellow,
              onPrimary: efficialsBlack,
              surface: darkSurface,
              onSurface: primaryTextColor,
              secondary: efficialsYellow,
              onSecondary: efficialsBlack,
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: darkSurface,
              headerBackgroundColor: efficialsYellow,
              headerForegroundColor: efficialsBlack,
              weekdayStyle: TextStyle(color: primaryTextColor),
              dayStyle: TextStyle(color: primaryTextColor),
              yearStyle: TextStyle(color: primaryTextColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      if (picked.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        _showValidationError('Please select a future date');
        return;
      }
      setState(() {
        _selectedDate = picked;
        if (_selectedTime == null) {
          _animationController.forward();
        }
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
            primaryColor: efficialsYellow,
            colorScheme: const ColorScheme.dark(
              primary: efficialsYellow,
              onPrimary: efficialsBlack,
              surface: darkSurface,
              onSurface: primaryTextColor,
              secondary: efficialsYellow,
              onSecondary: efficialsBlack,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: darkSurface,
              hourMinuteColor: darkBackground,
              hourMinuteTextColor: primaryTextColor,
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return efficialsYellow;
                }
                return darkBackground;
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return efficialsBlack;
                }
                return Colors.white;
              }),
              dialBackgroundColor: darkBackground,
              dialHandColor: efficialsYellow,
              dialTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return efficialsBlack;
                }
                return primaryTextColor;
              }),
              entryModeIconColor: efficialsYellow,
              helpTextStyle: const TextStyle(color: primaryTextColor),
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
      });
    }
  }

  Future<void> _loadTemplateFromDatabase() async {
    try {
      final user = await _userRepository.getCurrentUser();
      if (user != null && scheduleName != null) {
        final templateData = await _templateRepository.getTemplateData(user.id!, scheduleName!);
        if (templateData != null) {
          setState(() {
            template = GameTemplate.fromJson(templateData);
            
            if (template!.includeDate && template!.date != null) {
              final templateDate = template!.date!;
              if (templateDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
                _selectedDate = templateDate;
              }
            }
            if (template!.includeTime && template!.time != null) {
              _selectedTime = template!.time;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading template from database: $e');
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isValidDateTime() {
    if (_selectedDate == null || _selectedTime == null) return false;
    
    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    
    return selectedDateTime.isAfter(DateTime.now());
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

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Game Schedule', style: appBarTextStyle),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: darkBackground,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                  const SizedBox(height: 20),
                  const Text(
                    'When will the game be played?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: efficialsYellow,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: darkSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  _selectedDate != null && _selectedTime != null
                                      ? primaryTextColor
                                      : secondaryTextColor,
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
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: (_selectedDate != null && _selectedTime != null)
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
                                'isAssignerFlow': args?['isAssignerFlow'] ?? false, // Explicitly preserve isAssignerFlow flag
                              };

                              if (_isFromEdit) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/review_game_info',
                                  arguments: {
                                    ...updatedArgs,
                                    'isEdit': true,
                                    'isFromGameInfo': _isFromGameInfo,
                                    'isAssignerFlow': args?['isAssignerFlow'] ?? false, // Preserve isAssignerFlow in edit mode too
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
                        backgroundColor: (_selectedDate != null && _selectedTime != null)
                            ? efficialsYellow
                            : Colors.grey.shade600,
                        foregroundColor: (_selectedDate != null && _selectedTime != null)
                            ? efficialsBlack
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50), // Add extra space at bottom
                ],
                ),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? efficialsYellow : secondaryTextColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? efficialsYellow : secondaryTextColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? efficialsYellow : secondaryTextColor,
                  fontSize: 14,
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
