# Reset Authentication & Firestore Setup Instructions

## Prerequisites

### 1. Firebase Credentials Setup
You need to authenticate with Firebase. Choose **one** of these methods:

#### Option A: Application Default Credentials (Recommended)
```bash
# Install Google Cloud CLI if not already installed
# Windows: Download from https://cloud.google.com/sdk/docs/install
# macOS: brew install google-cloud-sdk
# Ubuntu: snap install google-cloud-sdk --classic

# Authenticate
gcloud auth application-default login
gcloud config set project efficials-app
```

#### Option B: Service Account Key
1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Download the JSON file as `service-account.json`
4. Place it in your project root `/mnt/c/Users/Efficials/efficials_app/`
5. Set environment variable:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="./service-account.json"
```

### 2. CSV File Preparation
Ensure your `officials.csv` file is in the project root with this format:
```csv
firstName,lastName
James,Broadway
John,Smith
Mary,Johnson
```

**Requirements:**
- Headers must be `firstName,lastName` (case-sensitive)
- All officials must be from locations within 100 miles of Edwardsville, IL
- All officials must have male names (per CLAUDE.md requirements)
- Empty lines will be skipped automatically

## Installation & Usage

### 1. Install Dependencies
```bash
npm install firebase-admin csv-parse
```

### 2. Run the Reset Script
```bash
npm run reset-auth-firestore
```

### 3. Alternative Direct Run
```bash
node reset_auth_firestore.js
```

## What the Script Does

### Phase 1: Data Preparation
- ✅ Reads `officials.csv` with firstName/lastName columns
- ✅ Generates unique @test.com emails (e.g., `james.broadway@test.com`)
- ✅ Handles duplicates by appending numbers (e.g., `john.smith1@test.com`)

### Phase 2: Firebase Cleanup
- 🗑️ Clears existing Firestore 'officials' collection
- 🗑️ Deletes all existing Firebase Authentication users
- ⚠️ **WARNING**: This is destructive! Make backups if needed.

### Phase 3: Data Creation
- 👤 Creates Firebase Authentication users with:
  - Email: Generated from firstName.lastName@test.com
  - Password: `tempPass123` (temporary)
  - Display Name: "FirstName LastName"
  - Email Verified: false

- 📄 Creates Firestore documents with:
  - firstName: From CSV
  - lastName: From CSV  
  - email: Generated email
  - uid: From Authentication user
  - createdAt: Server timestamp
  - updatedAt: Server timestamp

## Expected Output

```bash
🚀 Starting Authentication and Firestore reset...

📖 Reading CSV file: ./officials.csv
✅ Parsed 148 officials from CSV

🗑️  Clearing existing data...
   ✅ Deleted 100 Authentication users
   ✅ Deleted 100 Firestore documents

🔨 Creating Authentication users and Firestore documents...

📋 Processing 1/148: James Broadway
   👤 Created Auth user: james.broadway@test.com with UID: abc123
   📄 Created Firestore doc: def456
   ✅ Complete: james.broadway@test.com → UID: abc123

[... continues for all 148 officials ...]

======================================================================
RESET SUMMARY
======================================================================
📊 Total officials processed: 148
✅ Successful creations: 148
❌ Failed creations: 0
📈 Success rate: 100%

🎉 Authentication and Firestore reset completed!
```

## Verification Steps

### 1. Firebase Console Verification
- **Authentication**: Go to Firebase Console → Authentication → Users
  - Should see 148 users with @test.com emails
  - All should show "Email not verified"

- **Firestore**: Go to Firebase Console → Firestore → officials collection  
  - Should see 148 documents
  - Each with firstName, lastName, email, uid, createdAt, updatedAt

### 2. Test Your Flutter App
```bash
flutter run -d chrome
```

## Troubleshooting

### "Permission denied" errors
- Ensure you're authenticated: `gcloud auth list`
- Check project ID: `gcloud config get-value project`
- Verify Firebase Admin role in IAM

### "CSV file not found"
- Ensure `officials.csv` is in project root
- Check file permissions: `ls -la officials.csv`

### Rate limit errors
- Script automatically pauses every 10 creations
- Firebase has limits: 100 operations/second for Auth

### Email format issues  
- Duplicates auto-handled with numbers
- Special characters removed from names
- Format: `firstname.lastname@test.com`

## Next Steps After Success

1. ✅ Verify 148 users in Firebase Console
2. ✅ Test `unified_data_service.dart` with `flutter run -d chrome`  
3. ✅ Update user passwords as needed
4. ✅ Set up email verification flows
5. ✅ Configure additional user fields if required

## Security Notes

- 🔒 All users created with temporary password: `tempPass123`
- 📧 Email verification disabled initially
- 🔐 Change passwords in production
- 🛡️ Consider enabling MFA for admin users