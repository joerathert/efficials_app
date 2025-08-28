# Firebase Auth Email Fix Instructions

## Overview
This script (`fix_auth_emails.js`) maps Firebase Authentication users to Firestore 'officials' documents and updates both:
1. Adds `uid` fields to Firestore documents 
2. Updates Authentication user emails to match the new format (`first2letters + lastname@test.com`)

## Prerequisites

1. **Service Account JSON**: Place `service-account.json` in the project root
2. **Dependencies**: Run `npm install` to install required packages
3. **Firebase Project**: Ensure you have admin access to the Firebase project

## Script Features

- **Automatic CSV Export**: Exports all Authentication users to `auth_users_export.csv`
- **Smart Email Matching**: Uses multiple patterns to match officials to Auth users:
  - `1jimbroadway@gmail.com` → James Broadway
  - `jim.broadway@gmail.com` → James Broadway  
  - `jbroadway@gmail.com` → James Broadway
  - And more flexible patterns
- **UID Mapping**: Adds `uid` field to Firestore documents
- **Email Updates**: Updates Auth emails to new format
- **Error Handling**: Graceful handling of mismatches and failures
- **Progress Reporting**: Detailed logging and summary

## Usage

### Option 1: Automatic (Recommended)
```bash
npm run fix-auth-emails
```

The script will:
1. Export all Authentication users to CSV automatically
2. Process all officials and update emails

### Option 2: Manual CSV Preparation

If you prefer to prepare the CSV manually:

1. **Export from Firebase Console**:
   - Go to Firebase Console → Authentication → Users
   - Click "Export users" button
   - Save as CSV with columns: `uid`, `email`, `emailVerified`, `disabled`, `creationTime`

2. **Save CSV**: Place the exported CSV as `auth_users_export.csv` in project root

3. **Run Script**:
   ```bash
   npm run fix-auth-emails
   ```

## Expected CSV Format

```csv
uid,email,emailVerified,disabled,creationTime
"abc123","1jimbroadway@gmail.com","true","false","2024-01-15T10:30:00.000Z"
"def456","mary.johnson@gmail.com","true","false","2024-01-15T11:00:00.000Z"
```

## What the Script Does

### Step 1: CSV Processing
- Reads Authentication users from CSV
- Creates email-to-UID mapping

### Step 2: Firestore Processing  
- Fetches all documents from 'officials' collection
- For each official with `firstName` and `lastName`:

### Step 3: UID Mapping
- Uses smart matching to find corresponding Auth user
- Adds `uid` field to Firestore document

### Step 4: Email Updates
- Generates new email: `first2letters + lastname@test.com`
- Updates Authentication user's email address

## Example Transformations

| Official Name | Original Auth Email | New Email Format | Action |
|---------------|-------------------|------------------|--------|
| James Broadway | `1jimbroadway@gmail.com` | `jabroadway@test.com` | ✅ Match & Update |
| Mary Johnson | `mary.johnson@gmail.com` | `majohnson@test.com` | ✅ Match & Update |
| John Smith | No matching email | `josmith@test.com` | ❌ Skip (no match) |

## Output Example

```
🚀 Starting Firebase Auth email fixes...

📋 Fetching officials from Firestore collection...
✅ Found 25 officials in Firestore

🔄 Processing officials...

Processing: James Broadway (Doc ID: official_001)
  🔗 Matched Auth email: 1jimbroadway@gmail.com → UID: abc123
  ✅ Added UID to Firestore document
  📧 Updated Auth email: 1jimbroadway@gmail.com → jabroadway@test.com

============================================================
PROCESSING SUMMARY
============================================================
📊 Total officials processed: 25
🔗 UIDs added to Firestore: 23
📧 Auth emails updated: 23
⚠️  Skipped (errors): 2
❌ Total errors: 2

🎉 Firebase Auth email fixes completed!
```

## Troubleshooting

### Common Issues

1. **"CSV file not found"**: Script will auto-export, or manually place CSV in project root

2. **"No matching Auth user found"**: Official name doesn't match any Authentication email
   - Check spelling in Firestore
   - Verify Authentication user exists
   - Check email patterns in script

3. **"Failed to update Auth email"**: Usually permissions or user state issues
   - Ensure service account has Auth Admin privileges
   - Check if user is disabled

### Manual Verification

After running the script:
1. Check Firebase Console → Authentication → Users for updated emails
2. Verify Firestore 'officials' collection has `uid` fields
3. Review error log for any skipped officials

## Files Generated

- `auth_users_export.csv`: Authentication users export (created automatically)
- Console logs with detailed progress and errors

## Security Notes

- Uses Firebase Admin SDK with service account privileges
- Does not require user passwords (Admin SDK bypasses this)
- Processes only existing Authentication users
- No data deletion, only additions and updates