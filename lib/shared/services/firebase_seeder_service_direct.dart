import 'package:flutter/foundation.dart';
import 'firebase_database_service.dart';
import 'firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSeederService {
  static final FirebaseSeederService _instance =
      FirebaseSeederService._internal();
  FirebaseSeederService._internal();
  factory FirebaseSeederService() => _instance;

  final FirebaseDatabaseService _firebaseDb = FirebaseDatabaseService();
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  // Expose the firebase database service for external access
  FirebaseDatabaseService get firebaseDb => _firebaseDb;

  // Seed all data to Firebase
  Future<bool> seedAllData({bool force = false}) async {
    try {
      print('DEBUG: Starting Firebase seeding process...');

      // 1. Seed scheduler users (AD, Assigner, Coach)
      await _seedSchedulerUsers();

      // 2. Seed officials using the exact data provided
      await _seedOfficials();

      print('DEBUG: Firebase seeding completed successfully');
      return true;
    } catch (e) {
      print('ERROR: Firebase seeding failed: $e');
      return false;
    }
  }

  // Seed scheduler users (AD, Assigner, Coach)
  Future<void> _seedSchedulerUsers() async {
    print('DEBUG: Seeding scheduler users...');

    final users = [
      {
        'email': 'ad@test.com',
        'firstName': 'Athletic',
        'lastName': 'Director',
        'userType': 'scheduler',
        'schedulerType': 'athletic_director',
        'teamName': 'Edwardsville Tigers',
        'schoolName': 'Edwardsville High School',
        'schoolAddress': '6161 Center Grove Rd, Edwardsville, IL 62025',
        'phone': '618-656-7600',
        'setupCompleted': true,
        'password': 'test123', // In production, this would be hashed
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'email': 'assigner@test.com',
        'firstName': 'Game',
        'lastName': 'Assigner',
        'userType': 'scheduler',
        'schedulerType': 'assigner',
        'teamName': 'Metro East Officials',
        'schoolName': 'Metro East Officials Association',
        'phone': '618-555-0100',
        'setupCompleted': true,
        'password': 'test123',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'email': 'coach@test.com',
        'firstName': 'Head',
        'lastName': 'Coach',
        'userType': 'scheduler',
        'schedulerType': 'coach',
        'teamName': 'Alton Redbirds',
        'schoolName': 'Alton High School',
        'schoolAddress': '4200 Humbert Rd, Alton, IL 62002',
        'phone': '618-474-2600',
        'setupCompleted': true,
        'password': 'test123',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }
    ];

    for (var userData in users) {
      final email = userData['email'] as String;
      final password = userData['password'] as String;
      
      try {
        // TEMPORARY: Skip Firebase Auth during rate limiting, create Firestore profiles only
        print('DEBUG: Creating Firestore profile only (skipping Auth during rate limiting): $email');
        final success = await _firebaseDb.saveUserProfile(email, userData);
        if (success) {
          print('DEBUG: ✅ Firestore user profile created for: $email');
        } else {
          print('ERROR: ❌ Failed to create Firestore profile for: $email');
        }
      } catch (e) {
        print('ERROR: ❌ Exception creating user $email: $e');
      }
    }
  }

  // Seed officials using the exact data provided by the user
  Future<void> _seedOfficials() async {
    print('DEBUG: Seeding officials using direct data...');

    // Direct data from user - exactly as provided
    final officialsData = [
      ['Certified', '8', 'Aldridge', 'Brandon', '2627 Columbia Lakes Drive Unit 2D', 'Columbia', '62236', '618-719-4373'],
      ['Registered', '3', 'Angleton', 'Darrell', '800 Alton St', 'Alton', '62002', '618-792-9995'],
      ['Recognized', '11', 'Baird', 'Robert', '1217 W Woodfield Dr', 'Alton', '62002', '618-401-4016'],
      ['Certified', '12', 'Barczewski', 'Paul', '414 E Park Ln.', 'Nashville', '62263', '618-314-5349'],
      ['Certified', '36', 'Belcher', 'Brian', 'PO Box 166', 'Coulterville', '62237', '618-967-5081'],
      ['Certified', '16', 'Bicanic', 'Louis', '4 Ridgefield Ct', 'Maryville', '62062', '618-973-9484'],
      ['Registered', '26', 'Bishop', 'David', 'P.O. Box 412', 'Greenfield', '62044', '217-370-2851'],
      ['Registered', '2', 'Blacharczyk', 'Matt', '17 Bourdelais Drive', 'Belleville', '62226', '618-830-4165'],
      ['Recognized', '8', 'Blakemore', 'Michael', 'PO Box 94', 'O\'Fallon', '62269', '618-363-4625'],
      ['Registered', '3', 'Boykin', 'Theatrice', '387 Sweetwater Lane', 'O\'Fallon', '62269', '314-749-8245'],
      ['Certified', '28', 'Broadway', 'James', '4502  Broadway Acres Dr.', 'Glen Carbon', '62034', '618-781-7110'],
      ['Registered', '2', 'Brown', 'Keyshawn', '168 Liberty Dr', 'Belleville', '62226', '618-509-7375'],
      ['Recognized', '4', 'Brunstein', 'Nick', '364 Jubaka Dr', 'Fairview Heights', '62208', '618-401-5301'],
      ['Certified', '30', 'Buckley', 'James', '2723 Bryden Ct.', 'Alton', '62002', '618-606-2217'],
      ['Certified', '19', 'Bundy', 'Ryan', '1405 Stonebrooke Drive', 'Edwardsville', '62025', '618-210-0257'],
      ['Certified', '41', 'Bussey', 'William', '12703 Meadowdale Dr', 'St. Louis', '63138', '314-406-8685'],
      ['Certified', '8', 'Carmack', 'Jay', '116 Brackett Street', 'Swansea', '62226', '618-541-0012'],
      ['Certified', '8', 'Carmack', 'Jeff', '112 Westview Drive', 'Freeburg', '62243', '618-580-1310'],
      ['Certified', '7', 'Carpenter', 'Don', '233 Cedar St', 'Eldred', '62027', '217-248-4489'],
      ['Certified', '44', 'Chapman', 'Ralph', '6563 State Rt 127', 'Pinckneyville', '62274', '618-923-0733'],
      ['Registered', '13', 'Clark', 'James', '3056 Indian Medows Lane', 'Edwardsville', '62025', '618-558-5095'],
      ['Certified', '6', 'Clymer', 'Roger', '144 N 1400 E Road', 'Nokomis', '62075', '618-409-1868'],
      ['Registered', '3', 'Colbert', 'Aiden', '920 Hamburg Ln', 'Millstadt', '62260', '618-606-1924'],
      ['Registered', '2', 'Colbert', 'Craig', '22 Rose Ct', 'Glen Carbon', '62034', '618-660-5455'],
      ['Certified', '14', 'Cole', 'Bobby', '119 Fox Creek Road', 'Belleville', '62223', '618-974-0035'],
      ['Recognized', '9', 'Cornell', 'Curtis', '912 Stone Creek Ln', 'Belleville', '62223', '314-306-0453'],
      ['Certified', '18', 'Cowan', 'Clint', '317 North Meadow Lane', 'Steeleville', '62288', '618-615-1079'],
      ['Registered', '21', 'Crain', 'Daniel', '721 N. Main St.', 'Breese', '62230', '618-550-8152'],
      ['Certified', '29', 'Curtis', 'Raymond', '609 Marian Street', 'Dupo', '62239', '618-477-0590'],
      ['Certified', '11', 'Dalman', 'Patrick', '218 Shoreline Dr Unit 3', 'O\'Fallon', '62269', '618-520-0440'],
      ['Certified', '24', 'Davis', 'Chad', 'Po  Box 133', 'Maryville', '62062', '618-799-3496'],
      ['Registered', '8', 'DeClue', 'Wayman', '440 Miranda Dr.', 'Dupo', '62239', '618-980-3368'],
      ['Registered', '3', 'Dederich', 'Peter', '1001 S. Wood St.', 'Staunton', '62088', '309-530-9920'],
      ['Registered', '3', 'Dintelmann', 'Paul', '112 Lake Forest Dr', 'Belleville', '62220', '619-415-3786'],
      ['Registered', '4', 'Dooley', 'Chad', '607 N Jackson St', 'Litchfield', '62056', '217-556-4096'],
      ['Recognized', '5', 'Dunevant', 'Keith', '405 Adams Drive', 'Waterloo', '62298', '618-340-8578'],
      ['Registered', '14', 'Dunnette', 'Brian', '2720 Stone Valley Drive', 'Maryville', '62062', '618-514-9897'],
      ['Certified', '26', 'Eaves', 'Michael', '2548 Stratford Ln.', 'Granite City', '62040', '618-830-5829'],
      ['Certified', '27', 'Ferguson', 'Eric', '701 Clinton St', 'Gillespie', '62033', '217-276-3314'],
      ['Registered', '3', 'Fox', 'Malcolm', '6 Clinton Hill Dr', 'Swansea', '62226', '314-240-6115'],
      ['Certified', '21', 'George', 'Louis', '106 West Cherry', 'Hartford', '62048', '618-789-6553'],
      ['Registered', '2', 'George', 'Peyton', '203 Arrowhead Dr', 'Troy', '62294', '618-960-1421'],
      ['Certified', '30', 'George', 'Ricky', '203 Arrowhead Dr.', 'Troy', '62294', '618-567-6862'],
      ['Certified', '10', 'Gerlach', 'Andy', '505 Ridge Ave.', 'Steeleville', '62288', '618-534-2429'],
      ['Certified', '29', 'Gray', 'Jason', '3405 Amber Meadows Court', 'Swansea', '62226', '618-550-8663'],
      ['Certified', '12', 'Greenfield', 'Beaux', '204 Wild Cherry Ln.', 'Swansea', '62226', '618-540-8911'],
      ['Certified', '12', 'Greenfield', 'Derek', '9 Josiah Ln.', 'Millstadt', '62260', '618-604-6944'],
      ['Certified', '51', 'Harre', 'Larry', '597 E. Fairview Ln.', 'Nashville', '62263', '618-555-0000'],
      ['Certified', '26', 'Harris', 'Jeffrey', '103 North 41st St.', 'Belleville', '62226', '618-979-8209'],
      ['Certified', '21', 'Harris', 'Nathan', '2551 London Lane', 'Belleville', '62221', '618-791-2945'],
      ['Registered', '3', 'Harshbarger', 'Andrew', '2309 Woodlawn Ave', 'Granite City', '62040', '618-910-7492'],
      ['Recognized', '5', 'Haywood', 'Kim', '218 Locust Dr.', 'Shiloh', '62269', '618-960-2627'],
      ['Certified', '7', 'Hennessey', 'James', '313 Sleeping Indian Dr.', 'Freeburg', '62243', '618-623-5759'],
      ['Registered', '2', 'Henry', 'Tim', '117 Rhinegarten Dr', 'Hazelwood', '63031', '618-558-4923'],
      ['Recognized', '9', 'Heyen', 'Matthew', '1615 N State St', 'Litchfield', '62056', '217-313-4421'],
      ['Certified', '32', 'Hinkamper', 'Roy', '14 Fox Trotter Ct', 'High Ridge', '63049', '314-606-8598'],
      ['Certified', '14', 'Holder', 'David', '805 Charles Court', 'Steeleville', '62288', '618-615-1663'],
      ['Certified', '43', 'Holshouser', 'Robert', '1083 Prestonwood Dr.', 'Edwardsville', '62025', '618-407-1824'],
      ['Registered', '4', 'Holtkamp', 'Jacob', '336 Lincolnshire Blvd', 'Belleville', '62221', '618-322-8966'],
      ['Registered', '4', 'Hudson', 'Lamont', '341 Frey Lane', 'Fairview Heights', '62208', '708-724-8642'],
      ['Certified', '22', 'Hughes', 'Ramonn', '748 North 40th St.', 'East St. Louis', '62205', '314-651-2010'],
      ['Certified', '11', 'Jackson', 'Brian', '1137 Hampshire Lane', 'Shiloh', '62221', '618-301-0975'],
      ['Certified', '20', 'Jenkins', 'Darren', '8825 Wendell Creek Dr.', 'St. Jacob', '62281', '618-977-9311'],
      ['Certified', '27', 'Johnson', 'Emric', '245 Americana Circle', 'Fairview Heights', '62208', '618-979-7221'],
      ['Recognized', '18', 'Kaiser', 'Joseph', '302 Bridle Ridge', 'Collinsville', '62234', '618-616-6632'],
      ['Certified', '15', 'Kamp', 'Jeffrey', '958 Auer Landing Rd', 'Golden Eagle', '62036', '618-467-6060'],
      ['Certified', '36', 'Kampwerth', 'Daniel', '900 Pioneer Ct.', 'Breese', '62230', '618-363-0685'],
      ['Certified', '47', 'Lang', 'Louis', '612 E. Main St.', 'Coffeen', '62017', '217-246-2549'],
      ['Certified', '25', 'Lashmett', 'Dan', '1834 Lakamp Rd', 'Roodhouse', '62082', '217-473-2046'],
      ['Registered', '3', 'Lentz', 'James', '3811 State Route 160', 'Highland', '62249', '618-444-1773'],
      ['Recognized', '9', 'Leonard', 'Bill', '249 SE 200 Ave', 'Carrollton', '62016', '618-946-2266'],
      ['Certified', '36', 'Levan', 'Scott', '72 Heatherway Dr', 'Wood River', '62095', '618-444-0256'],
      ['Certified', '29', 'Lewis', 'Willie', '1100 Summit Ave', 'East St. Louis', '62201', '618-407-5733'],
      ['Recognized', '11', 'Lutz', 'Michael', '1307 Allendale', 'Chester', '62233', '618-615-1194'],
      ['Registered', '8', 'McAnulty', 'William', '1123 Eagle LN', 'Grafton', '62037', '618-610-9344'],
      ['Registered', '2', 'McCracken', 'Shane', '1106 North Idler Lane', 'Greenville', '62246', '618-699-9063'],
      ['Recognized', '8', 'McKay', 'Geoffery', '1516 Gedern Drive', 'Columbia', '62236', '314-973-9561'],
      ['Registered', '7', 'Middleton', 'Timothy', '900 Ottawa Ct', 'Mascoutah', '62258', '850-758-7278'],
      ['Certified', '14', 'Modarelli', 'Michael', '7920 West A Streeet', 'Belleville', '62223', '314-322-9359'],
      ['Registered', '3', 'Morris', 'Ranesha', '5710 Cates Ave', 'Saint Louis', '63112', '314-458-4245'],
      ['Certified', '40', 'Morrisey', 'James', '106 Oakridge Estates Dr.', 'Glen Carbon', '62034', '618-444-0232'],
      ['Certified', '24', 'Mueller', 'Larry', '2745 Otten Rd', 'Millstadt', '62260', '618-660-9394'],
      ['Certified', '23', 'Murray', 'Johnny', '2 Madonna Ct', 'Belleville', '62223', '618-235-5196'],
      ['Certified', '10', 'Nichols', 'Kevin', '224 Centennial St', 'White Hall', '62092', '217-248-8745'],
      ['Certified', '16', 'Ohren', 'Blake', '115 Baneberry Dr.', 'Highland', '62249', '618-971-9037'],
      ['Registered', '4', 'Owens', 'Jacoy', '143 Perrottet Dr', 'Mascoutah', '62258', '580-301-2646'],
      ['Certified', '11', 'Pearce', 'Allan', '303 Quarry Street', 'Staunton', '62088', '847-217-0922'],
      ['Registered', '2', 'Phillips', 'Arthur', '1595 Paddock Dr.', 'Florissant', '63033', '402-981-5532'],
      ['Certified', '19', 'Phillips', 'Jacob', '510 Florence Avenue ', 'Dupo', '62239', '618-830-6378'],
      ['Certified', '32', 'Phillips', 'Michael', '4539 Little Rock Rd., Apt. K', 'St. Louis', '63128', '314-805-8381'],
      ['Registered', '3', 'Pizzo', 'Isaac', '618 N. Franklin St', 'Litchfield', '62056', '217-851-1890'],
      ['Recognized', '5', 'Powell', 'John', '629 Solomon St.', 'Chester', '62233', '815-641-6074'],
      ['Certified', '30', 'Purcell', 'Trent', '1110 Madison Dr.', 'Carlyle', '62231', '618-401-1950'],
      ['Certified', '17', 'Raney', 'Michael', '50 Cheshire Dr ', 'Belleville', '62223', '618-402-5717'],
      ['Certified', '21', 'Rathert', 'Charles', '3138 Bluff Rd', 'Edwardsville', '62025', '314-303-8044'],
      ['Certified', '13', 'Rathert', 'Joe', '3120 Bluff Road', 'Edwardsville', '62025', '555-555-5555'],
      ['Certified', '21', 'Reif', 'Timothy', '333 9th Street', 'Carrollton', '62016', '217-473-9321'],
      ['Certified', '16', 'Roberts', 'Nathan', '525 N Main St', 'White Hall', '62092', '217-473-2906'],
      ['Registered', '14', 'Roundtree', 'Shawn', '11 Jennifer Dr', 'Glen Carbon', '62034', '618-789-2451'],
      ['Registered', '6', 'Royer', 'Justin', '317 W South St', 'Mascoutah', '62258', '618-401-8671'],
      ['Registered', '2', 'Royer', 'Riley', '317 W South St.', 'Mascoutah', '62258', '618-406-4748'],
      ['Certified', '37', 'Schaaf', 'Donald', '1462 South Lake Drive', 'Carrollton', '62016', '618-535-6435'],
      ['Certified', '14', 'Schipper', 'Dennis', '2424 Persimmon Wood Dr', 'Belleville', '62221', '618-772-9909'],
      ['Recognized', '14', 'Schmitz', 'Jason', '85 Sunfish Dr.', 'Highland', '62249', '618-792-2923'],
      ['Registered', '5', 'Scroggins', 'Louie', '29 Scroggins Lane', 'Hillsboro', '62049', '217-556-0403'],
      ['Certified', '15', 'Seibert', 'Tracy', '9903 Old Lincoln Trail', 'Fairview Heights', '62208', '618-531-0029'],
      ['Certified', '27', 'Sheff', 'Ronald', '363 East Airline Dr.', 'East Alton', '62024', '618-610-7117'],
      ['Recognized', '12', 'Shofner', 'Alan', '1878 Franklin Hill RD', 'Batchtown', '62006', '618-535-9590'],
      ['Certified', '20', 'Silas', 'Andre', '520 Washington St.', 'Venice', '62090', '217-341-0597'],
      ['Registered', '10', 'Smail', 'Donovan', '500 W Fairground Avenue', 'Hillsboro', '62049', '217-820-1550'],
      ['Certified', '24', 'Speciale', 'Andrew', '5B Villa Ct.', 'Edwardsville', '62025', '314-587-9902'],
      ['Certified', '20', 'Stinemetz', 'Douglas', '616 W Bottom Ave.', 'Columbia', '62236', '618-719-6173'],
      ['Recognized', '4', 'Stuller', 'Nathan', '303 Collinsville Road', 'Troy', '62294', '618-304-4011'],
      ['Certified', '14', 'Swank', 'Shawn', '301 W Spruce', 'Gillespie', '62033', '217-556-5066'],
      ['Certified', '29', 'Thomas', 'Carl', '228 Springdale Dr', 'Belleville', '62223', '618-781-8225'],
      ['Certified', '31', 'Tolle', 'Richard', '511 N. Main', 'Witt', '62094', '217-556-9441'],
      ['Certified', '21', 'Trotter', 'Benjamin', '1228 Conrad Ln', 'O\'Fallon', '62269', '618-779-4372'],
      ['Certified', '26', 'Unverzagt', 'Jason', '307 N. 39 St', 'Belleville', '62226', '618-555-0000'],
      ['Certified', '11', 'Walters', 'Chris', '1211 Marshal Ct', 'O\'Fallon', '62269', '217-549-8844'],
      ['Certified', '26', 'Webster', 'Vincent', '2 Lakeshire Dr.', 'Fairview Hts.', '62208', '618-660-7107'],
      ['Certified', '6', 'Womack', 'Paul', '811 S Polk St.', 'Millstadt', '62260', '618-567-7609'],
      ['Recognized', '7', 'Wood', 'William', '2764 Staunton Road', 'Troy', '62294', '618-593-5617'],
      ['Certified', '17', 'Wooten', 'Edward', '801 Chancellor Dr', 'Edwardsville', '62025', '618-560-1502'],
    ];

    print('DEBUG: Processing ${officialsData.length} officials...');

    int successCount = 0;
    int errorCount = 0;

    for (int i = 0; i < officialsData.length; i++) {
      final officialRow = officialsData[i];

      try {
        // Extract data from row
        final certificationLevel = officialRow[0];
        final experienceYears = int.tryParse(officialRow[1]) ?? 0;
        final lastName = officialRow[2];
        final firstName = officialRow[3];
        final address = officialRow[4];
        final city = officialRow[5];
        final zipCode = officialRow[6];
        final phone = officialRow[7].isEmpty ? '618-555-0000' : officialRow[7];

        // Generate email from first 2 letters + lastname
        final email = '${firstName.toLowerCase().substring(0, firstName.length >= 2 ? 2 : 1)}${lastName.toLowerCase()}@test.com';

        final officialData = {
          'id': i + 1,
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'displayName': '${firstName[0]}. $lastName',
          'address': address,
          'city': city,
          'zipCode': zipCode,
          'phone': phone,
          'certificationLevel': certificationLevel,
          'experienceYears': experienceYears,
          'competitionLevels': 'Varsity', // All officials work Varsity level
          'userType': 'official',
          'password': 'test123', // All officials have same test password
          'isActive': true,
          'rating': 0.0,
          'gamesWorked': 0,
          'availability': 'available',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        // TEMPORARY: Skip Firebase Auth during rate limiting, create Firestore profiles only
        print('DEBUG: Creating Firestore profile only (skipping Auth during rate limiting): $email');
        final success = await _firebaseDb.saveOfficialProfile(email, officialData);
        if (success) {
          successCount++;
          if (i % 10 == 0) {
            print('DEBUG: Processed $i/${officialsData.length} officials...');
          }
        } else {
          errorCount++;
          print('ERROR: Failed to seed official profile: $email');
        }
        
        // Rate limit protection: delay between account creations
        if (i < officialsData.length - 1) { // Don't delay after last item
          await Future.delayed(Duration(milliseconds: 100)); // 100ms delay
        }
      } catch (e) {
        errorCount++;
        print('ERROR: Exception processing official ${i + 1}: $e');
      }
    }

    print('DEBUG: Officials seeding complete - Success: $successCount, Errors: $errorCount');
  }

  // Helper method to create Firebase Auth account with retry logic for rate limits
  Future<dynamic> _createAuthAccountWithRetry(String email, String password, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final authResult = await _firebaseAuth.createUserWithEmailAndPassword(email, password);
      
      if (authResult.success) {
        return authResult; // Success
      }
      
      // Check if it's a rate limit error
      if (authResult.error != null && 
          (authResult.error!.contains('Too many requests') || 
           authResult.error!.contains('unusual activity'))) {
        
        if (attempt < maxRetries) {
          final delaySeconds = attempt * 2; // Exponential backoff: 2s, 4s, 6s
          print('DEBUG: Rate limited, retrying in ${delaySeconds}s (attempt $attempt/$maxRetries)');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        } else {
          print('ERROR: Rate limit exceeded after $maxRetries attempts for: $email');
        }
      }
      
      return authResult; // Return the error result
    }
  }

  // Clear officials collection (for compatibility with existing code)
  Future<bool> clearOfficials() async {
    try {
      print('DEBUG: Clearing officials collection...');
      final collection = FirebaseFirestore.instance.collection('officials');
      final snapshot = await collection.get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      print('DEBUG: Cleared ${snapshot.docs.length} officials');
      return true;
    } catch (e) {
      print('ERROR: Failed to clear officials: $e');
      return false;
    }
  }
}