# Advanced Method (Multiple Lists) Testing Guide

## Overview
This guide provides test scenarios to verify the Advanced Method functionality works correctly.

## Test Setup
1. Create a sport (e.g., Basketball)
2. Create two official lists:
   - "ROOKIE REFS" with 3 officials
   - "VETERAN REFS" with 2 officials  
   - Have 1 official (e.g., "Official A") on both lists
3. Create a basketball game requiring 2 officials
4. Set up Advanced Method quotas:
   - ROOKIE REFS: min=0, max=1
   - VETERAN REFS: min=1, max=2

## Test Scenarios

### Scenario 1: Basic Quota Logic
**Setup**: Game needs 2 officials with quotas above
**Expected Behavior**:
- Game should be visible to all officials on both lists initially
- When a rookie official claims the game, the game should disappear from Available Games for other rookies (max=1 reached)
- Game should remain visible to veteran officials (min=1 still needs to be filled)
- Officials on both lists should still see the game

### Scenario 2: Cross-List Membership
**Setup**: Official A is on both ROOKIE and VETERAN lists
**Test Steps**:
1. Rookie Official B claims the game
2. Check Available Games visibility

**Expected Results**:
- Official A should still see the game (can fulfill veteran requirement)
- Other rookie officials should not see the game
- Veteran officials should still see the game

### Scenario 3: Minimum Requirements Priority
**Setup**: Same as above, but test assignment logic
**Test Steps**:
1. Official A (on both lists) claims the game
2. Check which list they're assigned from

**Expected Results**:
- Official A should be assigned from VETERAN list (to fulfill minimum requirement)
- Game should still need 1 more official
- Only veteran officials should see the game now

### Scenario 4: Game Full Capacity
**Setup**: Continue from Scenario 3
**Test Steps**:
1. Veteran Official C claims the game
2. Check game visibility

**Expected Results**:
- Game should disappear from all officials' Available Games
- Game should show as fully staffed (2/2 officials)

## Database Queries for Verification

### Check Quota Status
```sql
SELECT 
  glq.*,
  ol.name as list_name
FROM game_list_quotas glq
JOIN official_lists ol ON glq.list_id = ol.id
WHERE glq.game_id = [GAME_ID];
```

### Check Official Assignments
```sql
SELECT 
  ola.*,
  o.name as official_name,
  ol.name as list_name
FROM official_list_assignments ola
JOIN officials o ON ola.official_id = o.id
JOIN official_lists ol ON ola.list_id = ol.id
WHERE ola.game_id = [GAME_ID];
```

### Check Game Visibility for Official
```sql
-- This would be done through the isGameVisibleToOfficial method
-- but you can manually check list memberships:
SELECT DISTINCT olm.list_id, ol.name
FROM official_list_members olm
JOIN official_lists ol ON olm.list_id = ol.id
JOIN games g ON ol.sport_id = g.sport_id
WHERE olm.official_id = [OFFICIAL_ID] AND g.id = [GAME_ID];
```

## Expected Database Changes

### After Setup
- `game_list_quotas` table should have 2 records for the game
- `games.method` should be 'advanced'

### After First Official Claims
- `official_list_assignments` should have 1 record
- `game_list_quotas.current_officials` should be updated
- `games.officials_hired` should be 1

### After Game is Full
- `official_list_assignments` should have 2 records
- All quotas should show appropriate `current_officials` counts
- `games.officials_hired` should equal `games.officials_required`

## Error Cases to Test

1. **No Lists Available**: Official not on any relevant lists should not see the game
2. **All Quotas Full**: When all lists reach maximum, game should be invisible to everyone
3. **Invalid Assignment**: Official tries to claim game they shouldn't see (should fail gracefully)

## Manual Testing Steps

1. **Create Test Data**:
   - Use existing UI to create officials, lists, and games
   - Verify data is created correctly in database

2. **Set Up Advanced Method**:
   - Use the new `AdvancedMethodSetupScreen` to configure quotas
   - Verify quotas are saved correctly

3. **Test Official Views**:
   - Log in as different officials
   - Check Available Games list matches expectations
   - Verify game claiming works correctly

4. **Verify Database State**:
   - After each action, check database tables match expected state
   - Use the SQL queries above to verify data

## Success Criteria

✅ Game visibility changes correctly based on quota status
✅ Officials are assigned from appropriate lists
✅ Cross-list membership works correctly  
✅ Minimum requirements are prioritized
✅ Maximum limits are enforced
✅ Database state remains consistent
✅ Error cases are handled gracefully