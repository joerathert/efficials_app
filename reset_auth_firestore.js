const admin = require('firebase-admin');
const fs = require('fs');
const { parse } = require('csv-parse');
const path = require('path');

// Initialize Firebase Admin SDK
let serviceAccount;
try {
  // Try to load service account from file
  serviceAccount = require('./service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log('✅ Firebase Admin SDK initialized with service account');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK:', error);
  console.log('\n🔧 Setup Instructions:');
  console.log('1. Go to Firebase Console → Project Settings → Service Accounts');
  console.log('2. Click "Generate New Private Key"');
  console.log('3. Save the JSON file as "service-account.json" in this directory');
  console.log('4. Re-run the script');
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
  
  // Handle duplicates by appending numbers
  let counter = 1;
  let uniqueEmail;
  do {
    uniqueEmail = `${firstName.toLowerCase()}.${lastName.toLowerCase()}${counter}${EMAIL_DOMAIN}`;
    counter++;
  } while (usedEmails.has(uniqueEmail));
  
  usedEmails.add(uniqueEmail);
  return uniqueEmail;
}

// Parse CSV file
async function parseOfficialsCSV() {
  console.log(`📖 Reading CSV file: ${CSV_FILE_PATH}`);
  
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
        // Handle various column name formats
        const firstName = row.firstName || row.first_name || row.FirstName || row.First;
        const lastName = row.lastName || row.last_name || row.LastName || row.Last;
        
        if (firstName && lastName && firstName.trim() && lastName.trim()) {
          const email = generateUniqueEmail(firstName.trim(), lastName.trim(), usedEmails);
          officials.push({
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            email: email
          });
          console.log(`   ✅ Added: ${firstName.trim()} ${lastName.trim()} → ${email}`);
        } else {
          console.log(`   ⚠️  Skipping row - missing names: First="${firstName || 'missing'}", Last="${lastName || 'missing'}"`);
        }
      })
      .on('end', () => {
        console.log(`✅ Parsed ${officials.length} officials from CSV`);
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

// Create Firestore document
async function createFirestoreDocument(official, uid) {
  try {
    const docRef = db.collection('officials').doc();
    await docRef.set({
      firstName: official.firstName,
      lastName: official.lastName,
      email: official.email,
      uid: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return docRef.id;
  } catch (error) {
    throw new Error(`Firestore creation failed: ${error.message}`);
  }
}

// Clear existing data (optional - be careful!)
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
    } else {
      console.log('   ℹ️  No Firestore documents to delete');
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
    } else {
      console.log('   ℹ️  No Authentication users to delete');
    }
    
  } catch (error) {
    console.error('⚠️  Error during cleanup (continuing anyway):', error.message);
  }
}

// Main reset function
async function resetAuthFirestore() {
  console.log('🚀 Starting Authentication and Firestore reset...\n');
  
  let officials = [];
  let successCount = 0;
  let errorCount = 0;
  const errors = [];
  
  try {
    // Step 1: Parse CSV
    officials = await parseOfficialsCSV();
    
    if (officials.length === 0) {
      console.log('❌ No officials found in CSV. Exiting.');
      return;
    }
    
    // Step 2: Ask for confirmation before clearing (optional safety check)
    console.log(`\n⚠️  About to create ${officials.length} Authentication users and Firestore documents`);
    console.log('⚠️  This will clear existing data. Continue? (This script assumes you want to reset)');
    
    // Step 3: Clear existing data
    await clearExistingData();
    
    console.log('\n🔨 Creating Authentication users and Firestore documents...\n');
    
    // Step 4: Create users and documents
    for (const [index, official] of officials.entries()) {
      try {
        console.log(`📋 Processing ${index + 1}/${officials.length}: ${official.firstName} ${official.lastName}`);
        
        // Create Auth user
        const userRecord = await createAuthUser(official);
        console.log(`   👤 Created Auth user: ${official.email} with UID: ${userRecord.uid}`);
        
        // Create Firestore document
        const docId = await createFirestoreDocument(official, userRecord.uid);
        console.log(`   📄 Created Firestore doc: ${docId}`);
        
        console.log(`   ✅ Complete: ${official.email} → UID: ${userRecord.uid}`);
        successCount++;
        
      } catch (error) {
        console.log(`   ❌ Failed: ${official.firstName} ${official.lastName} - ${error.message}`);
        errors.push(`${official.firstName} ${official.lastName}: ${error.message}`);
        errorCount++;
      }
      
      // Add small delay to avoid rate limits
      if (index % 10 === 9) {
        console.log('   ⏳ Pausing briefly to avoid rate limits...');
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
    
    // Step 5: Summary
    console.log('\n' + '='.repeat(70));
    console.log('RESET SUMMARY');
    console.log('='.repeat(70));
    console.log(`📊 Total officials processed: ${officials.length}`);
    console.log(`✅ Successful creations: ${successCount}`);
    console.log(`❌ Failed creations: ${errorCount}`);
    console.log(`📈 Success rate: ${Math.round((successCount / officials.length) * 100)}%`);
    
    if (errors.length > 0) {
      console.log('\n❌ ERRORS:');
      errors.forEach((error, index) => console.log(`  ${index + 1}. ${error}`));
    }
    
    console.log('\n🎉 Authentication and Firestore reset completed!');
    console.log('\n📋 Next Steps:');
    console.log('1. Verify users in Firebase Console → Authentication → Users');
    console.log('2. Verify documents in Firebase Console → Firestore → officials collection');
    console.log('3. Test with: flutter run -d chrome');
    console.log(`4. All users have temporary password: ${TEMP_PASSWORD}`);
    
    if (successCount === officials.length) {
      console.log('\n🏆 Perfect! All officials created successfully.');
    }
    
  } catch (error) {
    console.error('💥 Fatal error during reset:', error);
    process.exit(1);
  }
}

// Handle process termination gracefully
process.on('SIGINT', () => {
  console.log('\n\n🛑 Process interrupted by user');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n\n🛑 Process terminated');
  process.exit(0);
});

// Run the reset
resetAuthFirestore()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Unhandled error:', error);
    process.exit(1);
  });