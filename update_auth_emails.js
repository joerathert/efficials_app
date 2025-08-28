const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

async function updateAuthEmails() {
  console.log('Starting Firebase Auth email updates...\n');
  
  try {
    // Fetch all officials from Firestore
    console.log('Fetching officials from Firestore collection...');
    const officialsSnapshot = await db.collection('officials').get();
    
    if (officialsSnapshot.empty) {
      console.log('No officials found in Firestore collection.');
      return;
    }

    const emailMappings = new Map();
    
    // Build mapping of UIDs to new emails
    officialsSnapshot.forEach(doc => {
      const data = doc.data();
      const { firstName, lastName, uid } = data;
      
      if (firstName && lastName) {
        // Generate new email format: first two letters of firstName + lastName @ test.com
        const newEmail = `${firstName.substring(0, 2).toLowerCase()}${lastName.toLowerCase()}@test.com`;
        
        // Use uid field if present, otherwise use doc ID
        const userUid = uid || doc.id;
        emailMappings.set(userUid, {
          newEmail,
          firstName,
          lastName,
          docId: doc.id
        });
      }
    });

    console.log(`Found ${emailMappings.size} officials to process.\n`);

    let successCount = 0;
    let errorCount = 0;
    const errors = [];

    // Process each user
    for (const [uid, userData] of emailMappings) {
      try {
        console.log(`Processing ${userData.firstName} ${userData.lastName} (UID: ${uid})...`);
        
        // Check if user exists in Auth
        let userRecord;
        try {
          userRecord = await auth.getUser(uid);
        } catch (getUserError) {
          console.log(`  ❌ User not found in Auth: ${getUserError.message}`);
          errorCount++;
          errors.push(`User ${uid} (${userData.firstName} ${userData.lastName}) not found in Auth`);
          continue;
        }

        const currentEmail = userRecord.email;
        const newEmail = userData.newEmail;

        if (currentEmail === newEmail) {
          console.log(`  ✅ Email already correct: ${newEmail}`);
          successCount++;
          continue;
        }

        // Update user's email
        await auth.updateUser(uid, {
          email: newEmail,
        });

        console.log(`  ✅ Updated: ${currentEmail} → ${newEmail}`);
        successCount++;

      } catch (error) {
        console.log(`  ❌ Failed to update ${userData.firstName} ${userData.lastName}: ${error.message}`);
        errorCount++;
        errors.push(`${userData.firstName} ${userData.lastName} (${uid}): ${error.message}`);
      }
    }

    // Print summary
    console.log('\n' + '='.repeat(50));
    console.log('UPDATE SUMMARY');
    console.log('='.repeat(50));
    console.log(`✅ Successful updates: ${successCount}`);
    console.log(`❌ Failed updates: ${errorCount}`);
    console.log(`📊 Total processed: ${emailMappings.size}`);

    if (errors.length > 0) {
      console.log('\nERRORS:');
      errors.forEach(error => console.log(`  • ${error}`));
    }

    console.log('\n🎉 Email update process completed!');

  } catch (error) {
    console.error('Fatal error during email updates:', error);
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

// Run the update
updateAuthEmails()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('Unhandled error:', error);
    process.exit(1);
  });