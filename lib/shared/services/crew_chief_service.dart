import 'package:flutter/material.dart';
import 'repositories/crew_repository.dart';
import 'repositories/game_assignment_repository.dart';
import '../models/database_models.dart';

class CrewChiefService {
  final CrewRepository _crewRepo = CrewRepository();
  final GameAssignmentRepository _assignmentRepo = GameAssignmentRepository();
  
  // Crew Chief Authorization
  Future<bool> isCrewChief(int officialId, int crewId) async {
    return await _crewRepo.isCrewChief(officialId, crewId);
  }
  
  Future<void> _validateCrewChief(int officialId, int crewId) async {
    final isChief = await isCrewChief(officialId, crewId);
    if (!isChief) {
      throw CrewChiefAuthorizationException(
        'Official $officialId is not authorized to manage crew $crewId'
      );
    }
  }
  
  // Crew Availability Management (Crew Chief Only)
  Future<int> setCrewAvailability(int crewId, DateTime date, String status, 
                                  TimeOfDay? startTime, TimeOfDay? endTime, 
                                  String? notes, int crewChiefId) async {
    await _validateCrewChief(crewChiefId, crewId);
    
    return await _crewRepo.setCrewAvailability(
      crewId, date, status, startTime, endTime, notes, crewChiefId
    );
  }
  
  Future<List<CrewAvailability>> getCrewAvailability(int crewId, 
                                                     DateTime startDate, 
                                                     DateTime endDate,
                                                     int crewChiefId) async {
    await _validateCrewChief(crewChiefId, crewId);
    
    return await _crewRepo.getCrewAvailability(crewId, startDate, endDate);
  }
  
  Future<int> setBulkAvailability(int crewId, List<DateTime> dates, 
                                  String status, int crewChiefId) async {
    await _validateCrewChief(crewChiefId, crewId);
    
    int updatedCount = 0;
    for (final date in dates) {
      await _crewRepo.setCrewAvailability(
        crewId, date, status, null, null, null, crewChiefId
      );
      updatedCount++;
    }
    
    return updatedCount;
  }
  
  // Assignment Response (Crew Chief Only)
  Future<int> respondToAssignment(int assignmentId, String response, 
                                  String? notes, int crewChiefId) async {
    // Get assignment details to validate crew chief
    final assignments = await _crewRepo.rawQuery('''
      SELECT crew_id FROM crew_assignments WHERE id = ?
    ''', [assignmentId]);
    
    if (assignments.isEmpty) {
      throw Exception('Assignment not found');
    }
    
    final crewId = assignments.first['crew_id'];
    await _validateCrewChief(crewChiefId, crewId);
    
    return await _crewRepo.respondToCrewAssignment(
      assignmentId, response, notes, crewChiefId
    );
  }
  
  // Member Management (Crew Chief Only)
  Future<int> addCrewMember(int crewId, int officialId, String? gamePosition, 
                            int crewChiefId) async {
    await _validateCrewChief(crewChiefId, crewId);
    
    // Don't allow crew chief to add themselves again
    if (officialId == crewChiefId) {
      throw Exception('Crew chief is already a member of the crew');
    }
    
    return await _crewRepo.addCrewMember(crewId, officialId, 'member', gamePosition);
  }
  
  Future<int> removeCrewMember(int crewId, int officialId, int crewChiefId) async {
    await _validateCrewChief(crewChiefId, crewId);
    
    // Don't allow crew chief to remove themselves
    if (officialId == crewChiefId) {
      throw Exception('Crew chief cannot remove themselves from the crew');
    }
    
    return await _crewRepo.removeCrewMember(crewId, officialId);
  }
  
  Future<List<CrewMember>> getCrewMembers(int crewId, int crewChiefId) async {
    await _validateCrewChief(crewChiefId, crewId);
    
    return await _crewRepo.getCrewMembers(crewId);
  }
  
  // Payment Distribution (Crew Chief Only)
  Future<int> setPaymentDistribution(int crewAssignmentId, 
                                     Map<int, double> officialAmounts, 
                                     int crewChiefId) async {
    // Get crew assignment details
    final assignments = await _crewRepo.rawQuery('''
      SELECT ca.crew_id, ca.total_fee_amount
      FROM crew_assignments ca
      WHERE ca.id = ?
    ''', [crewAssignmentId]);
    
    if (assignments.isEmpty) {
      throw Exception('Crew assignment not found');
    }
    
    final assignment = assignments.first;
    final crewId = assignment['crew_id'];
    final totalFee = assignment['total_fee_amount'] ?? 0.0;
    
    await _validateCrewChief(crewChiefId, crewId);
    
    // Validate distribution totals
    _validatePaymentDistribution(totalFee, officialAmounts);
    
    // Clear existing distributions
    await _crewRepo.delete('crew_payment_distributions', 
      'crew_assignment_id = ?', [crewAssignmentId]);
    
    // Create new distributions
    int createdCount = 0;
    for (final entry in officialAmounts.entries) {
      await _crewRepo.insert('crew_payment_distributions', {
        'crew_assignment_id': crewAssignmentId,
        'official_id': entry.key,
        'amount': entry.value,
        'created_by': crewChiefId,
        'created_at': DateTime.now().toIso8601String(),
      });
      createdCount++;
    }
    
    // Update crew assignment payment method
    await _crewRepo.update('crew_assignments', 
      {'payment_method': 'crew_managed'}, 
      'id = ?', [crewAssignmentId]);
    
    return createdCount;
  }
  
  Future<List<PaymentDistribution>> getPaymentDistribution(int crewAssignmentId, 
                                                           int crewChiefId) async {
    // Validate crew chief authority
    final assignments = await _crewRepo.rawQuery('''
      SELECT crew_id FROM crew_assignments WHERE id = ?
    ''', [crewAssignmentId]);
    
    if (assignments.isNotEmpty) {
      await _validateCrewChief(crewChiefId, assignments.first['crew_id']);
    }
    
    final results = await _crewRepo.rawQuery('''
      SELECT * FROM crew_payment_distributions 
      WHERE crew_assignment_id = ?
      ORDER BY official_id
    ''', [crewAssignmentId]);
    
    return results.map((data) => PaymentDistribution.fromMap(data)).toList();
  }
  
  // Communication with Scheduler
  Future<List<CrewAssignment>> getPendingAssignments(int crewChiefId) async {
    return await _crewRepo.getPendingCrewAssignments(crewChiefId);
  }
  
  Future<int> sendMessageToScheduler(int gameId, String message, int crewChiefId) async {
    // This would integrate with your existing messaging/notification system
    // For now, we'll create a notification record
    
    // Get scheduler for the game
    final gameDetails = await _crewRepo.rawQuery('''
      SELECT user_id as scheduler_id FROM games WHERE id = ?
    ''', [gameId]);
    
    if (gameDetails.isEmpty) {
      throw Exception('Game not found');
    }
    
    // Create a notification (this would integrate with your notification system)
    // For now, we'll just return success
    return 1;
  }
  
  // Crew Performance & Analytics
  Future<Map<String, dynamic>> getCrewPerformanceStats(int crewId, int crewChiefId) async {
    await _validateCrewChief(crewChiefId, crewId);
    
    final stats = await _crewRepo.rawQuery('''
      SELECT 
        COUNT(ca.id) as total_assignments,
        SUM(CASE WHEN ca.status = 'accepted' THEN 1 ELSE 0 END) as accepted_count,
        SUM(CASE WHEN ca.status = 'declined' THEN 1 ELSE 0 END) as declined_count,
        AVG(CASE WHEN ca.total_fee_amount > 0 THEN ca.total_fee_amount ELSE NULL END) as avg_fee
      FROM crew_assignments ca
      WHERE ca.crew_id = ?
    ''', [crewId]);
    
    if (stats.isEmpty) {
      return {
        'total_assignments': 0,
        'accepted_count': 0,
        'declined_count': 0,
        'acceptance_rate': 0.0,
        'avg_fee': 0.0,
      };
    }
    
    final stat = stats.first;
    final totalAssignments = stat['total_assignments'] ?? 0;
    final acceptedCount = stat['accepted_count'] ?? 0;
    
    return {
      'total_assignments': totalAssignments,
      'accepted_count': acceptedCount,
      'declined_count': stat['declined_count'] ?? 0,
      'acceptance_rate': totalAssignments > 0 ? (acceptedCount / totalAssignments) * 100 : 0.0,
      'avg_fee': stat['avg_fee'] ?? 0.0,
    };
  }
  
  // Helper Methods
  void _validatePaymentDistribution(double totalFee, Map<int, double> distributions) {
    final sum = distributions.values.fold(0.0, (a, b) => a + b);
    if ((sum - totalFee).abs() > 0.01) {
      throw PaymentDistributionException(
        'Payment distribution total (\$${sum.toStringAsFixed(2)}) does not match game fee (\$${totalFee.toStringAsFixed(2)})'
      );
    }
    
    for (final amount in distributions.values) {
      if (amount < 0) {
        throw PaymentDistributionException('Payment amounts cannot be negative');
      }
    }
  }
  
  // Get conflicts with individual member schedules (for crew chief awareness)
  Future<List<Map<String, dynamic>>> getMemberConflicts(int crewId, 
                                                         DateTime gameDate,
                                                         int crewChiefId) async {
    await _validateCrewChief(crewChiefId, crewId);
    
    return await _crewRepo.rawQuery('''
      SELECT o.name as official_name, 'Individual Assignment' as conflict_type,
             g.time, g.opponent, s.name as sport_name
      FROM crew_members cm
      JOIN officials o ON cm.official_id = o.id
      JOIN game_assignments ga ON o.id = ga.official_id
      JOIN games g ON ga.game_id = g.id
      JOIN sports s ON g.sport_id = s.id
      WHERE cm.crew_id = ? 
        AND cm.status = 'active'
        AND g.date = ?
        AND ga.status = 'accepted'
      ORDER BY o.name, g.time
    ''', [crewId, gameDate.toIso8601String().split('T')[0]]);
  }
}

// Custom Exceptions
class CrewChiefAuthorizationException implements Exception {
  final String message;
  CrewChiefAuthorizationException(this.message);
  
  @override
  String toString() => 'CrewChiefAuthorizationException: $message';
}

class PaymentDistributionException implements Exception {
  final String message;
  PaymentDistributionException(this.message);
  
  @override
  String toString() => 'PaymentDistributionException: $message';
}

// Equal Split Payment Handler
class EqualSplitPaymentHandler {
  
  static List<PaymentDistribution> calculateEqualSplit(double totalFee, 
                                                       List<CrewMember> members,
                                                       int crewAssignmentId) {
    final amountPerMember = totalFee / members.length;
    return members.map((member) => PaymentDistribution(
      crewAssignmentId: crewAssignmentId,
      officialId: member.officialId,
      amount: amountPerMember,
      createdBy: 0, // System generated
    )).toList();
  }
  
  static bool validateEqualSplit(double totalFee, List<CrewMember> members) {
    if (members.isEmpty) return false;
    final amountPerMember = totalFee / members.length;
    return amountPerMember > 0;
  }
}