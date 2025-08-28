// Simple script to populate Firebase Emulator with test data
const admin = require('firebase-admin');

// Configure for emulator
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';

admin.initializeApp({
  projectId: 'efficials-app'
});

const auth = admin.auth();
const db = admin.firestore();

async function populateEmulator() {
  console.log('🔄 Populating Firebase Emulator with test data...');
  
  try {
    // Create test users in Auth and Firestore
    const testUsers = [
      { email: 'ad@test.com', password: 'test123', userType: 'athletic_director', name: 'Athletic Director Test' },
      { email: 'assigner@test.com', password: 'test123', userType: 'assigner', name: 'Assigner Test' },
      { email: 'coach@test.com', password: 'test123', userType: 'coach', name: 'Coach Test' }
    ];

    console.log('👥 Creating test users...');
    for (const user of testUsers) {
      try {
        // Create in Auth
        const userRecord = await auth.createUser({
          email: user.email,
          password: user.password,
          displayName: user.name
        });
        console.log(`✅ Auth user created: ${user.email}`);

        // Create in Firestore users collection
        await db.collection('users').doc(user.email).set({
          email: user.email,
          password: user.password,
          userType: user.userType,
          name: user.name,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✅ Firestore user document created: ${user.email}`);
        
      } catch (error) {
        if (error.code === 'auth/email-already-exists') {
          console.log(`⚠️  User already exists: ${user.email}`);
        } else {
          console.error(`❌ Error creating user ${user.email}:`, error.message);
        }
      }
    }

    // Create sample officials
    console.log('👨‍⚖️ Creating sample officials...');
    const sampleOfficials = [
      { email: 'official1@test.com', name: 'John Smith', sport: 'Basketball', location: 'Edwardsville, IL' },
      { email: 'official2@test.com', name: 'Michael Johnson', sport: 'Football', location: 'Alton, IL' },
      { email: 'official3@test.com', name: 'David Wilson', sport: 'Baseball', location: 'Collinsville, IL' }
    ];

    for (const official of sampleOfficials) {
      await db.collection('officials').doc(official.email).set({
        ...official,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log(`✅ Official created: ${official.name}`);
    }

    console.log('🎉 Emulator populated successfully!');
    console.log('🌐 View at: http://localhost:4000');
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
  
  process.exit(0);
}

populateEmulator();