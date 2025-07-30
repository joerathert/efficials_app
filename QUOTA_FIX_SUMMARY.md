# Advanced Method Quota Creation Fix

## Problem Description

When games were created from templates using the Advanced Method (Multiple Lists), the quota configuration was properly displayed in the UI but the actual quota records were never saved to the database. This caused the Advanced Method logic to fall back to traditional method, making games visible to all officials instead of enforcing the quota-based visibility rules.

## Root Cause Analysis

The issue was in the game creation flow in `review_game_info_screen.dart`. When a game was published:

1. ✅ Template correctly stored `selectedLists` data with quota configuration
2. ✅ Review screen correctly displayed quota information from `selectedLists` 
3. ✅ Game was saved to database with `method: 'advanced'`
4. ✅ `selectedLists` data was saved to SharedPreferences for UI reconstruction
5. ❌ **BUT** actual quota records were never created in the `game_list_quotas` table

This meant that when officials checked Available Games, the `AdvancedMethodRepository.isGameVisibleToOfficial()` method found no quotas and defaulted to showing the game to everyone.

## Data Structure

The `selectedLists` data structure contains:
```dart
[
  {
    'id': 1,                    // List ID (required for database)
    'name': 'Rookie Refs',      // List name (for display)
    'minOfficials': 0,          // Minimum required from this list
    'maxOfficials': 1,          // Maximum allowed from this list
    'officials': [...]          // Officials in this list
  },
  // ... more lists
]
```

## Solution Implemented

### 1. Modified `_publishGame()` method in `review_game_info_screen.dart`

Added quota creation logic after game is saved to database:

```dart
// CREATE ACTUAL QUOTA RECORDS IN DATABASE
try {
  final selectedLists = gameData['selectedLists'] as List<dynamic>;
  final quotas = selectedLists.map((list) => {
    'listId': list['id'] as int,
    'minOfficials': list['minOfficials'] as int,
    'maxOfficials': list['maxOfficials'] as int,
  }).toList();
  
  final advancedRepo = AdvancedMethodRepository();
  await advancedRepo.setGameListQuotas(gameId, quotas);
  debugPrint('Created ${quotas.length} quota records for game $gameId');
} catch (e) {
  debugPrint('Error creating quota records for game $gameId: $e');
}
```

### 2. Modified `_publishUpdate()` method in `review_game_info_screen.dart`

Added similar quota update logic for when games are edited:

```dart
// UPDATE QUOTA RECORDS IN DATABASE
try {
  final selectedLists = gameData['selectedLists'] as List<dynamic>;
  final quotas = selectedLists.map((list) => {
    'listId': list['id'] as int,
    'minOfficials': list['minOfficials'] as int,
    'maxOfficials': list['maxOfficials'] as int,
  }).toList();
  
  final advancedRepo = AdvancedMethodRepository();
  await advancedRepo.setGameListQuotas(gameId, quotas);
  debugPrint('Updated ${quotas.length} quota records for game $gameId');
} catch (e) {
  debugPrint('Error updating quota records for game $gameId: $e');
}
```

### 3. Added Required Import

```dart
import '../../shared/services/repositories/advanced_method_repository.dart';
```

## Expected Behavior After Fix

1. **Game Creation from Template**: 
   - Template has quota configuration (e.g., Rookie Refs: 0-1, Veteran Refs: 1-2)
   - Game is created and published
   - Actual quota records are saved to `game_list_quotas` table
   - Game appears only to officials who are on lists with remaining capacity

2. **Game Visibility Logic**:
   - `AdvancedMethodRepository.isGameVisibleToOfficial()` finds quota records
   - Checks if official is on any relevant lists for the game's sport
   - Returns `true` only if at least one list has remaining capacity
   - Returns `false` if all lists are at maximum capacity

3. **Quota Enforcement**:
   - First official from Rookie Refs list claims game → quota becomes 1/1 for Rookie Refs
   - Game disappears from Available Games for other Rookie Refs officials
   - Game remains visible to Veteran Refs officials (still 0/2)

## Files Modified

- `lib/features/games/review_game_info_screen.dart`
  - Added import for `AdvancedMethodRepository`
  - Added quota creation logic in `_publishGame()` method (lines 227-242)
  - Added quota update logic in `_publishUpdate()` method (lines 607-621)

## Testing

Created test script `test_quota_fix.dart` to verify:
- Quota creation from `selectedLists` data structure
- Database quota record creation and retrieval
- Game visibility logic with quota enforcement
- Template workflow simulation

## Debug Verification

After applying the fix, games created from Advanced Method templates should show debug output like:
```
Created 2 quota records for game 14
Found 2 quotas for game 14
List 1 quota: 0/1, canAcceptMore: true
Game 14 visible to official 2: true
```

Instead of the previous:
```
Found 0 quotas for game 14
No quotas found - game visible (traditional method)
```

## Impact

This fix resolves the core issue where Advanced Method quota enforcement wasn't working because quota database records were missing. Now the complete Advanced Method workflow functions as designed:

- Template → Game Creation → Quota Records → Visibility Logic → Quota Enforcement