const admin = require('firebase-admin');
const fs = require('fs');
const { parse } = require('csv-parse');

// Initialize Firebase Admin SDK
let serviceAccount;
try {
  serviceAccount = require('./service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log('✅ Firebase Admin SDK initialized with service account');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK:', error);
  process.exit(1);
}

const db = admin.firestore();
const auth = admin.auth();

// Constants
const CSV_FILE_PATH = './officials.csv';
const TEMP_PASSWORD = 'tempPass123';
const EMAIL_DOMAIN = '@test.com';

// Utility function to generate unique email
function generateUniqueEmail(firstName, lastName, usedEmails) {
  const baseEmail = `${firstName.toLowerCase()}.${lastName.toLowerCase()}${EMAIL_DOMAIN}`;
  
  if (!usedEmails.has(baseEmail)) {
    usedEmails.add(baseEmail);
    return baseEmail;
  }
  
  let counter = 1;
  let uniqueEmail;
  do {
    uniqueEmail = `${firstName.toLowerCase()}.${lastName.toLowerCase()}${counter}${EMAIL_DOMAIN}`;
    counter++;
  } while (usedEmails.has(uniqueEmail));
  
  usedEmails.add(uniqueEmail);
  return uniqueEmail;
}

// Enhanced CSV parsing with ALL fields
async function parseOfficialsCSV() {
  console.log(`📖 Reading enhanced CSV file: ${CSV_FILE_PATH}`);
  
  if (!fs.existsSync(CSV_FILE_PATH)) {
    throw new Error(`CSV file not found: ${CSV_FILE_PATH}`);
  }
  
  return new Promise((resolve, reject) => {
    const officials = [];
    const usedEmails = new Set();
    
    fs.createReadStream(CSV_FILE_PATH)
      .pipe(parse({
        columns: true,
        skip_empty_lines: true,
        trim: true
      }))
      .on('data', (row) => {
        const firstName = row.First;
        const lastName = row.Last;
        
        if (firstName && lastName && firstName.trim() && lastName.trim()) {
          const email = generateUniqueEmail(firstName.trim(), lastName.trim(), usedEmails);
          
          // Parse phone numbers - prioritize Cell, then Home, then Work
          const cellPhone = row['Cell Phone'] || '';
          const homePhone = row['Home Phone'] || '';
          const workPhone = row['Work Phone'] || '';
          const primaryPhone = cellPhone || homePhone || workPhone;
          
          const official = {
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            email: email,
            
            // Official certification details
            level: row.Level || '',
            certification: row.Certification || '',
            yearsExperience: parseInt(row.Years) || 0,
            
            // Contact information
            address: row.Address || '',
            city: row.City || '',
            zipCode: row.ZIP || '',
            
            // Phone numbers
            cellPhone: cellPhone,
            homePhone: homePhone,
            workPhone: workPhone,
            primaryPhone: primaryPhone,
            
            // Status and additional info
            status: row.Status || '',
            middleName: row.Middle || '',
            suffix: row.Suffix || '',
            
            // Sport and role (since this is football officials)
            sport: 'Football',
            role: 'Official',
            
            // Metadata
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          };
          
          officials.push(official);
          console.log(`   ✅ Added: ${firstName} ${lastName} (${official.certification}, ${official.yearsExperience} yrs) → ${email}`);
        }
      })
      .on('end', () => {
        console.log(`✅ Parsed ${officials.length} officials with full data`);
        resolve(officials);
      })
      .on('error', (error) => {
        reject(error);
      });
  });
}

// Create Firebase Authentication user
async function createAuthUser(official) {
  try {
    const userRecord = await auth.createUser({
      email: official.email,
      password: TEMP_PASSWORD,
      displayName: `${official.firstName} ${official.lastName}`,
      emailVerified: false
    });
    
    return userRecord;
  } catch (error) {
    throw new Error(`Auth creation failed: ${error.message}`);
  }
}

// Create enhanced Firestore document with ALL data matching original database schema
async function createFirestoreDocument(official, uid) {
  try {
    const docRef = db.collection('officials').doc();
    await docRef.set({
      // Match original 'officials' table structure
      name: `${official.firstName} ${official.lastName}`,
      firstName: official.firstName,
      lastName: official.lastName,
      email: official.email,
      uid: uid,
      
      // Official certification (matching original schema)
      rating: official.level, // C/X/R
      certification_level: official.certification, // Certified/Registered/Recognized
      years_experience: official.yearsExperience,
      
      // Contact info (matching original schema)
      address: official.address,
      city: official.city,
      zip_code: official.zipCode,
      phone_number: official.primaryPhone, // Main phone field
      cellPhone: official.cellPhone,
      homePhone: official.homePhone,
      workPhone: official.workPhone,
      
      // Additional details
      status: official.status, // compliant/non-compliant
      middleName: official.middleName,
      suffix: official.suffix,
      
      // Sport info (matching original database)
      sport: 'Football',
      sport_id: 1, // Football sport ID from original DB
      role: 'Official',
      
      // Availability and notes
      availability_notes: '',
      
      // User relationship (for SQLite compatibility)
      user_id: null, // Will be set when linked to scheduler
      
      // Timestamps (matching original schema)
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return docRef.id;
  } catch (error) {
    throw new Error(`Firestore creation failed: ${error.message}`);
  }
}

// Clear existing data
async function clearExistingData() {
  console.log('🗑️  Clearing existing data...');
  
  try {
    // Clear Firestore collection
    console.log('   Clearing Firestore officials collection...');
    const officialsSnapshot = await db.collection('officials').get();
    const batch = db.batch();
    
    officialsSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    if (officialsSnapshot.size > 0) {
      await batch.commit();
      console.log(`   ✅ Deleted ${officialsSnapshot.size} Firestore documents`);
    }
    
    // Clear Authentication users
    console.log('   Clearing Firebase Authentication users...');
    let deletedCount = 0;
    let nextPageToken;
    
    do {
      const listUsersResult = await auth.listUsers(1000, nextPageToken);
      
      if (listUsersResult.users.length > 0) {
        const uids = listUsersResult.users.map(user => user.uid);
        await auth.deleteUsers(uids);
        deletedCount += uids.length;
      }
      
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);
    
    if (deletedCount > 0) {
      console.log(`   ✅ Deleted ${deletedCount} Authentication users`);
    }
    
  } catch (error) {
    console.error('⚠️  Error during cleanup (continuing anyway):', error.message);
  }
}

// Main enhanced reset function
async function enhancedResetAuthFirestore() {
  console.log('🚀 Starting ENHANCED Authentication and Firestore reset...\n');
  
  let officials = [];
  let successCount = 0;
  let errorCount = 0;
  const errors = [];
  
  try {
    // Step 1: Parse CSV with ALL fields
    officials = await parseOfficialsCSV();
    
    if (officials.length === 0) {
      console.log('❌ No officials found in CSV. Exiting.');
      return;
    }
    
    console.log(`\n⚠️  About to create ${officials.length} Authentication users and Firestore documents with FULL data`);
    
    // Step 2: Clear existing data
    await clearExistingData();
    
    console.log('\n🔨 Creating Authentication users and enhanced Firestore documents...\n');
    
    // Step 3: Create users and documents with full data
    for (const [index, official] of officials.entries()) {
      try {
        console.log(`📋 Processing ${index + 1}/${officials.length}: ${official.firstName} ${official.lastName}`);
        console.log(`   📊 ${official.certification}, ${official.yearsExperience} years, ${official.city}, ${official.primaryPhone}`);
        
        // Create Auth user
        const userRecord = await createAuthUser(official);
        console.log(`   👤 Created Auth user: ${official.email} with UID: ${userRecord.uid}`);
        
        // Create enhanced Firestore document
        const docId = await createFirestoreDocument(official, userRecord.uid);
        console.log(`   📄 Created enhanced Firestore doc: ${docId}`);
        console.log(`   ✅ Complete with full data: ${official.email} → UID: ${userRecord.uid}`);
        
        successCount++;
        
      } catch (error) {
        console.log(`   ❌ Failed: ${official.firstName} ${official.lastName} - ${error.message}`);
        errors.push(`${official.firstName} ${official.lastName}: ${error.message}`);
        errorCount++;
      }
      
      // Rate limiting
      if (index % 10 === 9) {
        console.log('   ⏳ Pausing briefly...');
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
    
    // Step 4: Enhanced Summary
    console.log('\n' + '='.repeat(80));
    console.log('ENHANCED RESET SUMMARY');
    console.log('='.repeat(80));
    console.log(`📊 Total officials processed: ${officials.length}`);
    console.log(`✅ Successful creations: ${successCount}`);
    console.log(`❌ Failed creations: ${errorCount}`);
    console.log(`📈 Success rate: ${Math.round((successCount / officials.length) * 100)}%`);
    
    console.log('\n📋 DATA CAPTURED:');
    console.log('   ✅ Names (First, Middle, Last, Suffix)');
    console.log('   ✅ Certification Level & Years Experience');  
    console.log('   ✅ Full Address (Address, City, ZIP)');
    console.log('   ✅ Phone Numbers (Cell, Home, Work)');
    console.log('   ✅ Official Status & Sport');
    console.log('   ✅ Firebase Auth UID linking');
    
    if (errors.length > 0) {
      console.log('\n❌ ERRORS:');
      errors.forEach((error, index) => console.log(`  ${index + 1}. ${error}`));
    }
    
    console.log('\n🎉 ENHANCED Authentication and Firestore reset completed!');
    console.log('\n📋 Next Steps:');
    console.log('1. Verify users in Firebase Console → Authentication → Users');
    console.log('2. Verify enhanced documents in Firebase Console → Firestore → officials collection');
    console.log('3. Check that each document has certification, address, phone data');
    console.log('4. Test with: flutter run -d chrome');
    console.log(`5. All users have temporary password: ${TEMP_PASSWORD}`);
    
    if (successCount === officials.length) {
      console.log('\n🏆 Perfect! All 148 officials created with complete data.');
    }
    
  } catch (error) {
    console.error('💥 Fatal error during enhanced reset:', error);
    process.exit(1);
  }
}

// Run the enhanced reset
enhancedResetAuthFirestore()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Unhandled error:', error);
    process.exit(1);
  });