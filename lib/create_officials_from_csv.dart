import 'package:flutter/material.dart';
import 'shared/models/database_models.dart';
import 'shared/services/repositories/official_repository.dart';
import 'shared/services/database_helper.dart';
import 'shared/services/auth_service.dart';

class OfficialCreator {
  final OfficialRepository _officialRepo = OfficialRepository();

  /// Creates officials from CSV data
  /// Expected CSV format: Level of Certification,Years of Experience,Last Name,First Name,Address,City,ZIP,Cell Phone
  Future<List<int>> createOfficialsFromCsv(String csvData) async {
    final lines = csvData.trim().split('\n');

    // Skip header row if it exists
    final dataLines = lines
        .where((line) =>
            !line.toLowerCase().contains('certification') &&
            !line.toLowerCase().contains('experience') &&
            line.trim().isNotEmpty)
        .toList();

    print('Processing ${dataLines.length} officers from CSV data...');

    // Get Football sport ID
    final db = await DatabaseHelper().database;
    final footballResult =
        await db.query('sports', where: 'name = ?', whereArgs: ['Football']);
    int footballSportId;

    if (footballResult.isEmpty) {
      footballSportId = await db.insert('sports', {'name': 'Football'});
      print('Created Football sport with ID: $footballSportId');
    } else {
      footballSportId = footballResult.first['id'] as int;
      print('Found existing Football sport ID: $footballSportId');
    }

    List<Official> officials = [];
    List<OfficialSport> officialSports = [];

    for (int i = 0; i < dataLines.length; i++) {
      final line = dataLines[i];
      // Handle CSV parsing with proper quote handling
      final parts = _parseCSVLine(line);

      if (parts.length < 8) {
        print(
            'Skipping line ${i + 1}: insufficient data - ${parts.length} fields');
        continue;
      }

      // Updated column order: Level of Certification,Years of Experience,Last Name,First Name,Address,City,ZIP,Cell Phone
      final certLevel = parts[0];
      final yearsExp = int.tryParse(parts[1]) ?? 0;
      final lastName = parts[2];
      final firstName = parts[3];
      final address = parts[4]; // Not used in Official model currently
      final city = parts[5];
      final zip = parts[6]; // Not used in Official model currently
      final phone = parts[7];

      // Validate location constraint (within 100 miles of Edwardsville, IL)
      if (!_isValidLocation(city)) {
        print(
            'Skipping ${firstName} ${lastName}: ${city} is not within 100 miles of Edwardsville, IL');
        continue;
      }

      // Generate email: first letter of first name + last name + @test.com
      final email =
          '${firstName.toLowerCase().substring(0, 2)}${lastName.toLowerCase()}@test.com';

      final official = Official(
        name: '$firstName $lastName',
        userId: 1, // System user for batch created officials
        email: email,
        phone: phone,
        city: city,
        state: 'IL', // All approved locations are in Illinois
        experienceYears: yearsExp,
        certificationLevel: certLevel,
        isUserAccount:
            false, // These are not user accounts, just official records
      );

      officials.add(official);
    }

    print('Created ${officials.length} valid official objects');

    if (officials.isEmpty) {
      print('No valid officials to create');
      return [];
    }

    // Batch create officials
    final officialIds = await _officialRepo.batchCreateOfficials(officials);
    print('Successfully created ${officialIds.length} officials in database');

    // Create OfficialUser entries for authentication and link them to officials
    for (int i = 0; i < officialIds.length; i++) {
      final official = officials[i];

      // Hash the password properly using AuthService
      final passwordHash = AuthService.hashPassword('test123');

      final officialUser = OfficialUser(
        email: official.email!,
        passwordHash: passwordHash,
        phone: official.phone ?? '',
        firstName: official.name.split(' ')[0],
        lastName: official.name.split(' ').skip(1).join(' '),
        profileVerified: true,
        emailVerified: true,
        phoneVerified: true,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final officialUserId =
          await db.insert('official_users', officialUser.toMap());

      // Update the official record to link it with the official_user
      await db.update(
        'officials',
        {'official_user_id': officialUserId},
        where: 'id = ?',
        whereArgs: [officialIds[i]],
      );
    }

    print(
        'Successfully created ${officialIds.length} official user accounts for authentication');

    // Create OfficialSport entries for each official
    for (int i = 0; i < officialIds.length; i++) {
      final officialSport = OfficialSport(
        officialId: officialIds[i],
        sportId: footballSportId,
        certificationLevel: officials[i].certificationLevel,
        yearsExperience: officials[i].experienceYears,
        competitionLevels: 'Underclass,JV,Varsity', // All officials can do Underclass, JV, and Varsity
        isPrimary: true, // Football is their primary sport
      );
      officialSports.add(officialSport);
    }

    // Insert OfficialSport entries
    for (final officialSport in officialSports) {
      await db.insert('official_sports', officialSport.toMap());
    }

    print(
        'Successfully created ${officialSports.length} official-sport associations');
    print('All officials are registered for Football with competition levels: Underclass, JV, Varsity');

    return officialIds;
  }

  /// Validates that the city is within 100 miles of Edwardsville, IL
  bool _isValidLocation(String city) {
    final approvedCities = {
      'edwardsville',
      'alton',
      'collinsville',
      'belleville',
      'glen carbon',
      'highland',
      'greenville',
      'litchfield',
      'vandalia',
      'centralia',
      'effingham',
      'mattoon',
      'charleston',
      'taylorville',
      'hillsboro',
      'carlinville',
      'springfield',
      'red bud',
      'waterloo',
      'columbia',
      'nashville',
      'coulterville',
      'maryville',
      'greenfield',
      'o\'fallon',
      'fairview heights',
      'granite city',
      'gillespie',
      'swansea',
      'hartford',
      'troy',
      'steeleville',
      'breese',
      'dupo',
      'shiloh',
      'freeburg',
      'hazelwood',
      'high ridge',
      'east st. louis',
      'st. jacob',
      'golden eagle',
      'coffeen',
      'roodhouse',
      'carrollton',
      'wood river',
      'chester',
      'grafton',
      'mascoutah',
      'saint louis',
      'st. louis',
      'millstadt',
      'white hall',
      'florissant',
      'carlyle',
      'venice',
      'east alton',
      'batchtown',
      'witt',
      'staunton',
      'nokomis',
      'eldred',
      'pinckneyville'
    };

    return approvedCities.contains(city.toLowerCase());
  }

  /// Parses a CSV line handling quoted fields properly
  List<String> _parseCSVLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String currentField = '';

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }

    // Add the last field
    result.add(currentField.trim());

    return result;
  }

  /// Public validation method for testing
  Map<String, dynamic> validateOfficialData(String csvLine) {
    final parts = _parseCSVLine(csvLine);

    if (parts.length < 8) {
      return {'valid': false, 'reason': 'Insufficient data fields'};
    }

    final certLevel = parts[0];
    final yearsExp = int.tryParse(parts[1]) ?? 0;
    final lastName = parts[2];
    final firstName = parts[3];
    final city = parts[5];
    final phone = parts[7];

    final isValidLocation = _isValidLocation(city);

    return {
      'valid': isValidLocation,
      'firstName': firstName,
      'lastName': lastName,
      'certification': certLevel,
      'experience': yearsExp,
      'city': city,
      'phone': phone,
      'validLocation': isValidLocation,
      'email':
          '${firstName.toLowerCase().substring(0, 2)}${lastName.toLowerCase()}@test.com',
    };
  }

  /// Fixes existing officials that may not have competition levels set
  Future<int> fixExistingOfficialsCompetitionLevels() async {
    final db = await DatabaseHelper().database;
    
    // Find official_sports entries that have NULL or empty competition_levels
    final officialSportsWithoutLevels = await db.query(
      'official_sports',
      where: 'competition_levels IS NULL OR competition_levels = ""',
    );
    
    if (officialSportsWithoutLevels.isEmpty) {
      print('All official_sports entries already have competition levels set');
      return 0;
    }
    
    print('Found ${officialSportsWithoutLevels.length} official_sports entries without competition levels');
    
    int updatedCount = 0;
    for (final entry in officialSportsWithoutLevels) {
      await db.update(
        'official_sports',
        {'competition_levels': 'Underclass,JV,Varsity'},
        where: 'id = ?',
        whereArgs: [entry['id']],
      );
      updatedCount++;
    }
    
    print('Updated $updatedCount official_sports entries with competition levels: Underclass, JV, Varsity');
    return updatedCount;
  }

  /// Test method to process a few sample officials
  Future<void> testWithSampleData() async {
    final sampleCsv =
        '''Level of Certification,Years of Experience,Last Name,First Name,Address,City,ZIP,Cell Phone
Certified,8,Aldridge,Brandon,2627 Columbia Lakes Drive Unit 2D,Columbia,62236,618-719-4373
Registered,3,Angleton,Darrell,800 Alton St,Alton,62002,618-792-9995
Recognized,11,Baird,Robert,1217 W Woodfield Dr,Alton,62002,618-401-4016''';

    print('Testing with 3 sample officials...');
    final ids = await createOfficialsFromCsv(sampleCsv);
    print('Test completed. Created official IDs: $ids');
  }
}
