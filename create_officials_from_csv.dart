import 'package:flutter/material.dart';
import 'lib/shared/models/database_models.dart';
import 'lib/shared/services/repositories/official_repository.dart';
import 'lib/shared/services/database_helper.dart';
import 'lib/shared/services/auth_service.dart';

class OfficialCreator {
  final OfficialRepository _officialRepo = OfficialRepository();
  
  /// Creates officials from CSV data
  /// Expected CSV format: Level of Certification,Years of Experience,Last Name,First Name,Address,City,ZIP,Cell Phone
  Future<List<int>> createOfficialsFromCsv(String csvData) async {
    final lines = csvData.trim().split('\n');
    
    // Skip header row if it exists
    final dataLines = lines.where((line) => 
      !line.toLowerCase().contains('certification') && 
      !line.toLowerCase().contains('experience') &&
      line.trim().isNotEmpty
    ).toList();
    
    print('Processing ${dataLines.length} officers from CSV data...');
    
    // Get Football sport ID
    final db = await DatabaseHelper().database;
    final footballResult = await db.query('sports', where: 'name = ?', whereArgs: ['Football']);
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
        print('Skipping line ${i + 1}: insufficient data - ${parts.length} fields');
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
      
      // Validate name constraint (men's names only)
      if (!_isValidMaleName(firstName)) {
        print('Skipping ${firstName} ${lastName}: Not a valid male name');
        continue;
      }
      
      // Validate location constraint (within 100 miles of Edwardsville, IL)
      if (!_isValidLocation(city)) {
        print('Skipping ${firstName} ${lastName}: ${city} is not within 100 miles of Edwardsville, IL');
        continue;
      }
      
      // Generate email: first letter of first name + last name + @test.com
      final email = '${firstName.toLowerCase()[0]}${lastName.toLowerCase()}@test.com';
      
      final official = Official(
        name: '$firstName $lastName',
        userId: 1, // System user for batch created officials
        email: email,
        phone: phone,
        city: city,
        state: 'IL', // All approved locations are in Illinois
        experienceYears: yearsExp,
        certificationLevel: certLevel,
        isUserAccount: false, // These are not user accounts, just official records
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
    
    // Create OfficialUser entries for authentication
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
      
      await db.insert('official_users', officialUser.toMap());
    }
    
    print('Successfully created ${officialIds.length} official user accounts for authentication');
    
    // Create OfficialSport entries for each official
    for (int i = 0; i < officialIds.length; i++) {
      final officialSport = OfficialSport(
        officialId: officialIds[i],
        sportId: footballSportId,
        certificationLevel: officials[i].certificationLevel,
        yearsExperience: officials[i].experienceYears,
        isPrimary: true, // Football is their primary sport
      );
      officialSports.add(officialSport);
    }
    
    // Insert OfficialSport entries
    for (final officialSport in officialSports) {
      await db.insert('official_sports', officialSport.toMap());
    }
    
    print('Successfully created ${officialSports.length} official-sport associations');
    print('All officials are registered for Football');
    
    return officialIds;
  }
  
  /// Validates that the first name is a traditional male name
  bool _isValidMaleName(String firstName) {
    final maleNames = {
      'john', 'michael', 'david', 'robert', 'james', 'william', 'richard', 'charles',
      'thomas', 'christopher', 'daniel', 'paul', 'mark', 'donald', 'george', 'kenneth',
      'steven', 'edward', 'brian', 'ronald', 'anthony', 'kevin', 'jason', 'matthew',
      'gary', 'timothy', 'jose', 'larry', 'jeffrey', 'frank', 'scott', 'eric',
      'stephen', 'andrew', 'raymond', 'gregory', 'joshua', 'jerry', 'dennis', 'walter',
      'patrick', 'peter', 'harold', 'douglas', 'henry', 'carl', 'arthur', 'ryan',
      'roger', 'joe', 'juan', 'jack', 'albert', 'jonathan', 'justin', 'terry',
      'austin', 'sean', 'benjamin', 'zachary', 'samuel', 'tyler', 'mason', 'jacob',
      'noah', 'lucas', 'ethan', 'alexander', 'owen', 'caleb', 'isaac', 'nathan',
      'logan', 'hunter', 'aaron', 'elijah', 'wayne', 'adam', 'ralph', 'roy',
      'eugene', 'louis', 'philip', 'bobby', 'johnny', 'mason'
    };
    
    return maleNames.contains(firstName.toLowerCase());
  }
  
  /// Validates that the city is within 100 miles of Edwardsville, IL
  bool _isValidLocation(String city) {
    final approvedCities = {
      'edwardsville', 'alton', 'collinsville', 'belleville', 'glen carbon',
      'highland', 'greenville', 'litchfield', 'vandalia', 'centralia',
      'effingham', 'mattoon', 'charleston', 'taylorville', 'hillsboro',
      'carlinville', 'springfield', 'red bud', 'waterloo', 'columbia'
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
  
  /// Test method to process a few sample officials
  Future<void> testWithSampleData() async {
    final sampleCsv = '''Level of Certification,Years of Experience,Last Name,First Name,Address,City,ZIP,Cell Phone
Certified,8,Aldridge,Brandon,2627 Columbia Lakes Drive Unit 2D,Columbia,62236,618-719-4373
Registered,3,Angleton,Darrell,800 Alton St,Alton,62002,618-792-9995
Recognized,11,Baird,Robert,1217 W Woodfield Dr,Alton,62002,618-401-4016''';
    
    print('Testing with 3 sample officials...');
    final ids = await createOfficialsFromCsv(sampleCsv);
    print('Test completed. Created official IDs: $ids');
  }
}