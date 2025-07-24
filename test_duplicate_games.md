# Test Duplicate Games Issue

## Steps to Reproduce

1. **Reset Database and Create Test Users**
   - Go to Database Test screen
   - Click "Reset Database"
   - Click "Create Test Users"

2. **Create Game Template**
   - Use Quick Access menu on welcome screen to log in
   - Go to hamburger menu and create a Game Template
   - Fill in the template details (opponent, date, etc.)

3. **Create Games Using Template**
   - Use the Game Template to create a new game
   - Click "Publish Game" button (this should take you back to Home screen)
   - Click the "+" button to add another game
   - Click "Use Game Template"
   - Use the same Game Template to create another game within the same Schedule
   - Publish this game as well

4. **Check for Duplicates**
   - Switch to Official user account
   - Go to "Available Games" screen
   - Count the number of games displayed
   - Note if any games show only "Away Team" without "@ Home Team"

## Expected Result
- Should see 2 unique games (if you created 2)
- Each game should display as "Away Team @ Home Team"

## Actual Result (Before Fix)
- See 4 games (2 duplicates for each created game)
- Some games show only "Away Team" (missing home team)

## Debug Output to Look For

With the enhanced debugging, you should see output like:

```
🎮 ===== CREATING GAME (ID: 1234567890) =====
Game data: {opponent: "Team A", sport: "Basketball", ...}
Stack trace (first 3 lines): ...
==============================

Checking potential duplicate:
  Existing: opponent="Team A", date=2025-01-15, sport="Basketball", schedule="Schedule A"
  New: opponent="Team A", date=2025-01-15, sport="Basketball", schedule="Schedule A"
  Matches: opponent=true, date=true, sport=true, schedule=true

🚫 DUPLICATE DETECTED: Skipping creation of duplicate game.
   Existing game ID: 123
   Existing game: "Team A" on 2025-01-15T10:00:00.000
   Existing homeTeam: "Home Team"
```

Or if no duplicate is detected:

```
✅ Game created with database ID: 456 (Creation ID: 1234567890)
✅ Successfully retrieved created game from database
   Game ID: 456
   Opponent: "Team A"
   HomeTeam: "School Tigers"
   Sport: "Basketball"
   Status: "Published"
🎮 ===== END GAME CREATION (ID: 1234567890) =====
```

## What the Debug Output Will Tell Us

1. **If duplicates are still created**: We'll see multiple "CREATING GAME" logs for the same game
2. **If duplicate prevention works**: We'll see "DUPLICATE DETECTED" messages
3. **HomeTeam issues**: We'll see exactly what homeTeam value is being set
4. **Stack traces**: We'll see exactly where the game creation is being called from

This will help us identify if:
- Games are being created multiple times from the same code path
- Games are being created from different code paths
- The homeTeam logic is failing in some scenarios
- The duplicate prevention is working correctly