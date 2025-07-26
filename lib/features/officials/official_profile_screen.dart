import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/theme.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/repositories/endorsement_repository.dart';
import '../../shared/models/database_models.dart';

class OfficialProfileScreen extends StatefulWidget {
  const OfficialProfileScreen({super.key});

  @override
  State<OfficialProfileScreen> createState() => _OfficialProfileScreenState();
}

class _OfficialProfileScreenState extends State<OfficialProfileScreen> {
  Map<String, dynamic>? otherOfficialData;
  bool isViewingOwnProfile = true;
  bool showCareerStatistics = true;
  bool hasEndorsedThisOfficial = false; // Track if current user has endorsed this official
  bool isCurrentUserScheduler = false; // Track if current user is a scheduler
  bool _isLoading = true;
  bool _hasLoadedOtherProfileData = false; // Track if other profile data has been loaded
  Official? _currentOfficial;
  
  // Repositories
  final OfficialRepository _officialRepo = OfficialRepository();
  final EndorsementRepository _endorsementRepo = EndorsementRepository();
  
  // Profile data will be loaded from the database
  Map<String, dynamic> profileData = {};

  final List<Map<String, dynamic>> sports = [
    {'name': 'Football', 'level': 'IHSA Certified', 'years': 8, 'isPrimary': true},
    {'name': 'Basketball', 'level': 'IHSA Recognized', 'years': 5, 'isPrimary': false},
    {'name': 'Baseball', 'level': 'IHSA Registered', 'years': 3, 'isPrimary': false},
  ];

  final Map<String, bool> notificationSettings = {
    'emailNotifications': true,
    'smsNotifications': false,
    'appNotifications': true,
    'weeklyDigest': true,
    'marketingEmails': false,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if arguments were passed (viewing another official's profile)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic> && !_hasLoadedOtherProfileData) {
      otherOfficialData = args;
      isViewingOwnProfile = false;
      // Get the show career stats preference from the other official's data
      showCareerStatistics = otherOfficialData!['showCareerStats'] ?? false;
      
      // Load endorsement data for the other profile
      _loadOtherProfileEndorsementData();
      _hasLoadedOtherProfileData = true;
    }
    
    // Check if current user is a scheduler
    _checkCurrentUserType();
  }
  
  Future<void> _loadOtherProfileEndorsementData() async {
    if (otherOfficialData == null) return;
    
    try {
      final officialId = otherOfficialData!['id'];
      print('Loading endorsement data for official ID: $officialId');
      
      if (officialId != null) {
        // Get endorsement counts for the other official
        final endorsementCounts = await _endorsementRepo.getEndorsementCounts(officialId);
        print('Endorsement counts retrieved: $endorsementCounts');
        
        // Update the other official's data with real endorsement counts
        setState(() {
          otherOfficialData!['schedulerEndorsements'] = endorsementCounts['schedulerEndorsements'] ?? 0;
          otherOfficialData!['officialEndorsements'] = endorsementCounts['officialEndorsements'] ?? 0;
        });
        print('Updated endorsement counts in UI: Scheduler=${otherOfficialData!['schedulerEndorsements']}, Official=${otherOfficialData!['officialEndorsements']}');
        
        // Check if current user has endorsed this official
        final userSession = UserSessionService.instance;
        final currentUserId = await userSession.getCurrentUserId();
        if (currentUserId != null) {
          final hasEndorsed = await _endorsementRepo.hasUserEndorsedOfficial(
            endorsedOfficialId: officialId,
            endorserUserId: currentUserId,
          );
          print('Current user (ID: $currentUserId) has endorsed this official: $hasEndorsed');
          
          setState(() {
            hasEndorsedThisOfficial = hasEndorsed;
          });
        }
      }
    } catch (e) {
      print('Error loading other profile endorsement data: $e');
    }
  }
  
  Future<void> _loadData() async {
    if (!isViewingOwnProfile) return; // Don't load if viewing another profile
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get current user session
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();
      final userType = await userSession.getCurrentUserType();
      
      if (userId == null || userType != 'official') {
        // Handle error - redirect to login or show error
        return;
      }
      
      // Get the official record
      _currentOfficial = await _officialRepo.getOfficialByOfficialUserId(userId);
      
      if (_currentOfficial == null) {
        // Handle error - no official record found
        return;
      }
      
      // Get endorsement counts from the database
      final endorsementCounts = await _endorsementRepo.getEndorsementCounts(_currentOfficial!.id!);
      
      // Populate profile data from the database
      profileData = {
        'name': _currentOfficial!.name ?? 'Unknown Official',
        'email': _currentOfficial!.email ?? 'No email',
        'phone': _currentOfficial!.phone ?? 'No phone',
        'location': 'No location', // Not available in Official model - could be stored in settings
        'experienceYears': _currentOfficial!.experienceYears ?? 0,
        'primarySport': _currentOfficial!.sportName ?? 'N/A', // Use sportName from joined data
        'certificationLevel': _currentOfficial!.certificationLevel ?? 'N/A',
        'ratePerGame': 0.0, // Not available in Official model - could be stored in settings
        'maxTravelDistance': 0, // Not available in Official model - could be stored in settings
        'joinedDate': _currentOfficial!.createdAt ?? DateTime.now(),
        'totalGames': _currentOfficial!.totalAcceptedGames ?? 0,
        'schedulerEndorsements': endorsementCounts['schedulerEndorsements'] ?? 0,
        'officialEndorsements': endorsementCounts['officialEndorsements'] ?? 0,
        'profileVerified': false, // These are in OfficialUser model, not Official
        'emailVerified': false, // These are in OfficialUser model, not Official
        'phoneVerified': false, // These are in OfficialUser model, not Official
        'showCareerStats': true, // Default to true for now
        'followThroughRate': _currentOfficial!.followThroughRate ?? 100.0,
      };
      
    } catch (e) {
      print('Error loading official profile data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _checkCurrentUserType() async {
    try {
      final userSession = UserSessionService.instance;
      final userType = await userSession.getCurrentUserType();
      setState(() {
        isCurrentUserScheduler = userType == 'scheduler';
      });
    } catch (e) {
      print('Error checking user type: $e');
      // Default to false if error occurs
      setState(() {
        isCurrentUserScheduler = false;
      });
    }
  }

  Map<String, dynamic> get currentProfileData => 
      isViewingOwnProfile ? profileData : otherOfficialData!;

  @override
  Widget build(BuildContext context) {
    if (_isLoading && isViewingOwnProfile) {
      return Scaffold(
        backgroundColor: darkBackground,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: efficialsYellow),
              SizedBox(height: 16),
              Text(
                'Loading your profile...',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: !isViewingOwnProfile 
          ? AppBar(
              backgroundColor: efficialsBlack,
              iconTheme: const IconThemeData(color: efficialsWhite),
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with profile picture and basic info
              _buildProfileHeader(),
              const SizedBox(height: 24),

              // Verification Status (only for own profile)
              if (isViewingOwnProfile) ...[
                _buildVerificationStatus(),
                const SizedBox(height: 24),
              ],

              // Stats (show if own profile or if other official allows it)
              if (isViewingOwnProfile || showCareerStatistics) ...[
                _buildStatsSection(),
                const SizedBox(height: 24),
              ],

              // Career Statistics Toggle (only for own profile)
              if (isViewingOwnProfile) ...[  
                _buildCareerStatsToggle(),
                const SizedBox(height: 24),
              ],

              // Sports & Certifications
              _buildSportsSection(),
              const SizedBox(height: 24),

              // Contact & Location
              _buildContactSection(),
              const SizedBox(height: 24),

              // Preferences (only for own profile)
              if (isViewingOwnProfile) ...[
                _buildPreferencesSection(),
                const SizedBox(height: 24),
                
                // Notification Settings
                _buildNotificationSettings(),
                const SizedBox(height: 24),
                
                // Account Actions
                _buildAccountActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: efficialsYellow,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    currentProfileData['name']?.split(' ').map((n) => n[0]).join() ?? 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: efficialsBlack,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and basic info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentProfileData['name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentProfileData['experienceYears']} years experience',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Endorsements',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[300],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.thumb_up, size: 14, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Schedulers: ${currentProfileData['schedulerEndorsements'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.thumb_up, size: 14, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Officials: ${currentProfileData['officialEndorsements'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Edit button (only show for own profile) or Endorse button (for other profiles)
              if (isViewingOwnProfile)
                IconButton(
                  onPressed: () {
                    // TODO: Navigate to edit profile
                  },
                  icon: const Icon(Icons.edit, color: efficialsYellow),
                )
              else
                IconButton(
                  onPressed: () {
                    if (hasEndorsedThisOfficial) {
                      _showRemoveEndorsementDialog();
                    } else {
                      _showEndorsementDialog();
                    }
                  },
                  icon: Icon(
                    hasEndorsedThisOfficial ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: hasEndorsedThisOfficial ? efficialsYellow : Colors.grey[400],
                  ),
                  tooltip: hasEndorsedThisOfficial ? 'Already endorsed' : 'Endorse this official',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
          ),
          const SizedBox(height: 12),
          _buildVerificationItem(
            'Profile Verified',
            profileData['profileVerified'],
            'Your profile has been verified by administrators',
          ),
          _buildVerificationItem(
            'Email Verified',
            profileData['emailVerified'],
            'Your email address has been confirmed',
          ),
          _buildVerificationItem(
            'Phone Verified',
            profileData['phoneVerified'],
            'Your phone number has been confirmed',
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(String title, bool isVerified, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.cancel,
            color: isVerified ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (!isVerified)
            TextButton(
              onPressed: () {
                // TODO: Handle verification
              },
              child: const Text(
                'Verify',
                style: TextStyle(color: efficialsYellow),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Career Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total Games', '${currentProfileData['totalGames'] ?? 0}'),
              ),
              Expanded(
                child: _buildStatItem('This Season', '12'),
              ),
              Expanded(
                child: _buildStatItem('Experience', '${currentProfileData['experienceYears'] ?? 0} years'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Member Since', '${(currentProfileData['joinedDate'] as DateTime?)?.year ?? DateTime.now().year}'),
              ),
              Expanded(
                child: _buildStatItem('Sports', '${sports.length}'),
              ),
              Expanded(
                child: _buildStatItem('Follow-Through', '${(currentProfileData['followThroughRate'] ?? 100.0).toStringAsFixed(1)}%', isHighlighted: !isViewingOwnProfile && isCurrentUserScheduler),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isHighlighted = false}) {
    return Container(
      decoration: isHighlighted 
          ? BoxDecoration(
              color: efficialsYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: efficialsYellow.withOpacity(0.3), width: 1),
            )
          : null,
      padding: isHighlighted ? const EdgeInsets.all(8) : null,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? efficialsYellow : efficialsYellow,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted ? efficialsYellow.withOpacity(0.8) : Colors.grey[400],
              fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSportsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sports & Certifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              if (isViewingOwnProfile)
                TextButton(
                  onPressed: () {
                    // TODO: Edit sports
                  },
                  child: const Text('Edit', style: TextStyle(color: efficialsYellow)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...sports.map((sport) => _buildSportItem(sport)).toList(),
        ],
      ),
    );
  }

  Widget _buildSportItem(Map<String, dynamic> sport) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: efficialsBlack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sport['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (sport['isPrimary'])
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: efficialsYellow,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'PRIMARY',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: efficialsBlack,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sport['level'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${sport['years']} years',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contact & Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              if (isViewingOwnProfile)
                TextButton(
                  onPressed: () {
                    // TODO: Edit contact info
                  },
                  child: const Text('Edit', style: TextStyle(color: efficialsYellow)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContactItem(Icons.email, 'Email', currentProfileData['email'], isClickable: true),
          _buildContactItem(Icons.phone, 'Phone', currentProfileData['phone'], isClickable: true),
          _buildContactItem(Icons.location_on, 'Location', currentProfileData['location'], isClickable: false),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value, {bool isClickable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                GestureDetector(
                  onTap: isClickable && !isViewingOwnProfile ? () => _handleContactTap(label, value) : null,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isClickable && !isViewingOwnProfile ? efficialsYellow : Colors.white,
                      decoration: isClickable && !isViewingOwnProfile ? TextDecoration.underline : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Work Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
          ),
          const SizedBox(height: 12),
          _buildPreferenceItem(
            'Rate per Game',
            '\$${(currentProfileData['ratePerGame'] as double?)?.toStringAsFixed(0) ?? '0'}',
          ),
          _buildPreferenceItem(
            'Max Travel Distance',
            '${currentProfileData['maxTravelDistance'] ?? 0} miles',
          ),
          _buildPreferenceItem(
            'Primary Sport',
            currentProfileData['primarySport'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: efficialsYellow,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Email Notifications', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Game assignments and updates', style: TextStyle(color: Colors.grey)),
            value: notificationSettings['emailNotifications']!,
            onChanged: (value) {
              setState(() {
                notificationSettings['emailNotifications'] = value;
              });
            },
            activeColor: efficialsYellow,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('SMS Notifications', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Text messages for urgent updates', style: TextStyle(color: Colors.grey)),
            value: notificationSettings['smsNotifications']!,
            onChanged: (value) {
              setState(() {
                notificationSettings['smsNotifications'] = value;
              });
            },
            activeColor: efficialsYellow,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('App Notifications', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Push notifications in the app', style: TextStyle(color: Colors.grey)),
            value: notificationSettings['appNotifications']!,
            onChanged: (value) {
              setState(() {
                notificationSettings['appNotifications'] = value;
              });
            },
            activeColor: efficialsYellow,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // TODO: Show help/support
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: efficialsYellow,
              side: const BorderSide(color: efficialsYellow),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Help & Support'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // TODO: Show logout confirmation
              _showLogoutDialog();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Sign Out',
          style: TextStyle(color: efficialsYellow),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: efficialsYellow)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Handle logout
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/welcome',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerStatsToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: const Text(
          'Show Career Statistics',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Allow other officials to see your career statistics',
          style: TextStyle(color: Colors.grey),
        ),
        value: profileData['showCareerStats'] ?? true,
        onChanged: (value) {
          setState(() {
            profileData['showCareerStats'] = value;
          });
          // TODO: Save this preference to the database
        },
        activeColor: efficialsYellow,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _showEndorsementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Center(
          child: Text(
            'Endorse Official',
            style: TextStyle(color: efficialsYellow),
          ),
        ),
        content: Text(
          'Do you want to endorse ${currentProfileData['name']}? This will add to their endorsement count.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleEndorsement(isRemoving: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: efficialsYellow),
            child: const Text('Endorse', style: TextStyle(color: efficialsBlack)),
          ),
        ],
      ),
    );
  }

  void _showRemoveEndorsementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Center(
          child: Text(
            'Remove Endorsement',
            style: TextStyle(color: efficialsYellow),
          ),
        ),
        content: Text(
          'Do you want to remove your endorsement of ${currentProfileData['name']}? This will decrease their endorsement count.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleEndorsement(isRemoving: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleEndorsement({required bool isRemoving}) async {
    if (otherOfficialData == null) return;
    
    try {
      final userSession = UserSessionService.instance;
      final currentUserId = await userSession.getCurrentUserId();
      final officialId = otherOfficialData!['id'];
      
      print('Handling endorsement: isRemoving=$isRemoving, currentUserId=$currentUserId, officialId=$officialId, isCurrentUserScheduler=$isCurrentUserScheduler');
      
      if (currentUserId == null || officialId == null) {
        throw Exception('User not logged in or invalid official ID');
      }
      
      if (isRemoving) {
        // Remove endorsement from database
        print('Removing endorsement from database...');
        await _endorsementRepo.removeEndorsement(
          endorsedOfficialId: officialId,
          endorserUserId: currentUserId,
        );
        print('Endorsement removed from database');
      } else {
        // Add endorsement to database
        final endorserType = isCurrentUserScheduler ? 'scheduler' : 'official';
        print('Adding endorsement to database with type: $endorserType');
        await _endorsementRepo.addEndorsement(
          endorsedOfficialId: officialId,
          endorserUserId: currentUserId,
          endorserType: endorserType,
        );
        print('Endorsement added to database');
      }
      
      // Update UI state
      setState(() {
        hasEndorsedThisOfficial = !isRemoving;
        
        // Update the appropriate endorsement count based on current user type
        if (isCurrentUserScheduler) {
          // Current user is a scheduler - update scheduler endorsements
          int currentCount = otherOfficialData!['schedulerEndorsements'] ?? 0;
          print('Current scheduler endorsements: $currentCount');
          if (isRemoving) {
            otherOfficialData!['schedulerEndorsements'] = currentCount > 0 ? currentCount - 1 : 0;
          } else {
            otherOfficialData!['schedulerEndorsements'] = currentCount + 1;
          }
          print('Updated scheduler endorsements to: ${otherOfficialData!['schedulerEndorsements']}');
        } else {
          // Current user is an official - update official endorsements
          int currentCount = otherOfficialData!['officialEndorsements'] ?? 0;
          print('Current official endorsements: $currentCount');
          if (isRemoving) {
            otherOfficialData!['officialEndorsements'] = currentCount > 0 ? currentCount - 1 : 0;
          } else {
            otherOfficialData!['officialEndorsements'] = currentCount + 1;
          }
          print('Updated official endorsements to: ${otherOfficialData!['officialEndorsements']}');
        }
      });
      
      String endorserType = isCurrentUserScheduler ? 'Scheduler' : 'Official';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRemoving 
              ? '$endorserType endorsement removed successfully!' 
              : '$endorserType endorsement submitted successfully!'),
          backgroundColor: isRemoving ? Colors.orange : Colors.green,
        ),
      );
      
    } catch (e) {
      print('Error handling endorsement: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isRemoving ? 'remove' : 'add'} endorsement. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleContactTap(String label, String value) async {
    try {
      Uri uri;
      if (label == 'Phone') {
        uri = Uri(scheme: 'sms', path: value);
      } else if (label == 'Email') {
        uri = Uri(scheme: 'mailto', path: value);
      } else {
        return;
      }
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch ${label.toLowerCase()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening ${label.toLowerCase()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}