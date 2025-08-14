import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
    
    final routeArgs = ModalRoute.of(context)!.settings.arguments;
    
    if (routeArgs is Map<String, dynamic> && routeArgs.containsKey('assignment')) {
      // Handle the new format that may include linked games info
      assignment = routeArgs['assignment'] as GameAssignment;
      // Additional linked games handling can be added here if needed in the future
    } else {
      // Legacy format - direct GameAssignment
      assignment = routeArgs as GameAssignment;
    }
    
    print('OfficialGameDetailsScreen loaded - Assignment ID: ${assignment.id}');
    print('Assignment sport: ${assignment.sportName}');
    
    // Validate assignment has required data
    if (assignment.id == null) {
      print('WARNING: Assignment ID is null for assignment: ${assignment.toString()}');
    }
    
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
                          onTap: () async {
                            // Create a more complete profile data structure for the other official
                            final officialId = official['id'] as int;
                            final otherOfficialProfile = {
                              'id': officialId,
                              'name': official['name'],
                              'email': '${official['name'].toLowerCase().replaceAll(' ', '.')}@email.com',
                              'phone': '(555) ${(officialId * 123).toString().padLeft(7, '0').substring(0, 3)}-${(officialId * 456).toString().padLeft(4, '0')}',
                              'location': _formatOfficialLocation(official),
                              'experienceYears': 5 + (officialId % 10),
                              'primarySport': 'Football',
                              'certificationLevel': 'IHSA Certified',
                              'bio': 'Experienced official committed to fair play and sportsmanship.',
                              'totalGames': 30 + (officialId % 50),
                              'rating': 4.2 + ((officialId % 8) * 0.1),
                              'joinedDate': DateTime(2022, (officialId % 12) + 1, (officialId % 28) + 1),
                              'showCareerStats': (officialId % 2) == 0, // Some officials show stats, others don't
                              'schedulerEndorsements': 0, // Will be loaded by the profile screen
                              'officialEndorsements': 0, // Will be loaded by the profile screen
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
        if (assignment.id != null) // Only show back out button if assignment has valid ID
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
          )
        else
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Back Out Unavailable (Invalid Assignment)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _getDirections() async {
    final locationName = assignment.locationName;
    final address = assignment.locationAddress;
    
    if (locationName == null && address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location information not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Use address if available, otherwise use location name
    final query = Uri.encodeComponent(address ?? locationName!);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _contactScheduler() async {
    if (schedulerInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduler contact information not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final email = schedulerInfo!['email'] as String?;
    final phone = schedulerInfo!['phone'] as String?;
    final name = schedulerInfo!['name'] as String? ?? 'Scheduler';
    
    if (email == null && phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No contact information available for scheduler'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Always show the contact options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.contact_phone, color: efficialsYellow, size: 24),
            const SizedBox(width: 8),
            Text(
              'Contact $name',
              style: const TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phone != null) ...[
              ListTile(
                leading: const Icon(Icons.message, color: efficialsYellow),
                title: const Text('Send Text Message', style: TextStyle(color: Colors.white)),
                subtitle: Text(phone, style: TextStyle(color: Colors.grey[400])),
                onTap: () {
                  Navigator.pop(context);
                  _launchSMS(phone, name);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: efficialsYellow),
                title: const Text('Call', style: TextStyle(color: Colors.white)),
                subtitle: Text(phone, style: TextStyle(color: Colors.grey[400])),
                onTap: () {
                  Navigator.pop(context);
                  _launchPhone(phone);
                },
              ),
            ],
            if (email != null)
              ListTile(
                leading: const Icon(Icons.email, color: efficialsYellow),
                title: const Text('Send Email', style: TextStyle(color: Colors.white)),
                subtitle: Text(email, style: TextStyle(color: Colors.grey[400])),
                onTap: () {
                  Navigator.pop(context);
                  _launchEmail(email, name);
                },
              ),
            if (phone == null && email == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No contact information available',
                  style: TextStyle(color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _launchEmail(String email, String schedulerName) async {
    final gameTitle = _formatAssignmentTitle(assignment);
    final subject = Uri.encodeComponent('Game Assignment: ${assignment.sportName} - $gameTitle');
    final url = 'mailto:$email?subject=$subject';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch email');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _launchPhone(String phone) async {
    final url = 'tel:$phone';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch phone');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _launchSMS(String phone, String schedulerName) async {
    final gameTitle = _formatAssignmentTitle(assignment);
    final message = Uri.encodeComponent('Hi $schedulerName, this is regarding the ${assignment.sportName} game: $gameTitle');
    final url = 'sms:$phone?body=$message';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch SMS');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open messaging: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          assignmentId: assignment.id,
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
        Navigator.pop(context, true); // Return true to indicate successful back out
      }
    });
  }

  Future<void> _handleBackOut(String reason) async {
    if (assignment.id == null) {
      throw Exception('Assignment ID is null - cannot back out of game');
    }
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

  String _formatOfficialLocation(Map<String, dynamic> official) {
    final city = official['city']?.toString().trim() ?? '';
    final state = official['state']?.toString().trim() ?? '';
    
    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city, $state';
    } else if (city.isNotEmpty) {
      return city;
    } else if (state.isNotEmpty) {
      return state;
    } else {
      return 'Location not specified';
    }
  }
}