# Database Migration Testing Checklist

## Pre-Testing Setup
- [ ] Run `flutter clean && flutter pub get`
- [ ] Build app successfully: `flutter build apk --debug`
- [ ] Install app on test device

## Core Feature Testing

### Games Feature
- [ ] Create new game template
- [ ] Edit existing game template
- [ ] Delete game template
- [ ] Use template to create game
- [ ] Verify game data persists after app restart

### Schedules Feature
- [ ] Create new schedule
- [ ] Edit schedule details
- [ ] Delete schedule
- [ ] Associate games with schedule
- [ ] Verify schedule data persists after app restart

### Locations Feature
- [ ] Create new location
- [ ] Edit location details
- [ ] Delete location
- [ ] Use location in games
- [ ] Verify location data persists after app restart

## Data Migration Testing

### Fresh Install
- [ ] Install app on clean device
- [ ] Verify database initializes correctly
- [ ] Create test data
- [ ] Restart app, verify data persists

### Upgrade Testing (if applicable)
- [ ] Install old version with SharedPreferences data
- [ ] Upgrade to new version
- [ ] Verify all data migrates correctly
- [ ] Test mixed data scenarios

## Error Handling Testing

### Database Failures
- [ ] Test with corrupted database file
- [ ] Test with insufficient storage
- [ ] Test with database locked
- [ ] Verify fallback to SharedPreferences works

### Network/Storage Issues
- [ ] Test with low storage space
- [ ] Test app recovery after forced kill
- [ ] Test multiple rapid operations

## Performance Testing

### Load Testing
- [ ] Create 50+ games
- [ ] Create 20+ schedules
- [ ] Create 30+ locations
- [ ] Monitor app performance and memory usage

### Startup Performance
- [ ] Measure cold start time
- [ ] Measure warm start time
- [ ] Compare with pre-migration performance

## User Flow Testing

### Coach Workflow
- [ ] Create team profile
- [ ] Add multiple games to schedule
- [ ] Create and use game templates
- [ ] Manage locations

### Assigner Workflow
- [ ] Manage multiple teams
- [ ] Assign officials to games
- [ ] Track schedules across teams

### Athletic Director Workflow
- [ ] Oversee all activities
- [ ] Manage templates
- [ ] View comprehensive reports

## Database Integrity Verification

### Database File Checks
- [ ] Verify database file exists
- [ ] Check file size is reasonable
- [ ] Verify file permissions

### Schema Verification
- [ ] Confirm all tables exist
- [ ] Verify column definitions
- [ ] Check foreign key constraints
- [ ] Test data integrity rules

## Final Validation

### Data Consistency
- [ ] Compare data before/after migration
- [ ] Verify no data loss
- [ ] Check data relationships intact

### User Experience
- [ ] No new crashes or errors
- [ ] Performance is acceptable
- [ ] All existing features work
- [ ] UI responds correctly

## Post-Testing

### Cleanup
- [ ] Remove test data
- [ ] Document any issues found
- [ ] Verify fixes work correctly

### Rollback Plan
- [ ] Document rollback procedure
- [ ] Test rollback if needed
- [ ] Verify old version still works

---

## Quick Testing Commands

```bash
# Build and test
flutter clean
flutter pub get
flutter build apk --debug
flutter install

# Monitor logs
flutter logs

# Performance profiling
flutter run --profile
```

## Test Data Sets

### Sample Game Template
```json
{
  "name": "Test Basketball Game",
  "sport": "Basketball",
  "location": "Test Gym",
  "date": "2024-01-15",
  "time": "19:00",
  "opponent": "Test Team",
  "officialsRequired": 3,
  "gameFee": "75.00"
}
```

### Sample Location
```json
{
  "name": "Test Gymnasium",
  "address": "123 Test Street",
  "city": "Test City",
  "state": "CA",
  "zip": "12345"
}
```

### Sample Schedule
```json
{
  "name": "Test Season 2024",
  "sport": "Basketball",
  "startDate": "2024-01-01",
  "endDate": "2024-03-31"
}
```