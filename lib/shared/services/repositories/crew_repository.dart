import 'package:flutter/material.dart';
import 'base_repository.dart';
import '../../models/database_models.dart';

class CrewRepository extends BaseRepository {
  
  // Crew Type operations
  Future<List<CrewType>> getAllCrewTypes() async {
    final results = await rawQuery('''
      SELECT DISTINCT ct.sport_id, ct.required_officials, s.name as sport_name,
             MIN(ct.id) as id, MIN(ct.level_of_competition) as level_of_competition,
             MIN(ct.description) as description, MIN(ct.created_at) as created_at
      FROM crew_types ct
      JOIN sports s ON ct.sport_id = s.id
      GROUP BY ct.sport_id, ct.required_officials, s.name
      ORDER BY s.name, ct.required_officials
    ''');
    
    return results.map((data) => CrewType.fromMap(data)).toList();
  }
  
  Future<List<CrewType>> getCrewTypesBySport(int sportId) async {
    final results = await rawQuery('''
      SELECT DISTINCT ct.sport_id, ct.required_officials, s.name as sport_name,
             MIN(ct.id) as id, MIN(ct.level_of_competition) as level_of_competition,
             MIN(ct.description) as description, MIN(ct.created_at) as created_at
      FROM crew_types ct
      JOIN sports s ON ct.sport_id = s.id
      WHERE ct.sport_id = ?
      GROUP BY ct.sport_id, ct.required_officials, s.name
      ORDER BY ct.required_officials
    ''', [sportId]);
    
    return results.map((data) => CrewType.fromMap(data)).toList();
  }
  
  // Crew CRUD operations
  Future<int> createCrew(Crew crew) async {
    return await insert('crews', crew.toMap());
  }
  
  Future<Crew?> getCrewById(int crewId) async {
    final results = await rawQuery('''
      SELECT c.*, ct.required_officials, ct.level_of_competition,
             s.name as sport_name, o.name as crew_chief_name,
             COUNT(cm.id) as current_members
      FROM crews c
      JOIN crew_types ct ON c.crew_type_id = ct.id
      JOIN sports s ON ct.sport_id = s.id
      JOIN officials o ON c.crew_chief_id = o.id
      LEFT JOIN crew_members cm ON c.id = cm.crew_id AND cm.status = 'active'
      WHERE c.id = ? AND c.is_active = 1
      GROUP BY c.id
    ''', [crewId]);
    
    if (results.isEmpty) return null;
    
    final crewData = Crew.fromMap(results.first);
    
    // Get crew members separately to populate the members list
    final members = await getCrewMembers(crewId);
    
    return Crew(
      id: crewData.id,
      name: crewData.name,
      crewTypeId: crewData.crewTypeId,
      crewChiefId: crewData.crewChiefId,
      createdBy: crewData.createdBy,
      isActive: crewData.isActive,
      paymentMethod: crewData.paymentMethod,
      crewFeePerGame: crewData.crewFeePerGame,
      createdAt: crewData.createdAt,
      updatedAt: crewData.updatedAt,
      sportName: crewData.sportName,
      levelOfCompetition: crewData.levelOfCompetition,
      requiredOfficials: crewData.requiredOfficials,
      crewChiefName: crewData.crewChiefName,
      members: members,
    );
  }
  
  Future<List<Crew>> getAllCrews() async {
    final results = await rawQuery('''
      SELECT c.*, ct.required_officials, ct.level_of_competition,
             s.name as sport_name, o.name as crew_chief_name,
             COUNT(cm.id) as current_members
      FROM crews c
      JOIN crew_types ct ON c.crew_type_id = ct.id
      JOIN sports s ON ct.sport_id = s.id
      JOIN officials o ON c.crew_chief_id = o.id
      LEFT JOIN crew_members cm ON c.id = cm.crew_id AND cm.status = 'active'
      WHERE c.is_active = 1
      GROUP BY c.id
      ORDER BY c.name
    ''');
    
    final crews = <Crew>[];
    for (final data in results) {
      final crewData = Crew.fromMap(data);
      final members = await getCrewMembers(crewData.id!);
      
      crews.add(Crew(
        id: crewData.id,
        name: crewData.name,
        crewTypeId: crewData.crewTypeId,
        crewChiefId: crewData.crewChiefId,
        createdBy: crewData.createdBy,
        isActive: crewData.isActive,
        paymentMethod: crewData.paymentMethod,
        crewFeePerGame: crewData.crewFeePerGame,
        createdAt: crewData.createdAt,
        updatedAt: crewData.updatedAt,
        sportName: crewData.sportName,
        levelOfCompetition: crewData.levelOfCompetition,
        requiredOfficials: crewData.requiredOfficials,
        crewChiefName: crewData.crewChiefName,
        competitionLevels: crewData.competitionLevels,
        members: members,
      ));
    }
    
    return crews;
  }
  
  Future<List<Crew>> getCrewsWhereChief(int officialId) async {
    final results = await rawQuery('''
      SELECT c.*, ct.required_officials, ct.level_of_competition,
             s.name as sport_name, o.name as crew_chief_name,
             COUNT(cm.id) as current_members
      FROM crews c
      JOIN crew_types ct ON c.crew_type_id = ct.id
      JOIN sports s ON ct.sport_id = s.id
      JOIN officials o ON c.crew_chief_id = o.id
      LEFT JOIN crew_members cm ON c.id = cm.crew_id AND cm.status = 'active'
      WHERE c.crew_chief_id = ? AND c.is_active = 1
      GROUP BY c.id
      ORDER BY c.name
    ''', [officialId]);
    
    final crews = <Crew>[];
    for (final data in results) {
      final crewData = Crew.fromMap(data);
      final members = await getCrewMembers(crewData.id!);
      
      crews.add(Crew(
        id: crewData.id,
        name: crewData.name,
        crewTypeId: crewData.crewTypeId,
        crewChiefId: crewData.crewChiefId,
        createdBy: crewData.createdBy,
        isActive: crewData.isActive,
        paymentMethod: crewData.paymentMethod,
        crewFeePerGame: crewData.crewFeePerGame,
        createdAt: crewData.createdAt,
        updatedAt: crewData.updatedAt,
        sportName: crewData.sportName,
        levelOfCompetition: crewData.levelOfCompetition,
        requiredOfficials: crewData.requiredOfficials,
        crewChiefName: crewData.crewChiefName,
        competitionLevels: crewData.competitionLevels,
        members: members,
      ));
    }
    
    return crews;
  }
  
  Future<List<Crew>> getCrewsForOfficial(int officialId) async {
    final results = await rawQuery('''
      SELECT c.*, ct.required_officials, ct.level_of_competition,
             s.name as sport_name, o.name as crew_chief_name,
             cm.position, cm.game_position,
             COUNT(cm2.id) as current_members
      FROM crews c
      JOIN crew_types ct ON c.crew_type_id = ct.id
      JOIN sports s ON ct.sport_id = s.id
      JOIN officials o ON c.crew_chief_id = o.id
      JOIN crew_members cm ON c.id = cm.crew_id
      LEFT JOIN crew_members cm2 ON c.id = cm2.crew_id AND cm2.status = 'active'
      WHERE cm.official_id = ? AND cm.status = 'active' AND c.is_active = 1
      GROUP BY c.id
      ORDER BY c.name
    ''', [officialId]);
    
    final crews = <Crew>[];
    for (final data in results) {
      final crewData = Crew.fromMap(data);
      final members = await getCrewMembers(crewData.id!);
      
      crews.add(Crew(
        id: crewData.id,
        name: crewData.name,
        crewTypeId: crewData.crewTypeId,
        crewChiefId: crewData.crewChiefId,
        createdBy: crewData.createdBy,
        isActive: crewData.isActive,
        paymentMethod: crewData.paymentMethod,
        crewFeePerGame: crewData.crewFeePerGame,
        createdAt: crewData.createdAt,
        updatedAt: crewData.updatedAt,
        sportName: crewData.sportName,
        levelOfCompetition: crewData.levelOfCompetition,
        requiredOfficials: crewData.requiredOfficials,
        crewChiefName: crewData.crewChiefName,
        competitionLevels: crewData.competitionLevels,
        members: members,
      ));
    }
    
    return crews;
  }
  
  // Crew member management
  Future<int> addCrewMember(int crewId, int officialId, String position, String? gamePosition) async {
    // First check if crew has space
    final crew = await getCrewById(crewId);
    if (crew == null) throw Exception('Crew not found');
    
    final currentMembers = await getCurrentMemberCount(crewId);
    if (currentMembers >= crew.requiredOfficials!) {
      throw Exception('Crew is already at full capacity (${crew.requiredOfficials} members)');
    }
    
    return await insert('crew_members', {
      'crew_id': crewId,
      'official_id': officialId,
      'position': position,
      'game_position': gamePosition,
      'status': 'active',
      'joined_at': DateTime.now().toIso8601String(),
    });
  }
  
  Future<int> removeCrewMember(int crewId, int officialId) async {
    return await update('crew_members', 
      {'status': 'inactive'}, 
      'crew_id = ? AND official_id = ?', 
      [crewId, officialId]);
  }
  
  Future<List<CrewMember>> getCrewMembers(int crewId) async {
    final results = await rawQuery('''
      SELECT cm.*, o.name as official_name, o.phone, o.email
      FROM crew_members cm
      JOIN officials o ON cm.official_id = o.id
      WHERE cm.crew_id = ? AND cm.status = 'active'
      ORDER BY 
        CASE WHEN cm.position = 'crew_chief' THEN 0 ELSE 1 END,
        cm.joined_at
    ''', [crewId]);
    
    return results.map((data) => CrewMember.fromMap(data)).toList();
  }
  
  Future<int> getCurrentMemberCount(int crewId) async {
    final results = await rawQuery('''
      SELECT COUNT(*) as count 
      FROM crew_members 
      WHERE crew_id = ? AND status = 'active'
    ''', [crewId]);
    
    return results.first['count'] ?? 0;
  }
  
  // Crew availability management
  Future<int> setCrewAvailability(int crewId, DateTime date, String status,
                                  TimeOfDay? startTime, TimeOfDay? endTime,
                                  String? notes, int setById) async {
    final data = {
      'crew_id': crewId,
      'date': date.toIso8601String().split('T')[0],
      'status': status,
      'notes': notes,
      'set_by': setById,
    };
    
    if (startTime != null) {
      data['start_time'] = '${startTime.hour}:${startTime.minute}';
    }
    if (endTime != null) {
      data['end_time'] = '${endTime.hour}:${endTime.minute}';
    }
    
    // Use INSERT OR REPLACE for upsert behavior
    await rawInsert('''
      INSERT OR REPLACE INTO crew_availability 
      (crew_id, date, start_time, end_time, status, notes, set_by)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [crewId, data['date'], data['start_time'], data['end_time'], 
          status, notes, setById]);
    
    return 1; // Return success count
  }
  
  Future<List<CrewAvailability>> getCrewAvailability(int crewId, 
                                                     DateTime startDate, 
                                                     DateTime endDate) async {
    final results = await rawQuery('''
      SELECT * FROM crew_availability 
      WHERE crew_id = ? 
        AND date BETWEEN ? AND ?
      ORDER BY date
    ''', [crewId, startDate.toIso8601String().split('T')[0], 
          endDate.toIso8601String().split('T')[0]]);
    
    return results.map((data) => CrewAvailability.fromMap(data)).toList();
  }
  
  Future<bool> isCrewAvailable(int crewId, DateTime date, TimeOfDay time) async {
    final results = await rawQuery('''
      SELECT status, start_time, end_time
      FROM crew_availability
      WHERE crew_id = ? AND date = ?
    ''', [crewId, date.toIso8601String().split('T')[0]]);
    
    if (results.isEmpty) return true; // No restriction = available
    
    final availability = results.first;
    if (availability['status'] != 'available') return false;
    
    // Check time restrictions if set
    if (availability['start_time'] != null && availability['end_time'] != null) {
      final startParts = availability['start_time'].split(':');
      final endParts = availability['end_time'].split(':');
      
      final startTime = TimeOfDay(
        hour: int.parse(startParts[0]), 
        minute: int.parse(startParts[1])
      );
      final endTime = TimeOfDay(
        hour: int.parse(endParts[0]), 
        minute: int.parse(endParts[1])
      );
      
      final gameMinutes = time.hour * 60 + time.minute;
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      
      return gameMinutes >= startMinutes && gameMinutes <= endMinutes;
    }
    
    return true;
  }
  
  // Crew assignment management
  Future<int> createCrewAssignment(CrewAssignment assignment) async {
    return await insert('crew_assignments', assignment.toMap());
  }
  
  Future<List<CrewAssignment>> getPendingCrewAssignments(int crewChiefId) async {
    final results = await rawQuery('''
      SELECT ca.*, g.date, g.time, g.opponent, g.home_team, g.game_fee,
             l.name as location_name, s.name as sport_name, c.name as crew_name,
             u.first_name || ' ' || u.last_name as scheduler_name
      FROM crew_assignments ca
      JOIN games g ON ca.game_id = g.id
      JOIN crews c ON ca.crew_id = c.id
      JOIN users u ON ca.assigned_by = u.id
      LEFT JOIN locations l ON g.location_id = l.id
      LEFT JOIN sports sp ON g.sport_id = sp.id
      WHERE ca.crew_chief_id = ? 
        AND ca.status = 'pending'
        AND ca.crew_chief_response_required = 1
      ORDER BY g.date ASC, g.time ASC
    ''', [crewChiefId]);
    
    return results.map((data) => CrewAssignment.fromMap(data)).toList();
  }
  
  Future<int> respondToCrewAssignment(int assignmentId, String status, 
                                      String? notes, int crewChiefId) async {
    final result = await update('crew_assignments', {
      'status': status,
      'responded_at': DateTime.now().toIso8601String(),
      'response_notes': notes,
      'crew_chief_response_required': 0,
    }, 'id = ? AND crew_chief_id = ?', [assignmentId, crewChiefId]);
    
    // If accepted, create individual game assignments for all crew members
    if (status == 'accepted') {
      await _createIndividualAssignments(assignmentId);
    }
    
    return result;
  }
  
  Future<void> _createIndividualAssignments(int crewAssignmentId) async {
    // Get crew assignment details
    final crewAssignment = await rawQuery('''
      SELECT ca.*, c.payment_method
      FROM crew_assignments ca
      JOIN crews c ON ca.crew_id = c.id
      WHERE ca.id = ?
    ''', [crewAssignmentId]);
    
    if (crewAssignment.isEmpty) return;
    
    final assignment = crewAssignment.first;
    final gameId = assignment['game_id'];
    final crewId = assignment['crew_id'];
    final totalFee = assignment['total_fee_amount'] ?? 0.0;
    final paymentMethod = assignment['payment_method'] ?? 'equal_split';
    
    // Get crew members
    final members = await getCrewMembers(crewId);
    
    // Calculate individual fees
    double individualFee = 0.0;
    if (paymentMethod == 'equal_split' && totalFee > 0) {
      individualFee = totalFee / members.length;
    }
    
    // Create individual assignments
    for (final member in members) {
      await insert('game_assignments', {
        'game_id': gameId,
        'official_id': member.officialId,
        'position': member.gamePosition,
        'status': 'accepted', // Crew chief accepted on behalf of crew
        'assigned_by': assignment['assigned_by'],
        'assigned_at': assignment['assigned_at'],
        'responded_at': assignment['responded_at'],
        'fee_amount': paymentMethod == 'equal_split' ? individualFee : null,
      });
    }
    
    // Update game officials hired count
    await rawQuery('''
      UPDATE games 
      SET officials_hired = officials_hired + ?
      WHERE id = ?
    ''', [members.length, gameId]);
  }
  
  // Utility method to check if official is crew chief
  Future<bool> isCrewChief(int officialId, int crewId) async {
    final results = await rawQuery('''
      SELECT 1 FROM crews 
      WHERE id = ? AND crew_chief_id = ? AND is_active = 1
    ''', [crewId, officialId]);
    
    return results.isNotEmpty;
  }
  
  // Get available crews for a specific game
  Future<List<Crew>> getAvailableCrewsForGame(int sportId, String level, 
                                               DateTime gameDate, TimeOfDay gameTime) async {
    final results = await rawQuery('''
      SELECT c.*, ct.required_officials, ct.level_of_competition,
             s.name as sport_name, o.name as crew_chief_name,
             COUNT(cm.id) as current_members,
             CASE WHEN ca.status IS NULL THEN 'available'
                  ELSE ca.status END as availability_status
      FROM crews c
      JOIN crew_types ct ON c.crew_type_id = ct.id
      JOIN sports s ON ct.sport_id = s.id
      JOIN officials o ON c.crew_chief_id = o.id
      LEFT JOIN crew_members cm ON c.id = cm.crew_id AND cm.status = 'active'
      LEFT JOIN crew_availability ca ON c.id = ca.crew_id AND ca.date = ?
      WHERE ct.sport_id = ? 
        AND ct.level_of_competition = ?
        AND c.is_active = 1
        AND c.id NOT IN (
          SELECT crew_id FROM crew_assignments 
          WHERE game_id IN (
            SELECT id FROM games 
            WHERE date = ? AND time = ? AND status != 'cancelled'
          )
        )
      GROUP BY c.id
      HAVING current_members = ct.required_officials
        AND (ca.status IS NULL OR ca.status = 'available')
      ORDER BY c.name
    ''', [gameDate.toIso8601String().split('T')[0], sportId, level, 
          gameDate.toIso8601String().split('T')[0], 
          '${gameTime.hour.toString().padLeft(2, '0')}:${gameTime.minute.toString().padLeft(2, '0')}']);
    
    return results.map((data) => Crew.fromMap(data)).toList();
  }

  // Crew invitation management
  Future<int> createCrewInvitation(CrewInvitation invitation) async {
    return await insert('crew_invitations', invitation.toMap());
  }

  Future<List<CrewInvitation>> getPendingInvitations(int officialId) async {
    final results = await rawQuery('''
      SELECT ci.*, c.name as crew_name, 
             inviter.name as inviter_name,
             ct.level_of_competition, s.name as sport_name
      FROM crew_invitations ci
      JOIN crews c ON ci.crew_id = c.id
      JOIN officials inviter ON ci.invited_by = inviter.id
      JOIN crew_types ct ON c.crew_type_id = ct.id
      JOIN sports s ON ct.sport_id = s.id
      WHERE ci.invited_official_id = ? AND ci.status = 'pending'
      ORDER BY ci.invited_at DESC
    ''', [officialId]);
    
    return results.map((data) => CrewInvitation.fromMap(data)).toList();
  }

  Future<List<CrewInvitation>> getCrewInvitations(int crewId) async {
    final results = await rawQuery('''
      SELECT ci.*, 
             invited_official.name as invited_official_name,
             inviter.name as inviter_name
      FROM crew_invitations ci
      JOIN officials invited_official ON ci.invited_official_id = invited_official.id
      JOIN officials inviter ON ci.invited_by = inviter.id
      WHERE ci.crew_id = ?
      ORDER BY ci.invited_at DESC
    ''', [crewId]);
    
    return results.map((data) => CrewInvitation.fromMap(data)).toList();
  }

  Future<int> respondToInvitation(int invitationId, String status, String? notes, int respondingOfficialId) async {
    final result = await update('crew_invitations', {
      'status': status,
      'responded_at': DateTime.now().toIso8601String(),
      'response_notes': notes,
    }, 'id = ? AND invited_official_id = ?', [invitationId, respondingOfficialId]);

    // If accepted, add as crew member
    if (status == 'accepted') {
      final invitation = await rawQuery('''
        SELECT * FROM crew_invitations WHERE id = ?
      ''', [invitationId]);

      if (invitation.isNotEmpty) {
        final inv = invitation.first;
        await addCrewMember(
          inv['crew_id'],
          inv['invited_official_id'],
          inv['position'] ?? 'member',
          inv['game_position'],
        );
      }
    }

    return result;
  }

  Future<bool> hasInvitation(int crewId, int officialId) async {
    final results = await rawQuery('''
      SELECT 1 FROM crew_invitations 
      WHERE crew_id = ? AND invited_official_id = ? AND status = 'pending'
    ''', [crewId, officialId]);
    
    return results.isNotEmpty;
  }

  // Crew deletion (only for crew chiefs)
  Future<void> deleteCrew(int crewId, int crewChiefId) async {
    // Verify the official is the crew chief
    final isChief = await isCrewChief(crewChiefId, crewId);
    if (!isChief) {
      throw Exception('Only crew chiefs can delete crews');
    }

    // Check if crew has any accepted assignments
    final assignments = await rawQuery('''
      SELECT 1 FROM crew_assignments 
      WHERE crew_id = ? AND status = 'accepted'
      LIMIT 1
    ''', [crewId]);

    if (assignments.isNotEmpty) {
      throw Exception('Cannot delete crew with accepted game assignments');
    }

    // Delete all related records in order (to respect foreign key constraints)
    
    // 1. Delete crew invitations
    await rawDelete('''
      DELETE FROM crew_invitations WHERE crew_id = ?
    ''', [crewId]);

    // 2. Delete crew availability records
    await rawDelete('''
      DELETE FROM crew_availability WHERE crew_id = ?
    ''', [crewId]);

    // 3. Delete crew members
    await rawDelete('''
      DELETE FROM crew_members WHERE crew_id = ?
    ''', [crewId]);

    // 4. Delete pending crew assignments
    await rawDelete('''
      DELETE FROM crew_assignments WHERE crew_id = ? AND status != 'accepted'
    ''', [crewId]);

    // 5. Delete payment distributions for any crew assignments
    await rawDelete('''
      DELETE FROM crew_payment_distributions 
      WHERE crew_assignment_id IN (
        SELECT id FROM crew_assignments WHERE crew_id = ?
      )
    ''', [crewId]);

    // 6. Finally delete the crew itself
    await rawDelete('''
      DELETE FROM crews WHERE id = ? AND crew_chief_id = ?
    ''', [crewId, crewChiefId]);
  }

  // Advanced filtering methods for crew search
  Future<List<Crew>> getFilteredCrews({
    List<String>? ihsaCertifications,
    List<String>? competitionLevels,
    int? maxDistanceMiles,
    Map<String, dynamic>? gameLocation,
  }) async {
    // Start with all active crews with members loaded
    List<Crew> allCrews = await getAllCrews();
    
    // Filter by certification level (lowest common level logic)
    if (ihsaCertifications != null && ihsaCertifications.isNotEmpty) {
      List<Crew> certifiedCrews = [];
      for (final crew in allCrews) {
        if (await _crewMeetsIHSACertification(crew, ihsaCertifications)) {
          certifiedCrews.add(crew);
        }
      }
      allCrews = certifiedCrews;
    }
    
    // Filter by competition levels
    if (competitionLevels != null && competitionLevels.isNotEmpty) {
      allCrews = allCrews.where((crew) {
        if (crew.competitionLevels == null || crew.competitionLevels!.isEmpty) {
          return false;
        }
        // Check if any of the crew's selected levels match the filter
        return crew.competitionLevels!.any((crewLevel) =>
          competitionLevels.contains(crewLevel));
      }).toList();
    }
    
    // Filter by distance (using crew chief's address)
    if (maxDistanceMiles != null && gameLocation != null) {
      List<Crew> nearbyCrews = [];
      for (final crew in allCrews) {
        if (await _crewWithinDistance(crew, gameLocation, maxDistanceMiles)) {
          nearbyCrews.add(crew);
        }
      }
      allCrews = nearbyCrews;
    }
    
    // Only return crews that can be hired (fully staffed and active)
    return allCrews.where((crew) => crew.canBeHired).toList();
  }

  // Check if crew meets IHSA certification requirements (lowest common level)
  Future<bool> _crewMeetsIHSACertification(Crew crew, List<String> requiredCertifications) async {
    if (crew.members == null || crew.members!.isEmpty) {
      return false;
    }

    // Get certification levels for all crew members
    final memberCertifications = <String>[];
    for (final member in crew.members!) {
      final certification = await _getOfficialCertification(member.officialId);
      if (certification != null) {
        memberCertifications.add(certification);
      }
    }

    if (memberCertifications.isEmpty) {
      return false;
    }

    // Find the lowest common certification level
    final lowestLevel = _findLowestCertificationLevel(memberCertifications);
    
    // Check if the lowest level meets any of the required certifications
    return requiredCertifications.contains(lowestLevel) || 
           _certificationMeetsRequirement(lowestLevel, requiredCertifications);
  }

  Future<String?> _getOfficialCertification(int officialId) async {
    final results = await rawQuery('''
      SELECT certification_level FROM officials WHERE id = ?
    ''', [officialId]);
    
    if (results.isNotEmpty) {
      return results.first['certification_level'] as String?;
    }
    return null;
  }

  String _findLowestCertificationLevel(List<String> certifications) {
    // IHSA hierarchy: Certified > Recognized > Registered
    // Return the lowest level that all members have
    
    final certificationHierarchy = ['IHSA Registered', 'IHSA Recognized', 'IHSA Certified'];
    
    // Count how many officials have each level
    final certCounts = <String, int>{};
    for (final cert in certifications) {
      certCounts[cert] = (certCounts[cert] ?? 0) + 1;
    }
    
    final totalMembers = certifications.length;
    
    // Find the highest level that ALL members have
    for (int i = certificationHierarchy.length - 1; i >= 0; i--) {
      final level = certificationHierarchy[i];
      int membersWithThisLevelOrHigher = 0;
      
      // Count members who have this level or higher
      for (int j = i; j < certificationHierarchy.length; j++) {
        membersWithThisLevelOrHigher += certCounts[certificationHierarchy[j]] ?? 0;
      }
      
      if (membersWithThisLevelOrHigher == totalMembers) {
        return level;
      }
    }
    
    // Default to lowest if no common level found
    return 'IHSA Registered';
  }

  bool _certificationMeetsRequirement(String actualLevel, List<String> requiredLevels) {
    // Define the hierarchy order
    final hierarchy = {
      'IHSA Registered': 1,
      'IHSA Recognized': 2, 
      'IHSA Certified': 3,
    };
    
    final actualValue = hierarchy[actualLevel] ?? 0;
    
    // Check if actual level meets any of the required levels
    for (final required in requiredLevels) {
      final requiredValue = hierarchy[required] ?? 0;
      if (actualValue >= requiredValue) {
        return true;
      }
    }
    
    return false;
  }

  // Check if crew chief is within distance of game location
  Future<bool> _crewWithinDistance(Crew crew, Map<String, dynamic> gameLocation, int maxMiles) async {
    try {
      // Get crew chief's address
      final crewChiefAddress = await _getCrewChiefAddress(crew.crewChiefId);
      if (crewChiefAddress == null) {
        return false; // No address available
      }
      
      // For now, return true - actual distance calculation would require geocoding
      // TODO: Implement actual distance calculation using geocoding service
      print('Distance filtering: Crew chief at $crewChiefAddress, Game at ${gameLocation['address']}, Max: ${maxMiles}mi');
      return true;
    } catch (e) {
      print('Error calculating distance for crew ${crew.id}: $e');
      return false;
    }
  }

  Future<String?> _getCrewChiefAddress(int crewChiefId) async {
    // Try to get address from officials table first
    final officialResults = await rawQuery('''
      SELECT o.*, u.school_address as user_address
      FROM officials o
      LEFT JOIN users u ON o.user_id = u.id
      WHERE o.id = ?
    ''', [crewChiefId]);
    
    if (officialResults.isNotEmpty) {
      final official = officialResults.first;
      // Return user address if available, otherwise could add official-specific address
      return official['user_address'] as String?;
    }
    
    return null;
  }
}