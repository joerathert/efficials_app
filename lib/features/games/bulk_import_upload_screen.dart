import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:flutter/painting.dart' as painting;
import 'dart:io';
import '../../shared/theme.dart';
import '../../shared/services/game_service.dart';
import '../../shared/services/location_service.dart';

class BulkImportUploadScreen extends StatefulWidget {
  const BulkImportUploadScreen({super.key});

  @override
  State<BulkImportUploadScreen> createState() => _BulkImportUploadScreenState();
}

class _BulkImportUploadScreenState extends State<BulkImportUploadScreen> {
  bool isProcessing = false;
  String? selectedFilePath;
  List<Map<String, dynamic>> parsedGames = [];
  List<String> validationErrors = [];
  Map<String, dynamic> globalSettings = {};
  List<Map<String, dynamic>> scheduleConfigs = [];
  
  final GameService _gameService = GameService();
  final LocationService _locationService = LocationService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Allow more time for the widget tree to be fully built and file picker to initialize
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      // Add a longer delay and show loading indicator
      setState(() {
        isProcessing = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      setState(() {
        isProcessing = false;
      });

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null && file.path!.isNotEmpty) {
          setState(() {
            selectedFilePath = file.path;
            parsedGames.clear();
            validationErrors.clear();
          });
        } else {
          _showErrorDialog('Selected file path is not accessible. Please try selecting the file again.');
        }
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      
      debugPrint('Error picking file: $e');
      String errorMessage = 'Failed to select file';
      
      if (e.toString().contains('LateInitializationError')) {
        // Offer retry option
        _showRetryDialog();
        return;
      } else if (e.toString().contains('PlatformException')) {
        errorMessage = 'File access denied. Please check permissions and try again.';
      } else {
        errorMessage = 'Failed to select file: ${e.toString()}';
      }
      
      _showErrorDialog(errorMessage);
    }
  }

  Future<void> _parseExcelFile() async {
    if (selectedFilePath == null) return;

    setState(() {
      isProcessing = true;
      parsedGames.clear();
      validationErrors.clear();
    });

    try {
      final file = File(selectedFilePath!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // No need to parse global settings - everything is in the row data now

      // Parse each team sheet
      for (final sheetName in excel.tables.keys) {
        if (sheetName == 'Settings' || sheetName == 'Reference') continue;
        
        await _parseTeamSheet(excel, sheetName);
      }

      // Validate parsed games
      await _validateParsedGames();

      setState(() {
        isProcessing = false;
      });

      if (validationErrors.isEmpty) {
        _showImportPreview();
      } else {
        _showValidationErrors();
      }

    } catch (e) {
      debugPrint('Error parsing Excel file: $e');
      setState(() {
        isProcessing = false;
      });
      _showErrorDialog('Failed to parse Excel file: ${e.toString()}');
    }
  }

  Future<void> _parseGlobalSettings(Excel excel) async {
    final settingsSheet = excel.tables['Settings'];
    if (settingsSheet == null) return;

    final maxRows = settingsSheet.maxRows;
    for (int row = 0; row < maxRows; row++) {
      final keyCell = settingsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      final valueCell = settingsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      
      if (keyCell.value != null && valueCell.value != null) {
        final key = keyCell.value.toString();
        final value = valueCell.value.toString();
        
        // Map display names back to internal keys
        switch (key) {
          case 'Sport':
            globalSettings['sport'] = value;
            break;
          case 'Gender':
            globalSettings['gender'] = value;
            break;
          case 'Competition Level':
            globalSettings['levelOfCompetition'] = value;
            break;
          case 'Officials Required':
            globalSettings['officialsRequired'] = int.tryParse(value) ?? 0;
            break;
          case 'Game Fee':
            globalSettings['gameFee'] = value.replaceAll('\$', '');
            break;
          case 'Officials Method':
            globalSettings['method'] = _mapMethodFromDisplay(value);
            break;
          case 'Hire Automatically':
            globalSettings['hireAutomatically'] = value.toLowerCase() == 'yes';
            break;
        }
      }
    }
  }

  String _mapMethodFromDisplay(String displayValue) {
    switch (displayValue) {
      case 'Manual Selection': return 'standard';
      case 'Single List': return 'use_list';
      case 'Multiple Lists': return 'advanced';
      case 'Hire a Crew': return 'hire_crew';
      default: return 'standard';
    }
  }

  Future<void> _parseTeamSheet(Excel excel, String sheetName) async {
    final sheet = excel.tables[sheetName];
    if (sheet == null) return;

    // No need to parse schedule configuration - everything is in the table rows now
    Map<String, dynamic> scheduleConfig = {
      'sheetName': sheetName,
      'scheduleName': '', // Will be set from first game row
      'teamName': '',     // Will be set from first game row
      'homeLocation': null,
    };

    scheduleConfigs.add(scheduleConfig);

    // Find games table
    int headerRow = -1;
    List<String> headers = [];
    
    final headerMaxRows = sheet.maxRows;
    for (int row = 0; row < headerMaxRows; row++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      if (cell.value?.toString() == 'Date') {
        headerRow = row;
        // Get all headers
        final maxColumns = sheet.maxColumns;
        for (int col = 0; col < maxColumns; col++) {
          final headerCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          if (headerCell.value != null) {
            headers.add(headerCell.value.toString());
          }
        }
        break;
      }
    }

    if (headerRow == -1) {
      validationErrors.add('$sheetName: Could not find games table');
      return;
    }

    // Parse game rows
    final gameMaxRows = sheet.maxRows;
    for (int row = headerRow + 1; row < gameMaxRows; row++) {
      final dateCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      
      // Skip empty rows - check if date cell is truly empty or contains sample/placeholder data
      final dateValue = dateCell.value?.toString().trim() ?? '';
      if (dateValue.isEmpty) {
        continue;
      }
      
      // Skip instruction/example rows that might contain non-date text
      if (dateValue.startsWith('👆') || dateValue.startsWith('📋') || dateValue.startsWith('🔧') || 
          dateValue.contains('Fill out') || dateValue.contains('Reference sheet') || 
          dateValue.contains('above') || dateValue.contains('copy and paste')) {
        continue;
      }
      
      // Additional check: find the opponent column dynamically since column order may vary
      int opponentColIndex = -1;
      for (int i = 0; i < headers.length; i++) {
        if (headers[i] == 'Opponent') {
          opponentColIndex = i;
          break;
        }
      }
      
      // If we found opponent column, check if it has meaningful data
      if (opponentColIndex >= 0) {
        final opponentCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: opponentColIndex, rowIndex: row));
        final opponentValue = opponentCell.value?.toString().trim() ?? '';
        
        // If opponent is empty or contains sample data, skip this row
        if (opponentValue.isEmpty || 
            opponentValue.toLowerCase().contains('sample') || 
            opponentValue.toLowerCase().contains('example')) {
          continue;
        }
      } else {
        // If we can't find opponent column and only have date, it's probably not a real game
        continue;
      }

      Map<String, dynamic> gameData = {
        // Initialize with defaults - will be overridden by row data
        'isAway': false,
        'location': null,
        'sport': null, // Will be set from Sport column or need to be handled
      };

      // Parse row data
      final parseMaxColumns = sheet.maxColumns;
      for (int col = 0; col < headers.length && col < parseMaxColumns; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        if (cell.value == null) continue;
        
        final header = headers[col];
        final cellValue = cell.value;
        final value = cellValue?.toString().trim() ?? '';
        
        // Debug cell value for Date column
        if (header == 'Date') {
          debugPrint('Cell raw value: $cellValue (${cellValue?.runtimeType})');
        }
        
        switch (header) {
          case 'Date':
            debugPrint('=== DATE PARSING DEBUG ===');
            debugPrint('Raw date value from Excel: "$value"');
            debugPrint('Value type: ${value.runtimeType}');
            debugPrint('Value length: ${value.length}');
            final parsedDate = _parseDate(value);
            debugPrint('Parsed date result: $parsedDate');
            debugPrint('=== END DATE DEBUG ===');
            gameData['date'] = parsedDate;
            break;
          case 'Time':
            gameData['time'] = _parseTime(value);
            break;
          case 'Opponent':
            gameData['opponent'] = value;
            break;
          case 'Schedule Name':
            gameData['scheduleName'] = value;
            // Update schedule config from first game
            if (scheduleConfig['scheduleName'].toString().isEmpty) {
              scheduleConfig['scheduleName'] = value;
            }
            break;
          case 'Team Name':
            gameData['homeTeam'] = value;
            // Update schedule config from first game  
            if (scheduleConfig['teamName'].toString().isEmpty) {
              scheduleConfig['teamName'] = value;
            }
            break;
          case 'Away Game':
            final isAway = value.toLowerCase() == 'yes' || value.toLowerCase() == 'true' || value == '1';
            gameData['isAway'] = isAway;
            if (isAway) {
              gameData['location'] = 'Away Game';
            }
            break;
          case 'Gender':
            gameData['gender'] = value;
            break;
          case 'Competition Level':
            gameData['levelOfCompetition'] = value;
            break;
          case 'Officials Required':
            gameData['officialsRequired'] = int.tryParse(value) ?? 0;
            break;
          case 'Game Fee':
            gameData['gameFee'] = value.replaceAll('\$', '');
            break;
          case 'Officials Method':
            gameData['method'] = _mapMethodFromDisplay(value);
            break;
          case 'Hire Automatically':
            gameData['hireAutomatically'] = value.toLowerCase() == 'yes';
            break;
          case 'Location':
            if (value.isNotEmpty) {
              gameData['location'] = value;
            }
            break;
          case 'Officials List':
            gameData['officialsList'] = value;
            break;
          case 'Officials List 1':
            gameData['officialsList1'] = value;
            break;
          case 'Officials List 1 Min':
            gameData['officialsList1Min'] = int.tryParse(value) ?? 0;
            break;
          case 'Officials List 1 Max':
            gameData['officialsList1Max'] = int.tryParse(value) ?? 0;
            break;
          case 'Officials List 2':
            gameData['officialsList2'] = value;
            break;
          case 'Officials List 2 Min':
            gameData['officialsList2Min'] = int.tryParse(value) ?? 0;
            break;
          case 'Officials List 2 Max':
            gameData['officialsList2Max'] = int.tryParse(value) ?? 0;
            break;
          case 'Officials List 3':
            gameData['officialsList3'] = value;
            break;
          case 'Officials List 3 Min':
            gameData['officialsList3Min'] = int.tryParse(value) ?? 0;
            break;
          case 'Officials List 3 Max':
            gameData['officialsList3Max'] = int.tryParse(value) ?? 0;
            break;
          case 'Crew List':
            gameData['crewList'] = value;
            break;
          case 'Specific Crew Name':
            gameData['specificCrewName'] = value;
            break;
          case 'Sport':
            gameData['sport'] = value;
            break;
        }
      }

      // Set location for home games (if not already set by Away Game logic)
      if (gameData['isAway'] != true && gameData['location'] == null) {
        // For home games, we need to determine the location
        // This should be handled by the validation logic if missing
        gameData['location'] = null; // Will be validated later
      }

      // Ensure sport is set (critical for GameService.createGame)
      if (gameData['sport'] == null || gameData['sport'].toString().trim().isEmpty) {
        // Try to get sport from first game or use a default
        if (parsedGames.isNotEmpty && parsedGames.first['sport'] != null) {
          gameData['sport'] = parsedGames.first['sport'];
        } else {
          // This is a critical failure - we need sport to create games
          debugPrint('❌ Critical: No sport found for game row. Cannot create game without sport.');
        }
      }

      parsedGames.add(gameData);
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      // Handle various date formats
      final cleanDate = dateStr.trim();
      
      if (cleanDate.isEmpty) return null;
      
      // Check if it's a numeric value (Excel serial date)
      final numericValue = double.tryParse(cleanDate);
      if (numericValue != null) {
        // Excel serial date: days since January 1, 1900 (with adjustment for leap year bug)
        // Convert to DateTime
        final baseDate = DateTime(1900, 1, 1);
        final daysToAdd = numericValue.round() - 2; // -2 to account for Excel's leap year bug
        final resultDate = baseDate.add(Duration(days: daysToAdd));
        
        debugPrint('Parsed Excel serial date $numericValue to $resultDate');
        return resultDate;
      }
      
      // Try MM/dd/yyyy format (most common Excel format)
      if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(cleanDate)) {
        final parts = cleanDate.split('/');
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        
        // Validate date components
        if (month < 1 || month > 12 || day < 1 || day > 31 || year < 2020 || year > 2030) {
          debugPrint('Invalid date components: month=$month, day=$day, year=$year');
          return null;
        }
        
        return DateTime(year, month, day);
      }
      
      // Try MM-dd-yyyy format
      if (RegExp(r'^\d{1,2}-\d{1,2}-\d{4}$').hasMatch(cleanDate)) {
        final parts = cleanDate.split('-');
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        
        if (month < 1 || month > 12 || day < 1 || day > 31 || year < 2020 || year > 2030) {
          return null;
        }
        
        return DateTime(year, month, day);
      }
      
      // Try yyyy-MM-dd format (ISO format)
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(cleanDate)) {
        return DateTime.parse(cleanDate);
      }
      
      // Try ISO 8601 format with timezone (from Excel DateCellValue)
      if (RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$').hasMatch(cleanDate)) {
        debugPrint('Parsing ISO 8601 date: $cleanDate');
        final parsed = DateTime.parse(cleanDate);
        debugPrint('Successfully parsed ISO date: $parsed');
        return parsed;
      }
      
      // Try dd/MM/yyyy format (alternate format)
      if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(cleanDate)) {
        final parts = cleanDate.split('/');
        // Assume this is dd/MM/yyyy if day > 12
        final firstNum = int.parse(parts[0]);
        final secondNum = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        
        if (firstNum > 12) {
          // This must be dd/MM/yyyy
          final day = firstNum;
          final month = secondNum;
          if (month < 1 || month > 12 || day < 1 || day > 31) return null;
          return DateTime(year, month, day);
        }
      }
      
      debugPrint('Unrecognized date format: "$dateStr"');
      return null;
    } catch (e) {
      debugPrint('Error parsing date "$dateStr": $e');
      return null;
    }
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final cleanTime = timeStr.trim();
      
      if (cleanTime.isEmpty) return null;
      
      // Handle various time formats
      final lowerTime = cleanTime.toLowerCase();
      
      // Handle "7:00 PM" or "7:00 AM" format
      final match12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(am|pm)$').firstMatch(lowerTime);
      if (match12 != null) {
        int hour = int.parse(match12.group(1)!);
        final minute = int.parse(match12.group(2)!);
        final period = match12.group(3)!;
        
        // Validate hour and minute
        if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
          debugPrint('Invalid 12-hour time components: hour=$hour, minute=$minute');
          return null;
        }
        
        // Convert to 24-hour format
        if (period == 'pm' && hour != 12) {
          hour += 12;
        } else if (period == 'am' && hour == 12) {
          hour = 0;
        }
        
        return TimeOfDay(hour: hour, minute: minute);
      }
      
      // Handle "19:00" (24-hour) format
      final match24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(cleanTime);
      if (match24 != null) {
        final hour = int.parse(match24.group(1)!);
        final minute = int.parse(match24.group(2)!);
        
        // Validate 24-hour format
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
          debugPrint('Invalid 24-hour time components: hour=$hour, minute=$minute');
          return null;
        }
        
        return TimeOfDay(hour: hour, minute: minute);
      }
      
      // Handle "7 PM" or "7AM" format (no colon)
      final matchNoColon = RegExp(r'^(\d{1,2})\s*(am|pm)$').firstMatch(lowerTime);
      if (matchNoColon != null) {
        int hour = int.parse(matchNoColon.group(1)!);
        final period = matchNoColon.group(2)!;
        
        if (hour < 1 || hour > 12) {
          return null;
        }
        
        if (period == 'pm' && hour != 12) {
          hour += 12;
        } else if (period == 'am' && hour == 12) {
          hour = 0;
        }
        
        return TimeOfDay(hour: hour, minute: 0);
      }
      
      debugPrint('Unrecognized time format: "$timeStr"');
      return null;
    } catch (e) {
      debugPrint('Error parsing time "$timeStr": $e');
      return null;
    }
  }

  Future<void> _validateParsedGames() async {
    final locations = await _locationService.getLocations();
    final locationNames = locations.map((loc) => loc['name'] as String).toList();
    
    debugPrint('=== VALIDATION DEBUG ===');
    debugPrint('Available locations: $locationNames');
    debugPrint('Total games to validate: ${parsedGames.length}');
    
    int gameRowCounter = 0; // Track actual game rows for better error reporting

    for (int i = 0; i < parsedGames.length; i++) {
      final game = parsedGames[i];
      gameRowCounter++;
      final rowNum = gameRowCounter; // Use sequential counter instead of array index

      debugPrint('--- Game $rowNum Debug ---');
      debugPrint('Date: ${game['date']} (${game['date'].runtimeType})');
      debugPrint('Time: ${game['time']} (${game['time'].runtimeType})');
      debugPrint('Opponent: ${game['opponent']}');
      debugPrint('Location: ${game['location']}');
      debugPrint('IsAway: ${game['isAway']}');
      debugPrint('OfficialsRequired: ${game['officialsRequired']}');
      debugPrint('GameFee: ${game['gameFee']}');

      // Validate required fields
      if (game['date'] == null) {
        debugPrint('❌ Date validation failed');
        validationErrors.add('Row $rowNum: Invalid or missing date');
      }
      if (game['time'] == null) {
        debugPrint('❌ Time validation failed');
        validationErrors.add('Row $rowNum: Invalid or missing time');
      }
      if (game['opponent'] == null || game['opponent'].toString().trim().isEmpty) {
        debugPrint('❌ Opponent validation failed');
        validationErrors.add('Row $rowNum: Missing opponent');
      }

      // Validate location (if not away game)
      if (game['isAway'] != true) {
        final location = game['location']?.toString();
        if (location == null || location.trim().isEmpty) {
          debugPrint('❌ Location validation failed: null/empty');
          validationErrors.add('Row $rowNum: Invalid Location "null"');
        } else if (location != 'Away Game' && !locationNames.contains(location)) {
          debugPrint('❌ Location validation failed: "$location" not in valid locations');
          validationErrors.add('Row $rowNum: Invalid location "$location"');
        } else {
          debugPrint('✅ Location validation passed: "$location"');
        }
      } else {
        debugPrint('✅ Away game - location validation skipped');
      }

      // Validate officials required
      final officialsRequired = game['officialsRequired'] as int? ?? 0;
      if (officialsRequired < 1 || officialsRequired > 9) {
        debugPrint('❌ Officials validation failed: $officialsRequired');
        validationErrors.add('Row $rowNum: Officials required must be between 1-9');
      }

      // Validate game fee
      final gameFee = game['gameFee']?.toString();
      if (gameFee != null && gameFee.isNotEmpty && double.tryParse(gameFee) == null) {
        debugPrint('❌ Game fee validation failed: "$gameFee"');
        validationErrors.add('Row $rowNum: Invalid game fee "$gameFee"');
      }
      
      debugPrint('--- End Game $rowNum Debug ---');
    }
    
    debugPrint('=== END VALIDATION DEBUG ===');
    debugPrint('Total validation errors: ${validationErrors.length}');
  }

  Future<void> _importGames() async {
    setState(() {
      isProcessing = true;
    });

    try {
      int successCount = 0;
      int errorCount = 0;

      debugPrint('=== GAME IMPORT DEBUG ===');
      debugPrint('Total games to import: ${parsedGames.length}');

      for (int i = 0; i < parsedGames.length; i++) {
        final gameData = parsedGames[i];
        debugPrint('--- Importing Game ${i + 1} ---');
        debugPrint('Game data: $gameData');
        
        try {
          final result = await _gameService.createGame(gameData);
          debugPrint('GameService.createGame result: $result');
          debugPrint('Result type: ${result.runtimeType}');
          
          if (result != null) {
            debugPrint('✅ Game ${i + 1} created successfully');
            successCount++;
          } else {
            debugPrint('❌ Game ${i + 1} failed - createGame returned null');
            errorCount++;
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Game ${i + 1} failed with exception: $e');
          debugPrint('Stack trace: $stackTrace');
          errorCount++;
        }
        
        debugPrint('--- End Game ${i + 1} Import ---');
      }

      debugPrint('=== END GAME IMPORT DEBUG ===');
      debugPrint('Final results - Success: $successCount, Errors: $errorCount');

      setState(() {
        isProcessing = false;
      });

      _showImportResults(successCount, errorCount);

    } catch (e, stackTrace) {
      debugPrint('❌ Import process failed completely: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        isProcessing = false;
      });
      _showErrorDialog('Import failed: ${e.toString()}');
    }
  }

  void _showImportPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Import Preview',
          style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Found ${parsedGames.length} games across ${scheduleConfigs.length} schedules.',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Schedules:',
                style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.w500),
              ),
              ...scheduleConfigs.map((config) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '• ${config['scheduleName']} (${config['teamName']})',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _importGames();
            },
            child: const Text('Import Games', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _showValidationErrors() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Validation Errors',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please fix the following errors in your Excel file:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ...validationErrors.map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• $error',
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _showImportResults(int successCount, int errorCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: Text(
          'Import Complete',
          style: TextStyle(
            color: errorCount == 0 ? Colors.green : efficialsYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Successfully imported: $successCount games',
              style: const TextStyle(color: Colors.green),
            ),
            if (errorCount > 0)
              Text(
                'Failed to import: $errorCount games',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/assigner_home',
                (route) => false,
              );
            },
            child: const Text('Done', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'File Picker Not Ready',
          style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'The file picker is still initializing. Would you like to try again?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Wait a bit longer and try again
              await Future.delayed(const Duration(milliseconds: 1000));
              _pickFile();
            },
            child: const Text('Try Again', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Upload Excel File',
          style: TextStyle(color: efficialsYellow, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Import Games',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload your completed Excel file to create games in bulk.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),

            // File selection
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: painting.Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    selectedFilePath != null ? Icons.check_circle : Icons.cloud_upload,
                    color: selectedFilePath != null ? Colors.green : efficialsYellow,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedFilePath != null
                        ? 'File Selected'
                        : 'Select Excel File',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: selectedFilePath != null ? Colors.green : Colors.white,
                    ),
                  ),
                  if (selectedFilePath != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      selectedFilePath!.split('/').last,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isInitialized ? _pickFile : null,
                    style: elevatedButtonStyle(),
                    child: Text(
                      _isInitialized 
                          ? (selectedFilePath != null ? 'Change File' : 'Browse Files')
                          : 'Initializing...',
                      style: signInButtonTextStyle.copyWith(
                        color: _isInitialized ? efficialsBlack : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Processing status
            if (isProcessing) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: efficialsYellow),
                    SizedBox(height: 16),
                    Text(
                      'Processing Excel file...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],

            // Results summary
            if (parsedGames.isNotEmpty && !isProcessing) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: painting.Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Parsing Complete',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Found ${parsedGames.length} games across ${scheduleConfigs.length} schedules.',
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (validationErrors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${validationErrors.length} validation errors found.',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: selectedFilePath != null && !isProcessing
          ? Container(
              color: efficialsBlack,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: ElevatedButton(
                onPressed: parsedGames.isEmpty ? _parseExcelFile : 
                          validationErrors.isNotEmpty ? null : _importGames,
                style: elevatedButtonStyle(),
                child: Text(
                  parsedGames.isEmpty 
                      ? 'Parse Excel File'
                      : validationErrors.isNotEmpty
                          ? 'Fix Errors First'
                          : 'Import Games',
                  style: signInButtonTextStyle.copyWith(
                    color: validationErrors.isNotEmpty ? Colors.grey : efficialsBlack,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}