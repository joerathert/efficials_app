import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:flutter/painting.dart' as painting;
import 'dart:convert';
import 'dart:io';
import '../../shared/theme.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/schedule_service.dart';

class BulkImportGenerateScreen extends StatefulWidget {
  const BulkImportGenerateScreen({super.key});

  @override
  State<BulkImportGenerateScreen> createState() =>
      _BulkImportGenerateScreenState();
}

class _BulkImportGenerateScreenState extends State<BulkImportGenerateScreen> {
  bool isGenerating = false;
  String? generatedFilePath;
  Map<String, dynamic>? wizardConfig;

  // Team configuration
  List<Map<String, dynamic>> teamConfigs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (wizardConfig == null) {
      wizardConfig =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _initializeTeamConfigs();
    }
  }

  void _initializeTeamConfigs() {
    final numberOfTeams = wizardConfig!['numberOfTeams'] as int;
    final globalSettings = wizardConfig!['globalSettings'] as Map<String, bool>;
    final globalValues = wizardConfig!['globalValues'] as Map<String, dynamic>;
    final scheduleSettings =
        wizardConfig!['scheduleSettings'] as Map<String, bool>;

    teamConfigs = List.generate(numberOfTeams, (index) {
      Map<String, dynamic> config = {
        'scheduleName': '',
        'numberOfGames': 10, // Default to 10 games per schedule
      };

      // Add fields for schedule-level settings
      scheduleSettings.forEach((key, isSet) {
        if (isSet) {
          switch (key) {
            case 'teamName':
              config['teamName'] = '';
              break;
            case 'location':
              config['homeLocation'] = null;
              break;
            case 'gender':
              config['gender'] = null;
              break;
            case 'competitionLevel':
              config['competitionLevel'] = null;
              break;
            case 'officialsRequired':
              config['officialsRequired'] = null;
              break;
            case 'gameFee':
              config['gameFee'] = '';
              break;
            case 'method':
              config['method'] = null;
              break;
            case 'hireAutomatically':
              config['hireAutomatically'] = null;
              break;
            case 'time':
              config['time'] = '';
              break;
          }
        }
      });

      // Always add Team Name if not set globally, and populate with global value if available
      if (!(globalSettings['teamName'] ?? false)) {
        config['teamName'] = '';
      } else {
        // If team name is set globally, use the global value
        config['teamName'] = globalValues['teamName'] ?? '';
      }

      // Handle global Multiple Lists configuration
      if ((globalSettings['method'] ?? false) && globalValues['method'] == 'Multiple Lists') {
        final selectedMultipleLists = wizardConfig!['selectedMultipleLists'] as List<Map<String, dynamic>>? ?? [];
        if (selectedMultipleLists.isNotEmpty) {
          config['multipleLists'] = List<Map<String, dynamic>>.from(selectedMultipleLists);
        }
      }

      // Handle global Single List configuration  
      if ((globalSettings['method'] ?? false) && globalValues['method'] == 'Single List') {
        final selectedList = wizardConfig!['selectedList'] as String?;
        if (selectedList != null) {
          config['singleList'] = selectedList;
        }
      }

      // Handle global Hire a Crew configuration
      if ((globalSettings['method'] ?? false) && globalValues['method'] == 'Hire a Crew') {
        final selectedCrew = wizardConfig!['selectedCrew'] as String?;
        if (selectedCrew != null) {
          config['crewList'] = selectedCrew;
        }
      }

      return config;
    });
  }

  Future<void> _generateExcelFile() async {
    if (!_validateTeamConfigs()) return;

    setState(() {
      isGenerating = true;
    });

    try {
      final excel = Excel.createExcel();

      // Create Settings sheet
      await _createSettingsSheet(excel);

      // Create team sheets
      for (int i = 0; i < teamConfigs.length; i++) {
        await _createTeamSheet(excel, i);
      }

      // Create reference sheet with valid options
      await _createReferenceSheet(excel);

      // Remove default sheet AFTER creating all other sheets
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'BulkGameImport_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${directory.path}/$fileName');

      final bytes = excel.encode();
      await file.writeAsBytes(bytes!);

      setState(() {
        generatedFilePath = file.path;
        isGenerating = false;
      });

      // Show file location dialog immediately for development convenience
      _showFileLocationDialog();
    } catch (e) {
      debugPrint('Error generating Excel file: $e');
      setState(() {
        isGenerating = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _createSettingsSheet(Excel excel) async {
    final sheet = excel['Settings'];

    int row = 0;

    // Title
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('GLOBAL SETTINGS');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
    );
    row += 2;

    // Global settings
    final globalSettings = wizardConfig!['globalSettings'] as Map<String, bool>;
    final globalValues = wizardConfig!['globalValues'] as Map<String, dynamic>;

    globalSettings.forEach((key, isSet) {
      if (isSet) {
        final displayName = _getDisplayName(key);
        final value = _formatValue(key, globalValues[key]);

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(displayName);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(value);
        row++;
      }
    });

    // Instructions
    row += 2;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('INSTRUCTIONS');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
    );
    row++;

    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            '1. Fill in schedule-specific settings on each team sheet');
    row++;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('2. Enter game data in the table rows');
    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue('3. Replace example values with your actual data');
    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            '4. Use valid options from the Reference sheet (locations, gender, etc.)');
    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            '5. Note: This Excel package doesn\'t support dropdown menus');
    row++;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('6. Upload the completed file back to the app');
  }

  Future<void> _createTeamSheet(Excel excel, int teamIndex) async {
    final sheetName = 'Team ${teamIndex + 1}';
    final sheet = excel[sheetName];

    int row = 0;

    // Games table - no schedule settings section needed
    row += 1;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('GAMES');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
    );
    row += 2;

    // Table headers - new comprehensive approach
    final headers = _getNewTableHeaders();
    for (int col = 0; col < headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(headers[col]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .cellStyle = CellStyle(
        bold: true,
      );
    }

    // Generate pre-filled game rows based on numberOfGames setting
    final numberOfGames = teamConfigs[teamIndex]['numberOfGames'] as int? ?? 10;
    for (int gameRow = 1; gameRow <= numberOfGames; gameRow++) {
      final excelRow = row + gameRow;
      _createPreFilledGameRow(sheet, headers, excelRow, teamIndex);
    }

    // Add instructions row
    final instructionRow = row + numberOfGames + 1;
    sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: instructionRow))
            .value =
        TextCellValue(
            '👆 Fill out game details above. Check the Reference sheet for valid dropdown options.');
    sheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: instructionRow))
        .cellStyle = CellStyle(
      fontSize: 10,
    );

    // Add additional instruction rows
    final instructionRow2 = row + numberOfGames + 2;
    sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: instructionRow2))
            .value =
        TextCellValue(
            '📋 Reference sheet has all valid values - copy and paste from there into your game data');
    sheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: instructionRow2))
        .cellStyle = CellStyle(
      fontSize: 9,
    );

    final instructionRow3 = row + numberOfGames + 3;
    sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: instructionRow3))
            .value =
        TextCellValue(
            '🔧 Multiple Lists: Use Officials List 1-3 + Min/Max. Single List: Use Officials List. Hire Crew: Use Crew List + optional Specific Crew Name');
    sheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: instructionRow3))
        .cellStyle = CellStyle(
      fontSize: 8,
    );
  }

  void _addDropdownValidations(
      dynamic sheet, List<String> headers, int excelRow, int headerRow, int teamIndex) {
    // Add helpful comments/examples for dropdown columns
    for (int col = 0; col < headers.length; col++) {
      final header = headers[col];
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: excelRow));

      // Add example values for first row only
      if (excelRow == headerRow + 1) {
        // First data row
        switch (header) {
          case 'Gender':
            cell.value = TextCellValue('Boys');
            break;
          case 'Competition Level':
            cell.value = TextCellValue('Varsity');
            break;
          case 'Officials Required':
            cell.value = TextCellValue('3');
            break;
          case 'Game Fee':
            cell.value = TextCellValue('75');
            break;
          case 'Officials Method':
            cell.value = TextCellValue('Single List');
            break;
          case 'Officials List':
            // Use the actual configured single list for this team
            final configuredSingleList = teamConfigs[teamIndex]['singleList'];
            cell.value = TextCellValue(configuredSingleList ?? '(See Reference sheet)');
            break;
          case 'Officials List 1':
            final multipleLists = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final list1 = multipleLists.isNotEmpty ? multipleLists[0]['list'] ?? '(See Reference sheet)' : '(See Reference sheet)';
            cell.value = TextCellValue(list1);
            break;
          case 'Min from List 1':
            final multipleLists1 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final min1 = multipleLists1.isNotEmpty ? multipleLists1[0]['min']?.toString() ?? '1' : '1';
            cell.value = TextCellValue(min1);
            break;
          case 'Max from List 1':
            final multipleLists2 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final max1 = multipleLists2.isNotEmpty ? multipleLists2[0]['max']?.toString() ?? '2' : '2';
            cell.value = TextCellValue(max1);
            break;
          case 'Officials List 2':
            final multipleLists3 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final list2 = multipleLists3.length > 1 ? multipleLists3[1]['list'] ?? '(See Reference sheet)' : '(See Reference sheet)';
            cell.value = TextCellValue(list2);
            break;
          case 'Min from List 2':
            final multipleLists4 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final min2 = multipleLists4.length > 1 ? multipleLists4[1]['min']?.toString() ?? '0' : '0';
            cell.value = TextCellValue(min2);
            break;
          case 'Max from List 2':
            final multipleLists5 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final max2 = multipleLists5.length > 1 ? multipleLists5[1]['max']?.toString() ?? '1' : '1';
            cell.value = TextCellValue(max2);
            break;
          case 'Officials List 3':
            final multipleLists6 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final list3 = multipleLists6.length > 2 ? multipleLists6[2]['list'] ?? '(Optional - See Reference)' : '(Optional - See Reference)';
            cell.value = TextCellValue(list3);
            break;
          case 'Min from List 3':
            final multipleLists7 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final min3 = multipleLists7.length > 2 ? multipleLists7[2]['min']?.toString() ?? '0' : '0';
            cell.value = TextCellValue(min3);
            break;
          case 'Max from List 3':
            final multipleLists8 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final max3 = multipleLists8.length > 2 ? multipleLists8[2]['max']?.toString() ?? '0' : '0';
            cell.value = TextCellValue(max3);
            break;
          case 'Crew List':
            // Use the actual configured crew list for this team
            final configuredCrewList = teamConfigs[teamIndex]['crewList'];
            cell.value = TextCellValue(configuredCrewList ?? '(See Reference sheet)');
            break;
          case 'Specific Crew Name':
            cell.value = TextCellValue('(Optional - specific crew)');
            break;
          case 'Hire Automatically':
            cell.value = TextCellValue('No');
            break;
          case 'Away Game':
            cell.value = TextCellValue('No');
            break;
        }
      }

      // Note: Excel data validation would require additional package features
      // For now, users will reference the Reference sheet for valid values
    }
  }

  Future<void> _createReferenceSheet(Excel excel) async {
    final sheet = excel['Reference'];

    int row = 0;
    int col = 0;

    // Locations
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue('VALID LOCATIONS');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .cellStyle = CellStyle(bold: true);
    row++;

    final locationService = LocationService();
    final locations = await locationService.getLocations();
    for (final location in locations) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(location['name'] as String);
      row++;
    }

    // Competition Levels
    row = 0;
    col = 2;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue('COMPETITION LEVELS');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .cellStyle = CellStyle(bold: true);
    row++;

    final competitionLevels = [
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
    for (final level in competitionLevels) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(level);
      row++;
    }

    // Gender Options
    row = 0;
    col = 4;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue('GENDER OPTIONS');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .cellStyle = CellStyle(bold: true);
    row++;

    final genderOptions = ['Boys', 'Girls', 'Co-ed', 'Men', 'Women'];
    for (final gender in genderOptions) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(gender);
      row++;
    }

    // Officials Lists
    row = 0;
    col = 6;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue('OFFICIALS LISTS');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .cellStyle = CellStyle(bold: true);
    row++;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      if (listsJson != null && listsJson.isNotEmpty) {
        final List<dynamic> lists = jsonDecode(listsJson);
        for (final list in lists) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
              .value = TextCellValue(list['name'] as String);
          row++;
        }
      }
    } catch (e) {
      debugPrint('Error loading officials lists for reference: $e');
    }

    // Crew Lists
    row = 0;
    col = 8;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue('CREW LISTS');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .cellStyle = CellStyle(bold: true);
    row++;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? crewListsJson = prefs.getString('saved_crew_lists');
      if (crewListsJson != null && crewListsJson.isNotEmpty) {
        final List<dynamic> crewLists = jsonDecode(crewListsJson);
        for (final crewList in crewLists) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
              .value = TextCellValue(crewList['name'] as String);
          row++;
        }
      }
    } catch (e) {
      debugPrint('Error loading crew lists for reference: $e');
    }

    // Officials Methods
    row = 0;
    col = 10;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue('OFFICIALS METHODS');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .cellStyle = CellStyle(bold: true);
    row++;

    final officialsMethods = [
      'Single List',
      'Multiple Lists',
      'Hire a Crew'
    ];
    for (final method in officialsMethods) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(method);
      row++;
    }

    // Yes/No Options
    row = 0;
    col = 12;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue('YES/NO OPTIONS');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .cellStyle = CellStyle(bold: true);
    row++;

    final yesNoOptions = ['Yes', 'No'];
    for (final option in yesNoOptions) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(option);
      row++;
    }

    // Min/Max Numbers (for Multiple Lists)
    row = 0;
    col = 14;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue('MIN/MAX NUMBERS');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .cellStyle = CellStyle(bold: true);
    row++;

    final minMaxNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (final number in minMaxNumbers) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(number);
      row++;
    }

    // Specific Crew Names (if available)
    row = 0;
    col = 16;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue('SPECIFIC CREW NAMES');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .cellStyle = CellStyle(bold: true);
    row++;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? crewsJson = prefs.getString('saved_crews');
      if (crewsJson != null && crewsJson.isNotEmpty) {
        final List<dynamic> crews = jsonDecode(crewsJson);
        for (final crew in crews) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
              .value = TextCellValue(crew['name'] as String);
          row++;
        }
      } else {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .value = TextCellValue('(Leave blank to use any crew)');
        row++;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .value = TextCellValue('(from selected Crew List)');
      }
    } catch (e) {
      debugPrint('Error loading specific crews for reference: $e');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue('(Optional - specific crew names)');
    }
  }

  List<String> _getTableHeaders(int teamIndex) {
    // Start with essential columns
    final headers = ['Date'];
    
    final globalSettings = wizardConfig!['globalSettings'] as Map<String, bool>;
    final scheduleSettings =
        wizardConfig!['scheduleSettings'] as Map<String, bool>;
    final globalValues = wizardConfig!['globalValues'] as Map<String, dynamic>;
    
    // Only add Time column if time is not set at global or schedule level
    final timeIsGlobal = globalSettings['time'] ?? false;
    final timeIsSchedule = scheduleSettings['time'] ?? false;
    if (!timeIsGlobal && !timeIsSchedule) {
      headers.add('Time');
    }
    
    // Always add Opponent
    headers.add('Opponent');

    // Add columns ONLY for settings that are neither global nor schedule-level
    // (i.e., settings that need to be specified per-game)
    final allSettings = [
      'gender',
      'competitionLevel', 
      'officialsRequired',
      'gameFee',
      'method',
      'hireAutomatically'
    ];

    for (final setting in allSettings) {
      if (!(globalSettings[setting] ?? false) &&
          !(scheduleSettings[setting] ?? false)) {
        headers.add(_getDisplayName(setting));
      }
    }

    // For method-specific columns: ONLY add if method itself is per-game
    final methodIsGlobal = globalSettings['method'] ?? false;
    final methodIsSchedule = scheduleSettings['method'] ?? false;
    final methodIsPerGame = !methodIsGlobal && !methodIsSchedule;

    if (methodIsPerGame) {
      // Method will be set per-game, so include ALL possible method columns
      headers.add('Officials List');
      headers.add('Officials List 1');
      headers.add('Min from List 1');
      headers.add('Max from List 1');
      headers.add('Officials List 2');
      headers.add('Min from List 2');
      headers.add('Max from List 2');
      headers.add('Officials List 3');
      headers.add('Min from List 3');
      headers.add('Max from List 3');
      headers.add('Crew List');
      headers.add('Specific Crew Name');
    }
    // If method is set at global or schedule level, NO method-specific columns needed
    // because the method and its configuration are already determined!

    return headers;
  }

  String _getDisplayName(String key) {
    switch (key) {
      case 'sport':
        return 'Sport';
      case 'gender':
        return 'Gender';
      case 'competitionLevel':
        return 'Competition Level';
      case 'officialsRequired':
        return 'Officials Required';
      case 'gameFee':
        return 'Game Fee';
      case 'method':
        return 'Officials Method';
      case 'hireAutomatically':
        return 'Hire Automatically';
      case 'scheduleName':
        return 'Schedule Name';
      case 'teamName':
        return 'Team Name';
      case 'location':
        return 'Home Location';
      default:
        return key;
    }
  }

  String _formatValue(String key, dynamic value) {
    switch (key) {
      case 'gameFee':
        return '\$${value.toString()}';
      case 'hireAutomatically':
        return value ? 'Yes' : 'No';
      default:
        return value.toString();
    }
  }

  bool _validateTeamConfigs() {
    final globalSettings = wizardConfig!['globalSettings'] as Map<String, bool>;
    final scheduleSettings =
        wizardConfig!['scheduleSettings'] as Map<String, bool>;

    for (int i = 0; i < teamConfigs.length; i++) {
      // Always validate Schedule Name
      if (teamConfigs[i]['scheduleName']?.trim()?.isEmpty ?? true) {
        _showValidationError(
            'Please enter a Schedule Name for Schedule ${i + 1}');
        return false;
      }

      // Validate Team Name if not set globally
      if (!(globalSettings['teamName'] ?? false) &&
          (teamConfigs[i]['teamName']?.trim()?.isEmpty ?? true)) {
        _showValidationError('Please enter a Team Name for Schedule ${i + 1}');
        return false;
      }

      // Validate other schedule-level settings
      scheduleSettings.forEach((key, isSet) {
        if (isSet) {
          final value = teamConfigs[i][_getConfigKey(key)];
          final displayName = _getDisplayName(key);

          if (value == null || (value is String && value.trim().isEmpty)) {
            _showValidationError(
                'Please set $displayName for Schedule ${i + 1}');
            return;
          }
        }
      });
    }
    return true;
  }

  String _getConfigKey(String key) {
    switch (key) {
      case 'location':
        return 'homeLocation';
      default:
        return key;
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Excel File Generated!',
          style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your Excel file has been created successfully. You can now share it, fill it out, and upload it back to the app.',
          style: TextStyle(color: Colors.white),
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

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Generation Failed',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Failed to generate Excel file:\n$error',
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

  Future<void> _shareFile() async {
    if (generatedFilePath != null) {
      try {
        await Share.shareXFiles([XFile(generatedFilePath!)],
            text: 'Bulk Game Import Excel File');
      } catch (e) {
        // Fallback if share plugin fails
        debugPrint('Share failed: $e');
        _showFileLocationDialog();
      }
    }
  }

  void _showFileLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Excel File Ready',
          style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Excel file has been saved to:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                generatedFilePath ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'For emulator development: Use Device Explorer in Android Studio to navigate to this path.',
              style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'For physical device: Use the Share button below or find this file in your Documents folder.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareFile();
            },
            child: const Text('Share File', style: TextStyle(color: efficialsYellow)),
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
          'Generate Excel File',
          style: TextStyle(color: efficialsYellow, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Schedule Configuration',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure each schedule\'s settings before generating the Excel file.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),

            // Team configuration forms
            if (wizardConfig != null)
              ...List.generate(
                  teamConfigs.length, (index) => _buildTeamConfigCard(index)),

            const SizedBox(height: 30),

            // Generation status
            if (isGenerating) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: efficialsYellow),
                    SizedBox(height: 16),
                    Text(
                      'Generating Excel file...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ] else if (generatedFilePath != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      painting.Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Excel file generated successfully!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _shareFile,
                      icon: const Icon(Icons.share, color: efficialsYellow),
                      label: const Text('Share',
                          style: TextStyle(color: efficialsYellow)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: generatedFilePath == null
          ? Container(
              color: efficialsBlack,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: ElevatedButton(
                onPressed: isGenerating ? null : _generateExcelFile,
                style: elevatedButtonStyle(),
                child: Text(
                  isGenerating ? 'Generating...' : 'Generate Excel File',
                  style: signInButtonTextStyle,
                ),
              ),
            )
          : Container(
              color: efficialsBlack,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/bulk_import_upload'),
                      child: const Text(
                        'Upload Completed File',
                        style: TextStyle(color: efficialsYellow, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _shareFile,
                      style: elevatedButtonStyle(),
                      child: const Text('Share File',
                          style: signInButtonTextStyle),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTeamConfigCard(int index) {
    final globalSettings = wizardConfig!['globalSettings'] as Map<String, bool>;
    final scheduleSettings =
        wizardConfig!['scheduleSettings'] as Map<String, bool>;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: painting.Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule ${index + 1} Configuration',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
          ),
          const SizedBox(height: 16),

          // Schedule Name (always required)
          _buildScheduleNameDropdown(index),

          // Team Name (if not set globally)
          if (!(globalSettings['teamName'] ?? false)) ...[
            const SizedBox(height: 12),
            _buildTeamNameDropdown(index),
          ],

          // Number of Games field
          const SizedBox(height: 12),
          _buildNumberOfGamesField(index),

          // Dynamic schedule-level settings
          ...scheduleSettings.entries
              .where((entry) => entry.value)
              .map((entry) {
            return Column(
              children: [
                const SizedBox(height: 12),
                _buildScheduleSettingField(index, entry.key),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTextField(int index, String key, String label, String hint) {
    // Special handling for Game Fee to show dollar sign
    if (key == 'gameFee') {
      return _buildGameFeeTextField(index, key, label, hint);
    }

    return TextField(
      decoration: textFieldDecoration(label).copyWith(hintText: hint),
      style: const TextStyle(color: Colors.white),
      onChanged: (value) {
        setState(() {
          teamConfigs[index][key] = value;
        });
      },
    );
  }

  Widget _buildGameFeeTextField(
      int index, String key, String label, String hint) {
    final currentValue = teamConfigs[index][key] as String? ?? '';
    final displayValue = currentValue.isEmpty ? '' : '\$$currentValue';
    final controller = TextEditingController(text: displayValue);

    // Set cursor position to end
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return TextField(
      controller: controller,
      decoration: textFieldDecoration(label).copyWith(hintText: hint),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        // Remove any existing dollar signs and non-numeric characters except decimal
        String numericValue = value.replaceAll(RegExp(r'[^\d.]'), '');

        // Update the stored value without dollar sign
        setState(() {
          teamConfigs[index][key] = numericValue;
        });

        // Format display with dollar sign
        final formatted = numericValue.isEmpty ? '' : '\$$numericValue';

        // Only update the controller if the formatted text is different to avoid cursor jumps
        if (controller.text != formatted) {
          controller.value = controller.value.copyWith(
            text: formatted,
            selection: TextSelection.fromPosition(
              TextPosition(offset: formatted.length),
            ),
          );
        }
      },
    );
  }

  Widget _buildScheduleSettingField(int index, String key) {
    switch (key) {
      case 'location':
        return _buildLocationDropdown(index);
      case 'gender':
        return _buildGenderDropdown(index);
      case 'competitionLevel':
        return _buildCompetitionLevelDropdown(index);
      case 'officialsRequired':
        return _buildOfficialsRequiredDropdown(index);
      case 'gameFee':
        return _buildTextField(
            index, 'gameFee', 'Game Fee per Official', 'e.g., \$75');
      case 'method':
        return _buildMethodConfiguration(index);
      case 'hireAutomatically':
        return _buildHireAutomaticallyDropdown(index);
      case 'time':
        return _buildTimePicker(index);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLocationDropdown(int index) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: LocationService().getLocations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: efficialsYellow);
        }

        final locations = snapshot.data!;
        return DropdownButtonFormField<String>(
          decoration: textFieldDecoration('Home Location'),
          value: teamConfigs[index]['homeLocation'],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: darkSurface,
          onChanged: (value) {
            setState(() {
              teamConfigs[index]['homeLocation'] = value;
            });
          },
          items: locations.map((location) {
            return DropdownMenuItem(
              value: location['name'] as String,
              child: Text(
                location['name'] as String,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGenderDropdown(int index) {
    final genderOptions = ['Boys', 'Girls', 'Co-ed', 'Men', 'Women'];
    return DropdownButtonFormField<String>(
      decoration: textFieldDecoration('Gender'),
      value: teamConfigs[index]['gender'],
      style: const TextStyle(color: Colors.white, fontSize: 16),
      dropdownColor: darkSurface,
      onChanged: (value) {
        setState(() {
          teamConfigs[index]['gender'] = value;
        });
      },
      items: genderOptions.map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text(gender, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }

  Widget _buildCompetitionLevelDropdown(int index) {
    final competitionLevels = [
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
    return DropdownButtonFormField<String>(
      decoration: textFieldDecoration('Competition Level'),
      value: teamConfigs[index]['competitionLevel'],
      style: const TextStyle(color: Colors.white, fontSize: 16),
      dropdownColor: darkSurface,
      onChanged: (value) {
        setState(() {
          teamConfigs[index]['competitionLevel'] = value;
        });
      },
      items: competitionLevels.map((level) {
        return DropdownMenuItem(
          value: level,
          child: Text(level, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }

  Widget _buildOfficialsRequiredDropdown(int index) {
    final officialsOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    return DropdownButtonFormField<int>(
      decoration: textFieldDecoration('Officials Required'),
      value: teamConfigs[index]['officialsRequired'],
      style: const TextStyle(color: Colors.white, fontSize: 16),
      dropdownColor: darkSurface,
      onChanged: (value) {
        setState(() {
          teamConfigs[index]['officialsRequired'] = value;
        });
      },
      items: officialsOptions.map((count) {
        return DropdownMenuItem(
          value: count,
          child: Text(count.toString(),
              style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }

  Widget _buildMethodDropdown(int index) {
    final methodOptions = [
      'Single List',
      'Multiple Lists',
      'Hire a Crew'
    ];
    return DropdownButtonFormField<String>(
      decoration: textFieldDecoration('Officials Assignment Method'),
      value: teamConfigs[index]['method'],
      style: const TextStyle(color: Colors.white, fontSize: 16),
      dropdownColor: darkSurface,
      onChanged: (value) {
        setState(() {
          teamConfigs[index]['method'] = value;
        });
      },
      items: methodOptions.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Text(method, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }

  Widget _buildHireAutomaticallyDropdown(int index) {
    final hireOptions = [true, false];
    return DropdownButtonFormField<bool>(
      decoration: textFieldDecoration('Hire Automatically'),
      value: teamConfigs[index]['hireAutomatically'],
      style: const TextStyle(color: Colors.white, fontSize: 16),
      dropdownColor: darkSurface,
      onChanged: (value) {
        setState(() {
          teamConfigs[index]['hireAutomatically'] = value;
        });
      },
      items: hireOptions.map((hire) {
        return DropdownMenuItem(
          value: hire,
          child: Text(hire ? 'Yes' : 'No',
              style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }

  Widget _buildTimePicker(int index) {
    final currentTime = teamConfigs[index]['time'] as String?;
    TimeOfDay? timeOfDay;

    // Parse existing time if available
    if (currentTime != null && currentTime.isNotEmpty) {
      try {
        final parts = currentTime.split(' ');
        final timePart = parts[0];
        final period = parts.length > 1 ? parts[1] : 'AM';
        final hourMinute = timePart.split(':');

        if (hourMinute.length == 2) {
          int hour = int.parse(hourMinute[0]);
          final minute = int.parse(hourMinute[1]);

          if (period.toUpperCase() == 'PM' && hour != 12) {
            hour += 12;
          } else if (period.toUpperCase() == 'AM' && hour == 12) {
            hour = 0;
          }

          timeOfDay = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        // If parsing fails, timeOfDay remains null
      }
    }

    return GestureDetector(
      onTap: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: timeOfDay ??
              const TimeOfDay(hour: 19, minute: 0), // Default to 7:00 PM
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: efficialsYellow,
                  onPrimary: Colors.black,
                  primaryContainer: efficialsYellow,
                  onPrimaryContainer: Colors.black,
                  surface: darkSurface,
                  onSurface: Colors.white,
                  background: darkBackground,
                  onBackground: Colors.white,
                  secondary: efficialsYellow,
                  onSecondary: Colors.black,
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

        if (pickedTime != null) {
          // Format time as "7:00 PM"
          final hour =
              pickedTime.hourOfPeriod == 0 ? 12 : pickedTime.hourOfPeriod;
          final minute = pickedTime.minute.toString().padLeft(2, '0');
          final period = pickedTime.period == DayPeriod.am ? 'AM' : 'PM';
          final formattedTime = '$hour:$minute $period';

          setState(() {
            teamConfigs[index]['time'] = formattedTime;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: painting.Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              currentTime?.isNotEmpty == true
                  ? currentTime!
                  : 'Select Game Time',
              style: TextStyle(
                color: currentTime?.isNotEmpty == true
                    ? Colors.white
                    : Colors.grey,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodConfiguration(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Method dropdown
        _buildMethodDropdown(index),

        // Additional configuration based on selected method
        const SizedBox(height: 12),
        ..._buildMethodSpecificConfiguration(index),
      ],
    );
  }

  List<Widget> _buildMethodSpecificConfiguration(int index) {
    final selectedMethod = teamConfigs[index]['method'] as String?;

    switch (selectedMethod) {
      case 'Single List':
        return [_buildSingleListConfiguration(index)];
      case 'Multiple Lists':
        return _buildMultipleListsConfiguration(index);
      case 'Hire a Crew':
        return [_buildHireCrewConfiguration(index)];
      default:
        return [];
    }
  }

  Widget _buildSingleListConfiguration(int index) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadOfficialsList(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: efficialsYellow);
        }

        final lists = snapshot.data!;
        return DropdownButtonFormField<String>(
          decoration: textFieldDecoration('Officials List'),
          value: teamConfigs[index]['singleList'],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: darkSurface,
          onChanged: (value) {
            setState(() {
              teamConfigs[index]['singleList'] = value;
            });
          },
          items: lists.map((list) {
            return DropdownMenuItem(
              value: list['name'] as String,
              child: Text(list['name'] as String,
                  style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        );
      },
    );
  }

  List<Widget> _buildMultipleListsConfiguration(int index) {
    // Initialize multipleLists if null
    if (teamConfigs[index]['multipleLists'] == null) {
      teamConfigs[index]['multipleLists'] = <Map<String, dynamic>>[
        {'list': null, 'min': 0, 'max': 1}
      ];
    }

    final multipleLists =
        teamConfigs[index]['multipleLists'] as List<Map<String, dynamic>>;

    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: painting.Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Configure Multiple Lists',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (multipleLists.length < 3)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        // Ensure the list reference is properly updated
                        final currentMultipleLists = List<Map<String, dynamic>>.from(multipleLists);
                        currentMultipleLists.add({'list': null, 'min': 0, 'max': 1});
                        teamConfigs[index]['multipleLists'] = currentMultipleLists;
                      });
                    },
                    icon: const Icon(Icons.add_circle, color: efficialsYellow),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...multipleLists.asMap().entries.map((entry) {
              final listIndex = entry.key;
              final listConfig = entry.value;
              return _buildMultipleListItem(
                  index, listIndex, listConfig, multipleLists);
            }).toList(),
          ],
        ),
      ),
    ];
  }

  Widget _buildMultipleListItem(
      int scheduleIndex,
      int listIndex,
      Map<String, dynamic> listConfig,
      List<Map<String, dynamic>> multipleLists) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'List ${listIndex + 1}',
                style: const TextStyle(
                    color: efficialsYellow, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (multipleLists.length > 1)
                IconButton(
                  onPressed: () {
                    setState(() {
                      // Ensure the list reference is properly updated
                      final currentMultipleLists = List<Map<String, dynamic>>.from(multipleLists);
                      currentMultipleLists.removeAt(listIndex);
                      teamConfigs[scheduleIndex]['multipleLists'] = currentMultipleLists;
                    });
                  },
                  icon: const Icon(Icons.remove_circle,
                      color: Colors.red, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // List selection
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadOfficialsList(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator(color: efficialsYellow);
              }

              final lists = snapshot.data!;
              return DropdownButtonFormField<String>(
                decoration: textFieldDecoration('Select Officials List'),
                value: listConfig['list'],
                style: const TextStyle(color: Colors.white, fontSize: 14),
                dropdownColor: darkSurface,
                onChanged: (value) {
                  setState(() {
                    listConfig['list'] = value;
                  });
                },
                items: lists.map((list) {
                  return DropdownMenuItem(
                    value: list['name'] as String,
                    child: Text(list['name'] as String,
                        style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          // Min/Max configuration
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: textFieldDecoration('Min'),
                  value: listConfig['min'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  dropdownColor: darkSurface,
                  onChanged: (value) {
                    setState(() {
                      listConfig['min'] = value;
                    });
                  },
                  items: List.generate(10, (i) => i).map((num) {
                    return DropdownMenuItem(
                      value: num,
                      child: Text(num.toString(),
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: textFieldDecoration('Max'),
                  value: listConfig['max'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  dropdownColor: darkSurface,
                  onChanged: (value) {
                    setState(() {
                      listConfig['max'] = value;
                    });
                  },
                  items: List.generate(10, (i) => i + 1).map((num) {
                    return DropdownMenuItem(
                      value: num,
                      child: Text(num.toString(),
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHireCrewConfiguration(int index) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadCrewLists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: efficialsYellow);
        }

        final crewLists = snapshot.data!;
        return DropdownButtonFormField<String>(
          decoration: textFieldDecoration('Crew List'),
          value: teamConfigs[index]['crewList'],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: darkSurface,
          onChanged: (value) {
            setState(() {
              teamConfigs[index]['crewList'] = value;
            });
          },
          items: crewLists.map((list) {
            return DropdownMenuItem(
              value: list['name'] as String,
              child: Text(list['name'] as String,
                  style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildScheduleNameDropdown(int index) {
    return FutureBuilder<List<String>>(
      future: _loadScheduleNames(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: efficialsYellow);
        }

        final scheduleNames = snapshot.data!;

        // Create dropdown with option to add new schedule
        final allOptions = [...scheduleNames, '+ Add New Schedule'];

        return DropdownButtonFormField<String>(
          decoration: textFieldDecoration('Schedule Name'),
          value: teamConfigs[index]['scheduleName']?.isEmpty == true
              ? null
              : teamConfigs[index]['scheduleName'],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: darkSurface,
          onChanged: (value) {
            if (value == '+ Add New Schedule') {
              _showAddScheduleDialog(index);
            } else {
              setState(() {
                teamConfigs[index]['scheduleName'] = value;
              });
            }
          },
          items: allOptions.map((name) {
            return DropdownMenuItem(
              value: name == '+ Add New Schedule' ? '+ Add New Schedule' : name,
              child: Text(
                name,
                style: TextStyle(
                  color: name == '+ Add New Schedule'
                      ? efficialsYellow
                      : Colors.white,
                  fontStyle: name == '+ Add New Schedule'
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTeamNameDropdown(int index) {
    return FutureBuilder<List<String>>(
      future: _loadTeamNames(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: efficialsYellow);
        }

        final teamNames = snapshot.data!;

        // Create dropdown with option to add new team
        final allOptions = [...teamNames, '+ Add New Team'];

        return DropdownButtonFormField<String>(
          decoration: textFieldDecoration('Team Name'),
          value: teamConfigs[index]['teamName']?.isEmpty == true
              ? null
              : teamConfigs[index]['teamName'],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: darkSurface,
          onChanged: (value) {
            if (value == '+ Add New Team') {
              _showAddTeamDialog(index);
            } else {
              setState(() {
                teamConfigs[index]['teamName'] = value;
              });
            }
          },
          items: allOptions.map((name) {
            return DropdownMenuItem(
              value: name == '+ Add New Team' ? '+ Add New Team' : name,
              child: Text(
                name,
                style: TextStyle(
                  color:
                      name == '+ Add New Team' ? efficialsYellow : Colors.white,
                  fontStyle: name == '+ Add New Team'
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<String>> _loadScheduleNames() async {
    try {
      final scheduleService = ScheduleService();
      final scheduleNames = await scheduleService.getScheduleNames();
      return scheduleNames;
    } catch (e) {
      debugPrint('Error loading schedule names: $e');
      return [];
    }
  }

  Future<List<String>> _loadTeamNames() async {
    try {
      final scheduleService = ScheduleService();
      final schedules = await scheduleService.getRecentSchedules();
      final teamNames = schedules
          .map((schedule) => schedule['homeTeamName'] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      return teamNames;
    } catch (e) {
      debugPrint('Error loading team names: $e');
      return [];
    }
  }

  void _showAddScheduleDialog(int index) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Add New Schedule',
            style: TextStyle(color: efficialsYellow)),
        content: TextField(
          controller: controller,
          decoration: textFieldDecoration('Schedule Name')
              .copyWith(hintText: 'e.g., Edwardsville Varsity'),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  teamConfigs[index]['scheduleName'] = name;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  void _showAddTeamDialog(int index) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text('Add New Team',
            style: TextStyle(color: efficialsYellow)),
        content: TextField(
          controller: controller,
          decoration: textFieldDecoration('Team Name')
              .copyWith(hintText: 'e.g., Edwardsville Tigers'),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  teamConfigs[index]['teamName'] = name;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadOfficialsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? listsJson = prefs.getString('saved_lists');
      if (listsJson != null && listsJson.isNotEmpty) {
        return List<Map<String, dynamic>>.from(jsonDecode(listsJson));
      }
    } catch (e) {
      debugPrint('Error loading officials lists: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _loadCrewLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? crewListsJson = prefs.getString('saved_crew_lists');
      if (crewListsJson != null && crewListsJson.isNotEmpty) {
        return List<Map<String, dynamic>>.from(jsonDecode(crewListsJson));
      }
    } catch (e) {
      debugPrint('Error loading crew lists: $e');
    }
    return [];
  }

  Widget _buildNumberOfGamesField(int index) {
    final controller = TextEditingController();
    
    // Set initial value if it exists, but don't pre-fill with default
    final currentValue = teamConfigs[index]['numberOfGames'];
    if (currentValue != null && currentValue != 10) {
      controller.text = currentValue.toString();
    }

    return TextField(
      controller: controller,
      decoration: textFieldDecoration('Number of Games').copyWith(
        hintText: 'Number of Home Games (e.g., 10)',
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final numValue = int.tryParse(value);
        if (numValue != null && numValue > 0 && numValue <= 50) {
          setState(() {
            teamConfigs[index]['numberOfGames'] = numValue;
          });
        } else if (value.isEmpty) {
          // Reset to default when field is empty
          setState(() {
            teamConfigs[index]['numberOfGames'] = 10;
          });
        }
      },
    );
  }

  List<String> _getNewTableHeaders() {
    // Always start with Date and Opponent as the user-fillable columns
    List<String> headers = ['Date', 'Opponent'];
    
    // Add all other columns that will be pre-filled
    headers.addAll([
      'Schedule Name',
      'Team Name', 
      'Sport',  // Critical: GameService requires sport field
      'Time',
      'Gender',
      'Competition Level',
      'Officials Required',
      'Game Fee',
      'Hire Automatically',
      'Officials Method',
      'Location',
      'Away Game',
    ]);
    
    // Add method-specific columns - include all possible ones
    headers.addAll([
      'Officials List',
      'Officials List 1',
      'Officials List 1 Min',
      'Officials List 1 Max', 
      'Officials List 2',
      'Officials List 2 Min',
      'Officials List 2 Max',
      'Officials List 3',
      'Officials List 3 Min',
      'Officials List 3 Max',
      'Crew List',
      'Specific Crew Name',
    ]);
    
    return headers;
  }

  void _createPreFilledGameRow(dynamic sheet, List<String> headers, int rowIndex, int teamIndex) {
    final globalSettings = wizardConfig!['globalSettings'] as Map<String, bool>;
    final globalValues = wizardConfig!['globalValues'] as Map<String, dynamic>;
    final scheduleSettings = wizardConfig!['scheduleSettings'] as Map<String, bool>;
    
    for (int col = 0; col < headers.length; col++) {
      final header = headers[col];
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      
      switch (header) {
        case 'Date':
        case 'Opponent':
          // Always leave empty for user to fill
          break;
          
        case 'Schedule Name':
          // Always pre-fill schedule name
          cell.value = TextCellValue(teamConfigs[teamIndex]['scheduleName'] ?? '');
          break;
          
        case 'Team Name':
          // Pre-fill if set globally or at schedule level
          if (globalSettings['teamName'] ?? false) {
            cell.value = TextCellValue(globalValues['teamName']?.toString() ?? '');
          } else {
            // Leave empty for user to fill per-game
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Sport':
          // Always pre-fill sport (it's always set globally in the wizard)
          cell.value = TextCellValue(globalValues['sport']?.toString() ?? 'Unknown');
          break;
          
        case 'Time':
          // Pre-fill only if set globally or at schedule level
          if (globalSettings['time'] ?? false) {
            cell.value = TextCellValue(globalValues['time']?.toString() ?? '');
          } else if (scheduleSettings['time'] ?? false) {
            cell.value = TextCellValue(teamConfigs[teamIndex]['time']?.toString() ?? '');
          } else {
            // Leave empty for user to fill per-game
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Gender':
          // Pre-fill only if set globally or at schedule level
          if (globalSettings['gender'] ?? false) {
            cell.value = TextCellValue(globalValues['gender']?.toString() ?? '');
          } else if (scheduleSettings['gender'] ?? false) {
            cell.value = TextCellValue(teamConfigs[teamIndex]['gender']?.toString() ?? '');
          } else {
            // Leave empty for user to fill per-game
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Competition Level':
          // Pre-fill only if set globally or at schedule level
          if (globalSettings['competitionLevel'] ?? false) {
            cell.value = TextCellValue(globalValues['competitionLevel']?.toString() ?? '');
          } else if (scheduleSettings['competitionLevel'] ?? false) {
            cell.value = TextCellValue(teamConfigs[teamIndex]['competitionLevel']?.toString() ?? '');
          } else {
            // Leave empty for user to fill per-game
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Officials Required':
          // Pre-fill only if set globally or at schedule level
          if (globalSettings['officialsRequired'] ?? false) {
            cell.value = TextCellValue(globalValues['officialsRequired']?.toString() ?? '');
          } else if (scheduleSettings['officialsRequired'] ?? false) {
            cell.value = TextCellValue(teamConfigs[teamIndex]['officialsRequired']?.toString() ?? '');
          } else {
            // Leave empty for user to fill per-game
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Game Fee':
          // Pre-fill only if set globally or at schedule level
          if (globalSettings['gameFee'] ?? false) {
            cell.value = TextCellValue(globalValues['gameFee']?.toString() ?? '');
          } else if (scheduleSettings['gameFee'] ?? false) {
            cell.value = TextCellValue(teamConfigs[teamIndex]['gameFee']?.toString() ?? '');
          } else {
            // Leave empty for user to fill per-game
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Hire Automatically':
          // Pre-fill only if set globally or at schedule level
          if (globalSettings['hireAutomatically'] ?? false) {
            final hire = globalValues['hireAutomatically'] as bool? ?? false;
            cell.value = TextCellValue(hire ? 'Yes' : 'No');
          } else if (scheduleSettings['hireAutomatically'] ?? false) {
            final hire = teamConfigs[teamIndex]['hireAutomatically'] as bool? ?? false;
            cell.value = TextCellValue(hire ? 'Yes' : 'No');
          } else {
            // Leave empty for user to fill per-game
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Officials Method':
          // Pre-fill only if set globally or at schedule level
          if (globalSettings['method'] ?? false) {
            cell.value = TextCellValue(globalValues['method']?.toString() ?? '');
          } else if (scheduleSettings['method'] ?? false) {
            cell.value = TextCellValue(teamConfigs[teamIndex]['method']?.toString() ?? '');
          } else {
            // Leave empty for user to fill per-game
            cell.value = TextCellValue('');
          }
          break;

        case 'Location':
          // Pre-fill only if set globally or at schedule level
          if (globalSettings['location'] ?? false) {
            cell.value = TextCellValue(globalValues['location']?.toString() ?? '');
          } else if (scheduleSettings['location'] ?? false) {
            cell.value = TextCellValue(teamConfigs[teamIndex]['homeLocation']?.toString() ?? '');
          } else {
            // Leave empty for user to fill per-game
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Away Game':
          cell.value = TextCellValue('No'); // Default to home games
          break;
          
        case 'Officials List':
          // Only pre-fill if Single List method is set at global or schedule level
          if (_isMethodSetForTeam('Single List', teamIndex)) {
            final singleList = teamConfigs[teamIndex]['singleList'] ?? '';
            cell.value = TextCellValue(singleList.toString());
          } else {
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Officials List 1':
          // Only pre-fill if Multiple Lists method is set at global or schedule level
          if (_isMethodSetForTeam('Multiple Lists', teamIndex)) {
            final multipleLists = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final list1 = multipleLists.isNotEmpty ? (multipleLists[0]['list'] ?? '') : '';
            cell.value = TextCellValue(list1.toString());
          } else {
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Officials List 1 Min':
          // Only pre-fill if Multiple Lists method is set at global or schedule level
          if (_isMethodSetForTeam('Multiple Lists', teamIndex)) {
            final multipleLists1 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final min1 = multipleLists1.isNotEmpty ? (multipleLists1[0]['min'] ?? 0) : 0;
            cell.value = TextCellValue(min1.toString());
          } else {
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Officials List 1 Max':
          // Only pre-fill if Multiple Lists method is set at global or schedule level
          if (_isMethodSetForTeam('Multiple Lists', teamIndex)) {
            final multipleLists2 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final max1 = multipleLists2.isNotEmpty ? (multipleLists2[0]['max'] ?? 0) : 0;
            cell.value = TextCellValue(max1.toString());
          } else {
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Officials List 2':
          // Only pre-fill if Multiple Lists method is set at global or schedule level
          if (_isMethodSetForTeam('Multiple Lists', teamIndex)) {
            final multipleLists3 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final list2 = multipleLists3.length > 1 ? (multipleLists3[1]['list'] ?? '') : '';
            cell.value = TextCellValue(list2.toString());
          } else {
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Officials List 2 Min':
          // Only pre-fill if Multiple Lists method is set at global or schedule level
          if (_isMethodSetForTeam('Multiple Lists', teamIndex)) {
            final multipleLists4 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final min2 = multipleLists4.length > 1 ? (multipleLists4[1]['min'] ?? 0) : 0;
            cell.value = TextCellValue(min2.toString());
          } else {
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Officials List 2 Max':
          // Only pre-fill if Multiple Lists method is set at global or schedule level
          if (_isMethodSetForTeam('Multiple Lists', teamIndex)) {
            final multipleLists5 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final max2 = multipleLists5.length > 1 ? (multipleLists5[1]['max'] ?? 0) : 0;
            cell.value = TextCellValue(max2.toString());
          } else {
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Officials List 3':
          // Only pre-fill if Multiple Lists method is set at global or schedule level
          if (_isMethodSetForTeam('Multiple Lists', teamIndex)) {
            final multipleLists6 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final list3 = multipleLists6.length > 2 ? (multipleLists6[2]['list'] ?? '') : '';
            cell.value = TextCellValue(list3.toString());
          } else {
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Officials List 3 Min':
          // Only pre-fill if Multiple Lists method is set at global or schedule level
          if (_isMethodSetForTeam('Multiple Lists', teamIndex)) {
            final multipleLists7 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final min3 = multipleLists7.length > 2 ? (multipleLists7[2]['min'] ?? 0) : 0;
            cell.value = TextCellValue(min3.toString());
          } else {
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Officials List 3 Max':
          // Only pre-fill if Multiple Lists method is set at global or schedule level
          if (_isMethodSetForTeam('Multiple Lists', teamIndex)) {
            final multipleLists8 = teamConfigs[teamIndex]['multipleLists'] as List<Map<String, dynamic>>? ?? [];
            final max3 = multipleLists8.length > 2 ? (multipleLists8[2]['max'] ?? 0) : 0;
            cell.value = TextCellValue(max3.toString());
          } else {
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Crew List':
          // Only pre-fill if Hire a Crew method is set at global or schedule level
          if (_isMethodSetForTeam('Hire a Crew', teamIndex)) {
            final crewList = teamConfigs[teamIndex]['crewList'] ?? '';
            cell.value = TextCellValue(crewList.toString());
          } else {
            cell.value = TextCellValue('');
          }
          break;
          
        case 'Specific Crew Name':
          cell.value = TextCellValue(''); // Leave empty for optional specific crew
          break;
      }
    }
  }

  bool _isMethodSetForTeam(String methodName, int teamIndex) {
    final globalSettings = wizardConfig!['globalSettings'] as Map<String, bool>;
    final globalValues = wizardConfig!['globalValues'] as Map<String, dynamic>;
    final scheduleSettings = wizardConfig!['scheduleSettings'] as Map<String, bool>;
    
    // Check if method is set globally
    if (globalSettings['method'] ?? false) {
      return globalValues['method']?.toString() == methodName;
    }
    
    // Check if method is set at schedule level for this specific team
    if (scheduleSettings['method'] ?? false) {
      return teamConfigs[teamIndex]['method']?.toString() == methodName;
    }
    
    return false;
  }
}
