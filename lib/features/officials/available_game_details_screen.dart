import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme.dart';
import '../../shared/models/database_models.dart';
import '../../shared/services/repositories/game_assignment_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/user_session_service.dart';

class AvailableGameDetailsScreen extends StatefulWidget {
  const AvailableGameDetailsScreen({super.key});

  @override
  State<AvailableGameDetailsScreen> createState() => _AvailableGameDetailsScreenState();
}

class _AvailableGameDetailsScreenState extends State<AvailableGameDetailsScreen> {
  late GameAssignment assignment;
  List<Map<String, dynamic>> otherOfficials = [];
  Map<String, dynamic>? schedulerInfo;
  bool _isLoading = true;
  bool _hireAutomatically = false;
  
  final GameAssignmentRepository _assignmentRepo = GameAssignmentRepository();
  final OfficialRepository _officialRepo = OfficialRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final routeArgs = ModalRoute.of(context)!.settings.arguments;
    
    if (routeArgs is Map<String, dynamic>) {
      // New format with assignment and scheduler info
      assignment = routeArgs['assignment'] as GameAssignment;
      schedulerInfo = routeArgs['schedulerInfo'] as Map<String, dynamic>?;
      _hireAutomatically = routeArgs['hireAutomatically'] as bool? ?? false;
    } else {
      // Legacy format - just the assignment
      assignment = routeArgs as GameAssignment;
      _hireAutomatically = false; // Default for legacy calls
    }
    
    _loadGameDetails();
  }

  Future<void> _loadGameDetails() async {
    try {
      setState(() => _isLoading = true);
      
      print('Loading game details for gameId: ${assignment.gameId}');
      
      if (assignment.gameId != null && assignment.gameId != 0) {
        try {
          // Get other officials who have already claimed this game
          final officials = await _assignmentRepo.getConfirmedOfficialsForGame(assignment.gameId!);
          print('Found ${officials.length} confirmed officials');
          
          // Get scheduler information 
          final scheduler = await _assignmentRepo.getSchedulerForGame(assignment.gameId!);
          print('Scheduler info: $scheduler');
          
          setState(() {
            otherOfficials = officials;
            schedulerInfo = scheduler;
          });
        } catch (e) {
          print('Error loading game-specific details: $e');
          // Continue without these details
        }
      } else {
        print('No valid gameId available, skipping detailed load');
      }
    } catch (e) {
      print('Error loading available game details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Icon(
          Icons.sports,
          color: efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: efficialsYellow),
          SizedBox(height: 16),
          Text(
            'Loading game details...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGameHeader(),
          const SizedBox(height: 24),
          _buildGameDetails(),
          const SizedBox(height: 24),
          _buildOtherOfficials(),
          const SizedBox(height: 24),
          _buildSchedulerInfo(),
          const SizedBox(height: 24),
          _buildDistanceInfo(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildGameHeader() {
    final sportName = assignment.sportName ?? 'Sport';
    final gameTitle = _formatAssignmentTitle(assignment);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getSportColor(sportName).withOpacity(0.1),
            darkSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getSportColor(sportName).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getSportColor(sportName).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getSportIcon(sportName),
                  color: _getSportColor(sportName),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sportName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow,
                      ),
                    ),
                    Text(
                      gameTitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameDetails() {
    final gameDate = assignment.gameDate != null 
        ? DateFormat('EEEE, MMMM d, yyyy').format(assignment.gameDate!) 
        : 'TBD';
    final gameTime = assignment.gameTime != null 
        ? DateFormat('h:mm a').format(assignment.gameTime!) 
        : 'TBD';
    final locationName = assignment.locationName ?? 'TBD';
    final fee = assignment.feeAmount ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.schedule, 'Date & Time', '$gameDate at $gameTime'),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.location_on, 'Location', locationName),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.attach_money, 'Fee', '\$${fee.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherOfficials() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: efficialsYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Officials Already Confirmed (${otherOfficials.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (otherOfficials.isEmpty)
            Text(
              'No other officials have claimed this game yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            )
          else
            ...otherOfficials.map((official) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _navigateToOfficialProfile(official),
                          child: Text(
                            official['name'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: efficialsYellow,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          _formatOfficialLocation(official),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildSchedulerInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, color: efficialsYellow, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Scheduler Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (schedulerInfo == null)
            Text(
              'Scheduler information not available.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            )
          else
            Column(
              children: [
                _buildContactRow(Icons.person, 'Name', schedulerInfo!['name'] as String? ?? 'Unknown'),
                const SizedBox(height: 12),
                if (schedulerInfo!['email'] != null)
                  _buildContactRow(Icons.email, 'Email', schedulerInfo!['email'] as String),
                if (schedulerInfo!['phone'] != null) ...[
                  const SizedBox(height: 12),
                  _buildContactRow(Icons.phone, 'Phone', schedulerInfo!['phone'] as String),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDistanceInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, color: efficialsYellow, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Distance from Home',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.home, 'Distance', '${_calculateDistance()} miles'),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _hireAutomatically ? _claimGame : _expressInterest,
            icon: Icon(_hireAutomatically ? Icons.check : Icons.add, size: 20),
            label: Text(_hireAutomatically ? 'Claim' : 'Express Interest'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hireAutomatically ? Colors.green : efficialsYellow,
              foregroundColor: _hireAutomatically ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _getDirections,
            icon: const Icon(Icons.directions, size: 20),
            label: const Text('Get Directions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: efficialsYellow,
              side: const BorderSide(color: efficialsYellow),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _contactScheduler,
            icon: const Icon(Icons.message, size: 20),
            label: const Text('Contact Scheduler'),
            style: OutlinedButton.styleFrom(
              foregroundColor: efficialsYellow,
              side: const BorderSide(color: efficialsYellow),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _dismissGame,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            label: const Text('Dismiss Game'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _claimGame() async {
    if (assignment.gameId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to claim game - missing information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final gameId = assignment.gameId!;
    final feeAmount = assignment.feeAmount ?? 0.0;
    
    // Get current user and official info
    final userSession = UserSessionService.instance;
    final userId = await userSession.getCurrentUserId();
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final official = await _officialRepo.getOfficialByOfficialUserId(userId);
    
    if (official?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Official record not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final officialId = official!.id!;
    
    // Show immediate feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Claimed ${assignment.sportName} game'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Persist to database in the background
    try {
      final assignmentId = await _assignmentRepo.claimGame(gameId, officialId, feeAmount);
      debugPrint('Successfully claimed game with assignment ID: $assignmentId');
    } catch (e) {
      debugPrint('Error claiming game: $e');
      if (mounted) {
        String errorMessage = 'Failed to claim game. Please try again.';
        
        // Provide specific error messages for common issues
        if (e.toString().contains('No active crew found for this crew chief')) {
          errorMessage = 'You must be part of an active crew to claim crew-hire games. Please contact your administrator to set up your crew.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _expressInterest() async {
    if (assignment.gameId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to express interest - missing information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final gameId = assignment.gameId!;
    final feeAmount = assignment.feeAmount ?? 0.0;
    
    // Get current user and official info
    final userSession = UserSessionService.instance;
    final userId = await userSession.getCurrentUserId();
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final official = await _officialRepo.getOfficialByOfficialUserId(userId);
    
    if (official?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Official record not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final officialId = official!.id!;
    
    // Show immediate feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Interest expressed in ${assignment.sportName} game'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Persist to database in the background
    try {
      final assignmentId = await _assignmentRepo.expressInterest(gameId, officialId, feeAmount);
      debugPrint('Successfully persisted interest expression to database with ID: $assignmentId');
    } catch (e) {
      debugPrint('Error expressing interest: $e');
      if (mounted) {
        String errorMessage = 'Failed to express interest. Please try again.';
        
        // Provide specific error messages for common issues
        if (e.toString().contains('No active crew found for this crew chief')) {
          errorMessage = 'You must be part of an active crew to express interest in crew-hire games. Please contact your administrator to set up your crew.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _getDirections() {
    // TODO: Implement directions functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Directions feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _contactScheduler() {
    // TODO: Implement contact scheduler functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact scheduler feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _dismissGame() {
    _showDismissDialog();
  }

  void _showDismissDialog() {
    final sportName = assignment.sportName ?? 'Sport';
    final gameTitle = _formatAssignmentTitle(assignment);
    final gameDate = assignment.gameDate != null 
        ? DateFormat('EEEE, MMMM d, yyyy').format(assignment.gameDate!) 
        : 'TBD';
    final gameTime = assignment.gameTime != null 
        ? DateFormat('h:mm a').format(assignment.gameTime!) 
        : 'TBD';
    final locationName = assignment.locationName ?? 'TBD';
    
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        String? selectedReason;
        String? customReason;
        final reasonController = TextEditingController();
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: darkSurface,
              title: const Text(
                'Dismiss Game',
                style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: darkBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$sportName: $gameTitle',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$gameDate at $gameTime',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locationName,
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Why are you dismissing this game? (Optional)',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ...['Not interested in this sport', 'Location too far', 'Time conflict', 'Level not suitable', 'Other'].map((reason) => 
                      RadioListTile<String>(
                        title: Text(reason, style: const TextStyle(color: Colors.white)),
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: efficialsYellow,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                            if (value != 'Other') {
                              customReason = null;
                              reasonController.clear();
                            }
                          });
                        },
                      ),
                    ).toList(),
                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Please specify...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: efficialsYellow),
                          ),
                        ),
                        onChanged: (value) {
                          customReason = value;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => _handleDismiss(
                    selectedReason == 'Other' ? customReason : selectedReason,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Dismiss'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleDismiss(String? reason) async {
    try {
      Navigator.of(context).pop(); // Close dialog
      
      // Get current user and official info
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();
      
      if (userId == null) {
        throw Exception('No user logged in');
      }
      
      final official = await _officialRepo.getOfficialByOfficialUserId(userId);
      
      if (official?.id == null || assignment.gameId == null) {
        throw Exception('Missing required information');
      }
      
      await _assignmentRepo.dismissGame(
        assignment.gameId!,
        official!.id!,
        reason,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game dismissed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Go back to previous screen
      Navigator.of(context).pop();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to dismiss game: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper methods for sports
  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        return Icons.sports_basketball;
      case 'football':
        return Icons.sports_football;
      case 'baseball':
        return Icons.sports_baseball;
      case 'volleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.sports;
    }
  }

  Color _getSportColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        return Colors.orange;
      case 'football':
        return Colors.brown;
      case 'baseball':
        return Colors.blue;
      case 'volleyball':
        return Colors.purple;
      default:
        return efficialsYellow;
    }
  }

  String _formatAssignmentTitle(GameAssignment assignment) {
    final opponent = assignment.opponent;
    final homeTeam = assignment.homeTeam;
    
    if (opponent != null && homeTeam != null) {
      return '$opponent @ $homeTeam';
    } else if (opponent != null) {
      return opponent;
    } else {
      return 'TBD';
    }
  }

  String _formatOfficialLocation(Map<String, dynamic> official) {
    // Use actual location data from the database
    final city = official['city'] as String?;
    final state = official['state'] as String?;
    
    if (city != null && state != null) {
      return '$city, $state';
    } else if (city != null) {
      return '$city, IL'; // Default to IL if state is missing
    } else {
      return 'Location not available';
    }
  }

  String _calculateDistance() {
    // TODO: Implement actual distance calculation based on official's home address
    // For now, return a placeholder based on assignment ID for consistent display
    final distance = 15.0 + ((assignment.id ?? 0) % 20);
    return distance.toStringAsFixed(1);
  }

  void _navigateToOfficialProfile(Map<String, dynamic> official) {
    // Create profile data for the other official
    final profileData = {
      'id': official['id'],
      'name': official['name'],
      'experienceYears': 5, // Default placeholder - could be fetched from database
      'schedulerEndorsements': 0, // Will be loaded in profile screen
      'officialEndorsements': 0, // Will be loaded in profile screen
      'showCareerStats': false, // Default to false for privacy
      'email': 'Contact via platform', // Don't expose email directly
      'phone': 'Contact via platform', // Don't expose phone directly
      'location': _formatOfficialLocation(official),
      'primarySport': 'N/A', // Default placeholder
      'certificationLevel': 'N/A', // Default placeholder
      'totalGames': 0, // Default placeholder
      'followThroughRate': 100.0, // Default placeholder
      'joinedDate': DateTime.now(), // Default placeholder
    };

    Navigator.pushNamed(
      context,
      '/official_profile',
      arguments: profileData,
    );
  }

}