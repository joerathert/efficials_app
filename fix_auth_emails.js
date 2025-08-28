const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

// CSV parsing utility
function parseCSV(csvContent) {
  const lines = csvContent.trim().split('\n');
  const headers = lines[0].split(',').map(h => h.trim().replace(/"/g, ''));
  const data = [];
  
  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(',').map(v => v.trim().replace(/"/g, ''));
    const row = {};
    headers.forEach((header, index) => {
      row[header] = values[index] || '';
    });
    data.push(row);
  }
  
  return data;
}

// Generate expected email format
function generateNewEmail(firstName, lastName) {
  return `${firstName.substring(0, 2).toLowerCase()}${lastName.toLowerCase()}@test.com`;
}

// Export all Authentication users to CSV
async function exportAuthUsersToCSV() {
  console.log('📤 Exporting Firebase Authentication users to CSV...');
  
  try {
    const allUsers = [];
    let nextPageToken;
    
    do {
      const listUsersResult = await auth.listUsers(1000, nextPageToken);
      allUsers.push(...listUsersResult.users);
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);
    
    const csvContent = [
      'uid,email,emailVerified,disabled,creationTime',
      ...allUsers.map(user => 
        `"${user.uid}","${user.email || ''}","${user.emailVerified}","${user.disabled}","${user.metadata.creationTime}"`
      )
    ].join('\n');
    
    fs.writeFileSync('./auth_users_export.csv', csvContent);
    console.log(`✅ Exported ${allUsers.length} users to auth_users_export.csv`);
    
    return allUsers;
  } catch (error) {
    console.error('❌ Failed to export Auth users:', error);
    throw error;
  }
}

// Read CSV file (either exported or provided)
function readEmailUidMapping(csvPath = './auth_users_export.csv') {
  console.log(`📖 Reading email-to-UID mapping from ${csvPath}...`);
  
  if (!fs.existsSync(csvPath)) {
    throw new Error(`CSV file not found: ${csvPath}`);
  }
  
  const csvContent = fs.readFileSync(csvPath, 'utf8');
  const users = parseCSV(csvContent);
  
  const emailToUid = new Map();
  const emailDomains = new Map();
  let validUsers = 0;
  let invalidUsers = 0;
  
  users.forEach(user => {
    if (user.email && user.uid) {
      emailToUid.set(user.email.toLowerCase(), user.uid);
      
      // Track email domains for analysis
      const domain = user.email.split('@')[1];
      if (domain) {
        emailDomains.set(domain, (emailDomains.get(domain) || 0) + 1);
      }
      validUsers++;
    } else {
      invalidUsers++;
    }
  });
  
  console.log(`✅ Loaded ${emailToUid.size} email-to-UID mappings`);
  console.log(`📊 Valid users: ${validUsers}, Invalid: ${invalidUsers}`);
  
  // Show top email domains
  const topDomains = Array.from(emailDomains.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);
  console.log(`🏆 Top email domains: ${topDomains.map(([domain, count]) => `${domain}(${count})`).join(', ')}`);
  
  return emailToUid;
}

// Normalize email for better matching
function normalizeEmail(email) {
  return email.toLowerCase().replace(/\./g, '').replace(/\+.*@/, '@');
}

// Normalize name for better matching
function normalizeName(name) {
  return name.toLowerCase().replace(/[^a-z]/g, '');
}

// Enhanced email matching with detailed logging and doc ID fallback
function findMatchingAuthEmail(officialName, emailToUidMap, docId = null) {
  const { firstName, lastName } = officialName;
  const normalizedFirstName = normalizeName(firstName);
  const normalizedLastName = normalizeName(lastName);
  
  console.log(`    🔍 Searching for: ${firstName} ${lastName}`);
  console.log(`    📧 Normalized: ${normalizedFirstName} ${normalizedLastName}`);
  if (docId) {
    console.log(`    📄 Doc ID: ${docId}`);
  }
  
  // Show first few emails being checked in debug mode
  const DEBUG_MODE = process.env.DEBUG === 'true' || process.argv.includes('--debug');
  if (DEBUG_MODE) {
    console.log(`    📝 Sample emails to check:`);
    let sampleCount = 0;
    for (const [email] of emailToUidMap) {
      if (sampleCount < 3) {
        console.log(`       ${email}`);
        sampleCount++;
      } else {
        break;
      }
    }
  }
  
  // Create comprehensive search patterns
  const searchPatterns = [
    // Exact patterns with numbers/prefixes
    { pattern: new RegExp(`^\\d*${normalizedFirstName}${normalizedLastName}@`, 'i'), name: 'Number+FirstLast' },
    { pattern: new RegExp(`^\\d*${normalizedFirstName}\\.${normalizedLastName}@`, 'i'), name: 'Number+First.Last' },
    { pattern: new RegExp(`^\\d*${normalizedFirstName}_${normalizedLastName}@`, 'i'), name: 'Number+First_Last' },
    
    // Standard patterns
    { pattern: new RegExp(`^${normalizedFirstName}\\.${normalizedLastName}@`, 'i'), name: 'First.Last' },
    { pattern: new RegExp(`^${normalizedFirstName}_${normalizedLastName}@`, 'i'), name: 'First_Last' },
    { pattern: new RegExp(`^${normalizedFirstName}${normalizedLastName}@`, 'i'), name: 'FirstLast' },
    
    // First initial patterns
    { pattern: new RegExp(`^${normalizedFirstName.charAt(0)}${normalizedLastName}@`, 'i'), name: 'F+Last' },
    { pattern: new RegExp(`^${normalizedFirstName.charAt(0)}\\.${normalizedLastName}@`, 'i'), name: 'F.Last' },
    { pattern: new RegExp(`^${normalizedFirstName.charAt(0)}_${normalizedLastName}@`, 'i'), name: 'F_Last' },
    
    // Last initial patterns
    { pattern: new RegExp(`^${normalizedFirstName}${normalizedLastName.charAt(0)}@`, 'i'), name: 'First+L' },
    { pattern: new RegExp(`^${normalizedFirstName}\\.${normalizedLastName.charAt(0)}@`, 'i'), name: 'First.L' },
    
    // Reversed patterns
    { pattern: new RegExp(`^${normalizedLastName}${normalizedFirstName}@`, 'i'), name: 'LastFirst' },
    { pattern: new RegExp(`^${normalizedLastName}\\.${normalizedFirstName}@`, 'i'), name: 'Last.First' },
    
    // Broader fuzzy matching
    { pattern: new RegExp(`${normalizedFirstName}.*${normalizedLastName}`, 'i'), name: 'Contains First+Last' },
    { pattern: new RegExp(`${normalizedLastName}.*${normalizedFirstName}`, 'i'), name: 'Contains Last+First' }
  ];
  
  // Phase 1: Standard name-based matching
  let attemptCount = 0;
  for (const [email, uid] of emailToUidMap) {
    attemptCount++;
    const normalizedEmail = normalizeEmail(email);
    
    for (const { pattern, name } of searchPatterns) {
      if (pattern.test(normalizedEmail)) {
        console.log(`    ✅ MATCH FOUND (${name}): ${email} → UID: ${uid}`);
        return { email, uid, matchType: name };
      }
    }
  }
  
  console.log(`    ⚠️ No name-based match found after checking ${attemptCount} emails`);
  
  // Phase 2: Doc ID fallback matching
  if (docId) {
    console.log(`    🔄 Trying Doc ID fallback matching...`);
    
    // Normalize doc ID for matching
    const normalizedDocId = normalizeEmail(docId);
    console.log(`    📄 Normalized Doc ID: ${normalizedDocId}`);
    
    // Extract potential username from doc ID
    let docIdUsername = '';
    if (docId.includes('@')) {
      docIdUsername = docId.split('@')[0].toLowerCase();
    } else {
      docIdUsername = normalizedDocId;
    }
    
    console.log(`    👤 Doc ID username: ${docIdUsername}`);
    
    // Check if doc ID contains the normalized names
    const docIdContainsNames = docIdUsername.includes(normalizedFirstName) && docIdUsername.includes(normalizedLastName);
    
    if (docIdContainsNames) {
      console.log(`    ✅ Doc ID contains both names, searching Auth emails...`);
      
      // Search for Auth emails that match the doc ID pattern
      for (const [email, uid] of emailToUidMap) {
        const emailUsername = email.split('@')[0].toLowerCase();
        const normalizedEmailUsername = normalizeEmail(emailUsername + '@dummy.com').split('@')[0];
        
        // Check various matching patterns for doc ID
        const docIdPatterns = [
          // Exact match
          emailUsername === docIdUsername,
          normalizedEmailUsername === docIdUsername,
          // Doc ID is a substring of email username
          emailUsername.includes(docIdUsername),
          normalizedEmailUsername.includes(docIdUsername),
          // Email username is a substring of doc ID
          docIdUsername.includes(emailUsername),
          docIdUsername.includes(normalizedEmailUsername),
          // Fuzzy matching: both contain the core names
          emailUsername.includes(normalizedFirstName) && emailUsername.includes(normalizedLastName) && docIdUsername.includes(normalizedFirstName) && docIdUsername.includes(normalizedLastName)
        ];
        
        for (let i = 0; i < docIdPatterns.length; i++) {
          if (docIdPatterns[i]) {
            const matchTypes = ['Exact DocID', 'Normalized DocID', 'Email Contains DocID', 'Normalized Email Contains DocID', 'DocID Contains Email', 'DocID Contains Normalized Email', 'Both Contain Names'];
            console.log(`    ✅ MATCH FOUND (Doc ID Fallback - ${matchTypes[i]}): ${email} → UID: ${uid}`);
            console.log(`    🔗 DocID: ${docIdUsername} ↔ Email: ${emailUsername}`);
            return { email, uid, matchType: `Doc ID Fallback - ${matchTypes[i]}` };
          }
        }
      }
      
      console.log(`    ❌ No Doc ID fallback match found despite names in doc ID`);
    } else {
      console.log(`    ⚠️ Doc ID doesn't contain both names, skipping Doc ID fallback`);
    }
  }
  
  console.log(`    ❌ No match found after all attempts`);
  console.log(`    📝 Tried ${searchPatterns.length} name patterns + Doc ID fallback`);
  
  return null;
}

async function fixAuthEmails() {
  console.log('🚀 Starting Firebase Auth email fixes...\n');
  
  // Debug mode for detailed matching logs
  const DEBUG_MODE = process.env.DEBUG === 'true' || process.argv.includes('--debug');
  
  let emailToUidMap;
  let authUsers;
  
  try {
    // Step 1: Try to read existing CSV, or export if not found
    try {
      emailToUidMap = readEmailUidMapping('./auth_users_export.csv');
    } catch (error) {
      console.log('📤 CSV not found, exporting Auth users first...');
      authUsers = await exportAuthUsersToCSV();
      emailToUidMap = readEmailUidMapping('./auth_users_export.csv');
    }
    
    // Step 2: Fetch all officials from Firestore
    console.log('\n📋 Fetching officials from Firestore collection...');
    const officialsSnapshot = await db.collection('officials').get();
    
    if (officialsSnapshot.empty) {
      console.log('❌ No officials found in Firestore collection.');
      return;
    }
    
    const officialsCount = officialsSnapshot.size;
    const authUsersCount = emailToUidMap.size;
    
    console.log(`✅ Found ${officialsCount} officials in Firestore`);
    console.log(`📊 Found ${authUsersCount} Authentication users\n`);
    
    // Warn about user count mismatches
    if (authUsersCount < officialsCount) {
      const difference = officialsCount - authUsersCount;
      console.log('⚠️ ' + '='.repeat(60));
      console.log('⚠️  WARNING: USER COUNT MISMATCH');
      console.log('⚠️ ' + '='.repeat(60));
      console.log(`⚠️  Firestore officials: ${officialsCount}`);
      console.log(`⚠️  Authentication users: ${authUsersCount}`);
      console.log(`⚠️  Missing Auth accounts: ${difference}`);
      console.log('⚠️ ');
      console.log('⚠️  RECOMMENDATION: Create Firebase Auth accounts for missing officials');
      console.log('⚠️  or some officials may not get matched to Auth users.');
      console.log('⚠️ ' + '='.repeat(60) + '\n');
    } else if (authUsersCount > officialsCount) {
      const difference = authUsersCount - officialsCount;
      console.log(`ℹ️  Note: You have ${difference} more Auth users than officials. Some Auth accounts may not correspond to officials.\n`);
    } else {
      console.log(`✅ Perfect match: ${officialsCount} officials = ${authUsersCount} Auth users\n`);
    }
    
    // Step 3: Process each official
    let uidAddedCount = 0;
    let emailUpdatedCount = 0;
    let skippedCount = 0;
    let nameMatchCount = 0;
    let docIdFallbackMatchCount = 0;
    const errors = [];
    const matchTypes = new Map();
    
    console.log('🔄 Processing officials...\n');
    
    for (const doc of officialsSnapshot.docs) {
      const data = doc.data();
      const { firstName, lastName, email: currentFirestoreEmail } = data;
      
      if (!firstName || !lastName) {
        console.log(`⚠️  Skipping document ${doc.id}: Missing firstName or lastName`);
        skippedCount++;
        continue;
      }
      
      console.log(`\n👤 Processing: ${firstName} ${lastName} (Doc ID: ${doc.id})`);
      
      // Debug mode: show current Firestore email
      if (DEBUG_MODE && currentFirestoreEmail) {
        console.log(`  📛 Current Firestore email: ${currentFirestoreEmail}`);
      }
      
      try {
        let authMatch = null;
        let currentUid = data.uid;
        
        // Check if UID already exists
        if (currentUid) {
          console.log(`  ✅ UID already exists: ${currentUid}`);
        } else {
          // Find matching Auth user (with doc ID fallback)
          authMatch = findMatchingAuthEmail({ firstName, lastName }, emailToUidMap, doc.id);
          
          if (!authMatch) {
            console.log(`  ❌ No matching Auth user found`);
            errors.push(`${firstName} ${lastName}: No matching Auth user found`);
            skippedCount++;
            continue;
          }
          
          console.log(`  🔗 Matched Auth email (${authMatch.matchType}): ${authMatch.email} → UID: ${authMatch.uid}`);
          
          // Track match types for statistics
          const matchCategory = authMatch.matchType.includes('Doc ID Fallback') ? 'Doc ID Fallback' : 'Name-based';
          matchTypes.set(matchCategory, (matchTypes.get(matchCategory) || 0) + 1);
          
          if (authMatch.matchType.includes('Doc ID Fallback')) {
            docIdFallbackMatchCount++;
          } else {
            nameMatchCount++;
          }
          
          // Add UID to Firestore document
          await doc.ref.update({ uid: authMatch.uid });
          console.log(`  ✅ Added UID to Firestore document`);
          currentUid = authMatch.uid;
          uidAddedCount++;
        }
        
        // Update Auth email if needed
        if (currentUid) {
          const newEmail = generateNewEmail(firstName, lastName);
          
          try {
            const userRecord = await auth.getUser(currentUid);
            
            if (userRecord.email !== newEmail) {
              await auth.updateUser(currentUid, { email: newEmail });
              console.log(`  📧 Updated Auth email: ${userRecord.email} → ${newEmail}`);
              emailUpdatedCount++;
            } else {
              console.log(`  ✅ Auth email already correct: ${newEmail}`);
            }
          } catch (authError) {
            console.log(`  ❌ Failed to update Auth email: ${authError.message}`);
            errors.push(`${firstName} ${lastName}: Auth update failed - ${authError.message}`);
          }
        }
        
      } catch (error) {
        console.log(`  ❌ Error processing ${firstName} ${lastName}: ${error.message}`);
        errors.push(`${firstName} ${lastName}: ${error.message}`);
        skippedCount++;
      }
      
      console.log(); // Empty line for readability
    }
    
    // Step 4: Print detailed summary
    console.log('='.repeat(70));
    console.log('PROCESSING SUMMARY');
    console.log('='.repeat(70));
    console.log(`📊 Total officials processed: ${officialsSnapshot.size}`);
    console.log(`🔗 UIDs added to Firestore: ${uidAddedCount}`);
    console.log(`📧 Auth emails updated: ${emailUpdatedCount}`);
    console.log(`✅ Successfully processed: ${uidAddedCount + (officialsSnapshot.size - uidAddedCount - skippedCount)}`);
    console.log(`⚠️  Skipped (errors): ${skippedCount}`);
    console.log(`❌ Total errors: ${errors.length}`);
    console.log(`📈 Success rate: ${Math.round(((officialsSnapshot.size - skippedCount) / officialsSnapshot.size) * 100)}%`);
    
    // Show match type breakdown
    console.log('\n🔍 MATCHING BREAKDOWN:');
    console.log(`  📝 Name-based matches: ${nameMatchCount}`);
    console.log(`  📄 Doc ID fallback matches: ${docIdFallbackMatchCount}`);
    console.log(`  ❌ No matches found: ${skippedCount}`);
    
    if (matchTypes.size > 0) {
      console.log('\n📈 MATCH TYPE DETAILS:');
      for (const [type, count] of matchTypes.entries()) {
        console.log(`  • ${type}: ${count}`);
      }
    }
    
    if (errors.length > 0) {
      console.log('\n' + '='.repeat(30) + ' ERRORS ' + '='.repeat(30));
      errors.forEach((error, index) => console.log(`  ${index + 1}. ${error}`));
      
      // Categorize errors
      const noMatchErrors = errors.filter(e => e.includes('No matching Auth user found')).length;
      const authUpdateErrors = errors.filter(e => e.includes('Auth update failed')).length;
      const otherErrors = errors.length - noMatchErrors - authUpdateErrors;
      
      console.log('\n📋 ERROR BREAKDOWN:');
      console.log(`  🔍 No matching Auth user: ${noMatchErrors}`);
      console.log(`  📧 Auth update failed: ${authUpdateErrors}`);
      console.log(`  ❓ Other errors: ${otherErrors}`);
    }
    
    console.log('\n🎉 Firebase Auth email fixes completed!');
    
    // Show some sample successful mappings if any
    if (uidAddedCount > 0) {
      console.log('\n📋 Sample successful mappings were logged above.');
    }
    
    console.log('\nℹ️  Next steps:');
    console.log('  1. Review any errors above');
    console.log('  2. For "No matching Auth user" errors, check if those officials exist in Firebase Auth');
    console.log('  3. Run with --debug flag for detailed matching logs: npm run fix-auth-emails -- --debug');
    console.log('  4. Verify email updates in Firebase Console');
    console.log('  5. Check Firestore documents now have uid fields');
    
    if (skippedCount > 0) {
      console.log('\n⚠️  ATTENTION: Some officials were skipped. Consider:');
      console.log('     • Creating Firebase Auth accounts for missing officials');
      console.log('     • Checking spelling of names in Firestore');
      console.log('     • Manually mapping difficult cases');
      
      if (docIdFallbackMatchCount > 0) {
        console.log(`\n✅ SUCCESS: Doc ID fallback found ${docIdFallbackMatchCount} additional matches!`);
        console.log('     This means the enhancement is working for previously failed cases.');
      }
    }
    
  } catch (error) {
    console.error('💥 Fatal error during processing:', error);
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

// Run the fix
fixAuthEmails()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Unhandled error:', error);
    process.exit(1);
  });