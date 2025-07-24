import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme.dart';
import '../../shared/models/database_models.dart';
import '../../shared/services/repositories/game_assignment_repository.dart';
import '../../shared/widgets/back_out_dialog.dart';

class OfficialGameDetailsScreen extends StatefulWidget {
  const OfficialGameDetailsScreen({super.key});

  @override
  State<OfficialGameDetailsScreen> createState() => _OfficialGameDetailsScreenState();
}

class _OfficialGameDetailsScreenState extends State<OfficialGameDetailsScreen> {
  late GameAssignment assignment;
  List<Map<String, dynamic>> otherOfficials = [];
  Map<String, dynamic>? schedulerInfo;
  bool _isLoading = true;
  
  final GameAssignmentRepository _assignmentRepo = GameAssignmentRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assignment = ModalRoute.of(context)!.settings.arguments as GameAssignment;
    _loadGameDetails();
  }

  Future<void> _loadGameDetails() async {
    try {
      setState(() => _isLoading = true);
      
      if (assignment.gameId != null) {
        // Get other officials for this game
        final officials = await _assignmentRepo.getConfirmedOfficialsForGame(assignment.gameId!);
        
        // Get scheduler information 
        final scheduler = await _assignmentRepo.getSchedulerForGame(assignment.gameId!);
        
        setState(() {
          otherOfficials = officials.where((official) => 
            official['id'] != assignment.officialId
          ).toList();
          schedulerInfo = scheduler;
        });
      }
    } catch (e) {
      print('Error loading game details: $e');
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'CONFIRMED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[300],
                  ),
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
                'Other Officials (${otherOfficials.length})',
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
              'You are the only official assigned to this game.',
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
                      color: efficialsYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: efficialsYellow,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Create a more complete profile data structure for the other official
                            final officialId = official['id'] as int;
                            final otherOfficialProfile = {
                              'id': officialId,
                              'name': official['name'],
                              'email': '${official['name'].toLowerCase().replaceAll(' ', '.')}@email.com',
                              'phone': '(555) ${(officialId * 123).toString().padLeft(7, '0').substring(0, 3)}-${(officialId * 456).toString().padLeft(4, '0')}',
                              'location': 'Chicago, IL',
                              'experienceYears': 5 + (officialId % 10),
                              'primarySport': 'Football',
                              'certificationLevel': 'IHSA Certified',
                              'bio': 'Experienced official committed to fair play and sportsmanship.',
                              'totalGames': 30 + (officialId % 50),
                              'rating': 4.2 + ((officialId % 8) * 0.1),
                              'joinedDate': DateTime(2022, (officialId % 12) + 1, (officialId % 28) + 1),
                              'showCareerStats': (officialId % 2) == 0, // Some officials show stats, others don't
                            };
                            
                            Navigator.pushNamed(
                              context,
                              '/official_profile',
                              arguments: otherOfficialProfile,
                            );
                          },
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
                          _getOfficialLocation(official['id'] as int),
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
            onPressed: _getDirections,
            icon: const Icon(Icons.directions, size: 20),
            label: const Text('Get Directions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: efficialsYellow,
              foregroundColor: Colors.black,
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
          child: ElevatedButton.icon(
            onPressed: _showBackOutDialog,
            icon: const Icon(Icons.exit_to_app, size: 20),
            label: const Text('Back Out of Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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

  void _showBackOutDialog() {
    final sportName = assignment.sportName ?? 'Sport';
    final gameDate = assignment.gameDate;
    final gameTime = assignment.gameTime;
    final locationName = assignment.locationName ?? 'TBD';
    
    String gameTitle = _formatAssignmentTitle(assignment);
    String dateString = gameDate != null 
        ? DateFormat('EEEE, MMMM d, yyyy').format(gameDate) 
        : 'TBD';
    String timeString = gameTime != null 
        ? DateFormat('h:mm a').format(gameTime) 
        : 'TBD';
    
    final gameSummary = '$sportName: $gameTitle\n$dateString at $timeString\n$locationName';

    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return BackOutDialog(
          gameSummary: gameSummary,
          onConfirmBackOut: (String reason) => _handleBackOut(reason),
        );
      },
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully backed out of game'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to previous screen
      }
    });
  }

  Future<void> _handleBackOut(String reason) async {
    await _assignmentRepo.backOutOfGame(assignment.id!, reason);
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

  String _getOfficialLocation(int officialId) {
    // Generate consistent city, state based on official ID
    // This is placeholder data until proper location fields are added to the database
    final cities = [
      'Chicago, IL', 'Springfield, IL', 'Peoria, IL', 'Rockford, IL', 
      'Aurora, IL', 'Joliet, IL', 'Naperville, IL', 'Elgin, IL',
      'Waukegan, IL', 'Cicero, IL', 'Champaign, IL', 'Bloomington, IL',
      'Arlington Heights, IL', 'Evanston, IL', 'Decatur, IL'
    ];
    
    return cities[officialId % cities.length];
  }
}