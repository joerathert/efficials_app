import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/theme.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/repositories/endorsement_repository.dart';
import '../../shared/services/repositories/user_repository.dart';
import '../../shared/services/verification_service.dart';
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
  bool hasEndorsedThisOfficial =
      false; // Track if current user has endorsed this official
  bool isCurrentUserScheduler = false; // Track if current user is a scheduler
  bool _isLoading = true;
  bool _isProcessingEndorsement = false; // Prevent double-clicking endorsement button
  bool _hasLoadedOtherProfileData =
      false; // Track if other profile data has been loaded
  bool _isVerificationExpanded = false; // Track if verification section is expanded
  Official? _currentOfficial;

  // Repositories and services
  final OfficialRepository _officialRepo = OfficialRepository();
  final EndorsementRepository _endorsementRepo = EndorsementRepository();
  final UserRepository _userRepo = UserRepository();
  final VerificationService _verificationService = VerificationService();

  // Profile data will be loaded from the database
  Map<String, dynamic> profileData = {};
  List<Map<String, dynamic>> sports = [];

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
    print('Received arguments in official profile: $args');
    if (args != null &&
        args is Map<String, dynamic> &&
        !_hasLoadedOtherProfileData) {
      otherOfficialData = args;
      isViewingOwnProfile = false;
      print('Setting up other official profile with data: $otherOfficialData');

      // Validate the data
      if (otherOfficialData?['id'] == null) {
        print('Error: Official ID is missing from arguments');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Official profile data is incomplete'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
          return;
        }
      }

      // Get the show career stats preference from the other official's data
      showCareerStatistics = otherOfficialData?['showCareerStats'] ?? false;

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
      final officialId = otherOfficialData?['id'];
      print('Loading endorsement data for official ID: $officialId');

      if (officialId != null) {
        // Get endorsement counts for the other official
        final endorsementCounts =
            await _endorsementRepo.getEndorsementCounts(officialId);
        print('Endorsement counts retrieved: $endorsementCounts');

        // Update the other official's data with real endorsement counts
        setState(() {
          otherOfficialData?['schedulerEndorsements'] =
              endorsementCounts['schedulerEndorsements'] ?? 0;
          otherOfficialData?['officialEndorsements'] =
              endorsementCounts['officialEndorsements'] ?? 0;
        });
        print(
            'Updated endorsement counts in UI: Scheduler=${otherOfficialData?['schedulerEndorsements']}, Official=${otherOfficialData?['officialEndorsements']}');

        // Check if current user has endorsed this official
        final userSession = UserSessionService.instance;
        final currentUserId = await userSession.getCurrentUserId();
        if (currentUserId != null) {
          final hasEndorsed = await _endorsementRepo.hasUserEndorsedOfficial(
            endorsedOfficialId: officialId,
            endorserUserId: currentUserId,
          );
          print(
              'Current user (ID: $currentUserId) has endorsed this official: $hasEndorsed');

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
      _currentOfficial =
          await _officialRepo.getOfficialByOfficialUserId(userId);

      if (_currentOfficial == null) {
        // Handle error - no official record found
        return;
      }

      // Get the official user record for verification status
      final officialUser = await _officialRepo.getOfficialUserById(userId);

      // Get endorsement counts from the database
      final endorsementCounts =
          await _endorsementRepo.getEndorsementCounts(_currentOfficial!.id!);

      // Load settings from database
      final showCareerStats = await _userRepo
          .getBoolSetting(userId, 'showCareerStats', defaultValue: true);
      final savedNotificationSettings =
          await _userRepo.getJsonSetting(userId, 'notificationSettings');
      
      // Load profile-specific settings with defaults
      final maxTravelDistance = await _userRepo.getIntSetting(userId, 'maxTravelDistance') ?? 999;
      final ratePerGame = await _userRepo.getDoubleSetting(userId, 'ratePerGame') ?? 0.0;
      final locationSetting = await _userRepo.getSetting(userId, 'location');
      final location = locationSetting ?? '${_currentOfficial!.city ?? ''}, ${_currentOfficial!.state ?? 'IL'}';
      
      // Load sports data from database
      await _loadSportsData();

      // Update notification settings if loaded from DB
      if (savedNotificationSettings != null) {
        setState(() {
          notificationSettings.clear();
          notificationSettings.addAll(savedNotificationSettings
              .map((key, value) => MapEntry(key, value as bool)));
        });
      }

      // Populate profile data from the database
      profileData = {
        'name': _currentOfficial!.name ?? 'Unknown Official',
        'email': _currentOfficial!.email ?? 'No email',
        'phone': _currentOfficial!.phone ?? 'No phone',
        'location': location.trim().isEmpty ? 'No location' : location,
        'experienceYears': _currentOfficial!.experienceYears ?? 0,
        'certificationLevel': _currentOfficial!.certificationLevel ?? 'N/A',
        'ratePerGame': ratePerGame,
        'maxTravelDistance': maxTravelDistance,
        'joinedDate': _currentOfficial!.createdAt ?? DateTime.now(),
        'totalGames': _currentOfficial!.totalAcceptedGames ?? 0,
        'schedulerEndorsements':
            endorsementCounts['schedulerEndorsements'] ?? 0,
        'officialEndorsements': endorsementCounts['officialEndorsements'] ?? 0,
        'profileVerified': officialUser?.profileVerified ?? false,
        'emailVerified': officialUser?.emailVerified ?? false,
        'phoneVerified': officialUser?.phoneVerified ?? false,
        'showCareerStats': showCareerStats,
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

  Future<void> _loadSportsData() async {
    if (_currentOfficial?.id == null) return;
    
    try {
      // Load sports data for this official from official_sports table
      final results = await _officialRepo.rawQuery('''
        SELECT 
          s.name as sport_name,
          os.certification_level,
          os.years_experience,
          os.is_primary
        FROM official_sports os
        JOIN sports s ON os.sport_id = s.id
        WHERE os.official_id = ?
        ORDER BY os.is_primary DESC, s.name ASC
      ''', [_currentOfficial!.id]);
      
      setState(() {
        sports = results.map((row) => {
          'name': row['sport_name'] ?? 'Unknown Sport',
          'level': row['certification_level'] ?? 'N/A',
          'years': row['years_experience'] ?? 0,
          'isPrimary': (row['is_primary'] as int?) == 1,
        }).toList();
      });
      
      print('Loaded ${sports.length} sports for official ${_currentOfficial!.name}');
    } catch (e) {
      print('Error loading sports data: $e');
      // Fallback to empty list if there's an error
      setState(() {
        sports = [];
      });
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
      isViewingOwnProfile ? profileData : (otherOfficialData ?? {});

  Future<bool> _isViewingCurrentUserProfile() async {
    if (isViewingOwnProfile) return true;
    
    if (otherOfficialData == null) return false;
    
    try {
      final userSession = UserSessionService.instance;
      final currentUserId = await userSession.getCurrentUserId();
      if (currentUserId == null) return false;
      
      final currentUserOfficial = await _officialRepo.getOfficialByOfficialUserId(currentUserId);
      if (currentUserOfficial == null) return false;
      
      return currentUserOfficial.id == otherOfficialData?['id'];
    } catch (e) {
      print('Error checking if viewing current user profile: $e');
      return false;
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'U';
    }

    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) {
      return 'U';
    }

    final initials = nameParts
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .join();

    return initials.isNotEmpty ? initials : 'U';
  }

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
    try {
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
                // Profile Picture with edit button overlay
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: efficialsYellow,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(currentProfileData['name']),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: efficialsBlack,
                          ),
                        ),
                      ),
                    ),
                    if (isViewingOwnProfile)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: efficialsYellow,
                            shape: BoxShape.circle,
                            border: Border.all(color: darkSurface, width: 2),
                          ),
                          child: IconButton(
                            onPressed: () {
                              _showEditProfilePhotoDialog();
                            },
                            icon: const Icon(
                              Icons.edit,
                              size: 14,
                              color: efficialsBlack,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Name and basic info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentProfileData['name'] ?? 'Unknown Official',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: efficialsYellow,
                              ),
                            ),
                          ),
                          if (isViewingOwnProfile)
                            IconButton(
                              onPressed: () {
                                _showEditNameDialog();
                              },
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: efficialsYellow,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
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
                                GestureDetector(
                                  onTap: () =>
                                      _showEndorsersDialog('scheduler'),
                                  child: Row(
                                    children: [
                                      Icon(Icons.thumb_up,
                                          size: 14, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Schedulers: ${currentProfileData['schedulerEndorsements'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[400],
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: () => _showEndorsersDialog('official'),
                                  child: Row(
                                    children: [
                                      Icon(Icons.thumb_up,
                                          size: 14, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Officials: ${currentProfileData['officialEndorsements'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[400],
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Endorse button (for other profiles only)
                if (!isViewingOwnProfile)
                  FutureBuilder<bool>(
                    future: _isViewingCurrentUserProfile(),
                    builder: (context, snapshot) {
                      final isOwnProfile = snapshot.data ?? false;
                      
                      if (isOwnProfile) {
                        // Don't show endorse button if user is viewing their own profile
                        return const SizedBox.shrink();
                      }
                      
                      return IconButton(
                        onPressed: _isProcessingEndorsement ? null : () {
                          if (hasEndorsedThisOfficial) {
                            _showRemoveEndorsementDialog();
                          } else {
                            _showEndorsementDialog();
                          }
                        },
                        icon: Icon(
                          hasEndorsedThisOfficial
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          color: hasEndorsedThisOfficial
                              ? efficialsYellow
                              : Colors.grey[400],
                        ),
                        tooltip: hasEndorsedThisOfficial
                            ? 'Already endorsed'
                            : 'Endorse this official',
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error building profile header: $e');
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: darkSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Text(
              'Error loading profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Unable to load official profile data',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildVerificationStatus() {
    // Calculate overall verification status
    final profileVerified = profileData['profileVerified'] ?? false;
    final emailVerified = profileData['emailVerified'] ?? false;
    final phoneVerified = profileData['phoneVerified'] ?? false;
    final allVerified = profileVerified && emailVerified && phoneVerified;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isVerificationExpanded = !_isVerificationExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Verification Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      allVerified ? Icons.check_circle : Icons.cancel,
                      color: allVerified ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ],
                ),
                Icon(
                  _isVerificationExpanded ? Icons.expand_less : Icons.expand_more,
                  color: efficialsYellow,
                ),
              ],
            ),
          ),
          if (_isVerificationExpanded) ...[
            const SizedBox(height: 12),
            _buildVerificationItem(
              'Profile Verified',
              profileVerified,
              'Your profile has been verified by administrators',
            ),
            _buildVerificationItem(
              'Email Verified',
              emailVerified,
              'Your email address has been confirmed',
            ),
            _buildVerificationItem(
              'Phone Verified',
              phoneVerified,
              'Your phone number has been confirmed',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationItem(
      String title, bool? isVerified, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            (isVerified ?? false) ? Icons.check_circle : Icons.cancel,
            color: (isVerified ?? false) ? Colors.green : Colors.red,
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
          if (!(isVerified ?? false))
            TextButton(
              onPressed: () => _handleVerificationRequest(title),
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
                child: _buildStatItem(
                    'Total Games', '${currentProfileData['totalGames'] ?? 0}'),
              ),
              Expanded(
                child: _buildStatItem('This Season', '12'),
              ),
              Expanded(
                child: _buildStatItem('Experience',
                    '${currentProfileData['experienceYears'] ?? 0} years'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Member Since',
                    '${(currentProfileData['joinedDate'] as DateTime?)?.year ?? DateTime.now().year}'),
              ),
              Expanded(
                child: _buildStatItem('Sports', '${sports.length}'),
              ),
              Expanded(
                child: _buildStatItem('Follow-Through',
                    '${(currentProfileData['followThroughRate'] ?? 100.0).toStringAsFixed(1)}%',
                    isHighlighted:
                        !isViewingOwnProfile && isCurrentUserScheduler),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value,
      {bool isHighlighted = false}) {
    return Container(
      decoration: isHighlighted
          ? BoxDecoration(
              color: efficialsYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: efficialsYellow.withOpacity(0.3), width: 1),
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
              color: isHighlighted
                  ? efficialsYellow.withOpacity(0.8)
                  : Colors.grey[400],
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
                    Navigator.pushNamed(context, '/edit_sports');
                  },
                  child: const Text('Edit',
                      style: TextStyle(color: efficialsYellow)),
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
                Text(
                  sport['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
                    Navigator.pushNamed(context, '/edit_contact');
                  },
                  child: const Text('Edit',
                      style: TextStyle(color: efficialsYellow)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContactItem(Icons.email, 'Email', currentProfileData['email'],
              isClickable: true),
          _buildContactItem(Icons.phone, 'Phone', currentProfileData['phone'],
              isClickable: true),
          _buildContactItem(
              Icons.location_on, 'Location', currentProfileData['location'],
              isClickable: false),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String? value,
      {bool isClickable = false}) {
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
                  onTap: isClickable && !isViewingOwnProfile && value != null
                      ? () => _handleContactTap(label, value!)
                      : null,
                  child: Text(
                    value ?? 'Not provided',
                    style: TextStyle(
                      fontSize: 14,
                      color: isClickable && !isViewingOwnProfile
                          ? efficialsYellow
                          : Colors.white,
                      decoration: isClickable && !isViewingOwnProfile
                          ? TextDecoration.underline
                          : null,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Work Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: efficialsYellow,
                ),
              ),
              IconButton(
                onPressed: () {
                  _showEditWorkPreferencesDialog();
                },
                icon: const Icon(Icons.edit, color: efficialsYellow, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
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
            title: const Text('Email Notifications',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Game assignments and updates',
                style: TextStyle(color: Colors.grey)),
            value: notificationSettings['emailNotifications'] ?? true,
            onChanged: (value) async {
              setState(() {
                notificationSettings['emailNotifications'] = value;
              });
              await _saveNotificationSettings();
            },
            activeColor: efficialsYellow,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('SMS Notifications',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Text messages for urgent updates',
                style: TextStyle(color: Colors.grey)),
            value: notificationSettings['smsNotifications'] ?? false,
            onChanged: (value) async {
              setState(() {
                notificationSettings['smsNotifications'] = value;
              });
              await _saveNotificationSettings();
            },
            activeColor: efficialsYellow,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('App Notifications',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Push notifications in the app',
                style: TextStyle(color: Colors.grey)),
            value: notificationSettings['appNotifications'] ?? true,
            onChanged: (value) async {
              setState(() {
                notificationSettings['appNotifications'] = value;
              });
              await _saveNotificationSettings();
            },
            activeColor: efficialsYellow,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Weekly Digest',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Weekly summary of your activity',
                style: TextStyle(color: Colors.grey)),
            value: notificationSettings['weeklyDigest'] ?? true,
            onChanged: (value) async {
              setState(() {
                notificationSettings['weeklyDigest'] = value;
              });
              await _saveNotificationSettings();
            },
            activeColor: efficialsYellow,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Marketing Emails',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Updates about new features and news',
                style: TextStyle(color: Colors.grey)),
            value: notificationSettings['marketingEmails'] ?? false,
            onChanged: (value) async {
              setState(() {
                notificationSettings['marketingEmails'] = value;
              });
              await _saveNotificationSettings();
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
            child:
                const Text('Cancel', style: TextStyle(color: efficialsYellow)),
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
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Allow other officials to see your career statistics',
          style: TextStyle(color: Colors.grey),
        ),
        value: profileData['showCareerStats'] ?? true,
        onChanged: (value) async {
          setState(() {
            profileData['showCareerStats'] = value;
          });
          await _saveCareerStatsSetting(value);
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
          'Do you want to endorse ${currentProfileData['name'] ?? 'this official'}? This will add to their endorsement count.',
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
            child:
                const Text('Endorse', style: TextStyle(color: efficialsBlack)),
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
          'Do you want to remove your endorsement of ${currentProfileData['name'] ?? 'this official'}? This will decrease their endorsement count.',
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
    if (otherOfficialData == null || _isProcessingEndorsement) return;

    setState(() {
      _isProcessingEndorsement = true;
    });

    try {
      final userSession = UserSessionService.instance;
      final currentUserId = await userSession.getCurrentUserId();
      final officialId = otherOfficialData?['id'];

      print(
          'Handling endorsement: isRemoving=$isRemoving, currentUserId=$currentUserId, officialId=$officialId, isCurrentUserScheduler=$isCurrentUserScheduler');

      if (currentUserId == null || officialId == null) {
        throw Exception('User not logged in or invalid official ID');
      }

      // Check if user is trying to endorse themselves
      // Only prevent self-endorsement for officials, not for schedulers/ADs
      if (!isCurrentUserScheduler) {
        final currentUserOfficial = await _officialRepo.getOfficialByOfficialUserId(currentUserId);
        if (currentUserOfficial != null && currentUserOfficial.id == officialId) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You cannot endorse yourself.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // Double-check the current endorsement status from database to prevent conflicts
      final currentlyEndorsed = await _endorsementRepo.hasUserEndorsedOfficial(
        endorsedOfficialId: officialId,
        endorserUserId: currentUserId,
      );

      // If the user is trying to add an endorsement but already has one, or vice versa
      if (!isRemoving && currentlyEndorsed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already endorsed this official.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (isRemoving && !currentlyEndorsed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have not endorsed this official.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
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
          int currentCount = otherOfficialData?['schedulerEndorsements'] ?? 0;
          print('Current scheduler endorsements: $currentCount');
          if (isRemoving) {
            otherOfficialData?['schedulerEndorsements'] =
                currentCount > 0 ? currentCount - 1 : 0;
          } else {
            otherOfficialData?['schedulerEndorsements'] = currentCount + 1;
          }
          print(
              'Updated scheduler endorsements to: ${otherOfficialData?['schedulerEndorsements']}');
        } else {
          // Current user is an official - update official endorsements
          int currentCount = otherOfficialData?['officialEndorsements'] ?? 0;
          print('Current official endorsements: $currentCount');
          if (isRemoving) {
            otherOfficialData?['officialEndorsements'] =
                currentCount > 0 ? currentCount - 1 : 0;
          } else {
            otherOfficialData?['officialEndorsements'] = currentCount + 1;
          }
          print(
              'Updated official endorsements to: ${otherOfficialData?['officialEndorsements']}');
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

      // Show specific error message based on the error type
      String errorMessage;
      if (e.toString().contains('UNIQUE constraint failed') || 
          e.toString().contains('already endorsed')) {
        errorMessage = 'You have already endorsed this official.';
      } else if (e.toString().contains('cannot endorse yourself')) {
        errorMessage = 'You cannot endorse yourself.';
      } else {
        errorMessage = 'Failed to ${isRemoving ? 'remove' : 'add'} endorsement. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingEndorsement = false;
        });
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

  Future<void> _saveCareerStatsSetting(bool value) async {
    try {
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();

      if (userId != null) {
        await _userRepo.setBoolSetting(userId, 'showCareerStats', value);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Career stats preference saved'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving career stats setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save preference'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();

      if (userId != null) {
        await _userRepo.setJsonSetting(
            userId, 'notificationSettings', notificationSettings);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification settings saved'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving notification settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save notification settings'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getEndorsers(
      int officialId, String endorserType) async {
    try {
      final endorsements =
          await _endorsementRepo.getEndorsementsForOfficial(officialId);
      final filteredEndorsements =
          endorsements.where((e) => e.endorserType == endorserType).toList();

      List<Map<String, dynamic>> endorsers = [];
      for (var endorsement in filteredEndorsements) {
        final user = await _userRepo.getUserById(endorsement.endorserUserId);
        if (user != null) {
          endorsers.add({
            'name': '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
            'type': endorsement.endorserType,
            'date': endorsement.createdAt,
          });
        }
      }

      return endorsers;
    } catch (e) {
      print('Error getting endorsers: $e');
      return [];
    }
  }

  void _showEndorsersDialog(String endorserType) async {
    final officialId =
        isViewingOwnProfile ? _currentOfficial?.id : otherOfficialData?['id'];

    if (officialId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: Text(
          '${endorserType == 'scheduler' ? 'Scheduler' : 'Official'} Endorsements',
          style: const TextStyle(color: efficialsYellow),
        ),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getEndorsers(officialId, endorserType),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: efficialsYellow),
                ),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No ${endorserType} endorsements found',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            final endorsers = snapshot.data!;
            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: endorsers.length,
                itemBuilder: (context, index) {
                  final endorser = endorsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: efficialsYellow,
                      child: Text(
                        _getInitials(endorser['name']),
                        style: const TextStyle(color: efficialsBlack),
                      ),
                    ),
                    title: Text(
                      endorser['name'] ?? 'Unknown User',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      endorser['date'] != null
                          ? 'Endorsed on ${endorser['date'].toString().split(' ')[0]}'
                          : 'Date unknown',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Close', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVerificationRequest(String verificationType) async {
    try {
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();

      if (userId == null) {
        _showErrorMessage('User not logged in');
        return;
      }

      switch (verificationType) {
        case 'Email Verified':
          await _requestEmailVerification(userId);
          break;
        case 'Phone Verified':
          await _requestPhoneVerification(userId);
          break;
        case 'Profile Verified':
          await _requestProfileVerification(userId);
          break;
      }
    } catch (e) {
      print('Error handling verification request: $e');
      _showErrorMessage('Verification request failed. Please try again.');
    }
  }

  Future<void> _requestEmailVerification(int userId) async {
    try {
      // Get the official user's email
      final officialUser = await _officialRepo.getOfficialUserById(userId);
      if (officialUser?.email == null) {
        _showErrorMessage('Email address not found');
        return;
      }

      // Request email verification
      final token = await _verificationService.requestEmailVerification(
          userId, officialUser!.email);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: darkSurface,
          title: const Text(
            'Email Verification Sent',
            style: TextStyle(color: efficialsYellow),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A verification link has been sent to ${officialUser.email}.',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please check your email and click the verification link. The link will expire in 24 hours.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Development Note: Verification token is $token (for testing)',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: efficialsYellow)),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error requesting email verification: $e');
      _showErrorMessage('Failed to send verification email. Please try again.');
    }
  }

  Future<void> _requestPhoneVerification(int userId) async {
    try {
      // Get the official user's phone
      final officialUser = await _officialRepo.getOfficialUserById(userId);
      if (officialUser?.phone == null) {
        _showErrorMessage('Phone number not found');
        return;
      }

      // Request phone verification
      final code = await _verificationService.requestPhoneVerification(
          userId, officialUser!.phone!);

      _showPhoneVerificationDialog(userId, code, officialUser.phone!);
    } catch (e) {
      print('Error requesting phone verification: $e');
      _showErrorMessage('Failed to send verification code. Please try again.');
    }
  }

  void _showPhoneVerificationDialog(
      int userId, String sentCode, String phoneNumber) {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Phone Verification',
          style: TextStyle(color: efficialsYellow),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A verification code has been sent to $phoneNumber.',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please enter the 6-digit code:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter code',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: efficialsYellow),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: efficialsYellow),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Development Note: Code is $sentCode (for testing)',
                style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final enteredCode = codeController.text.trim();
              if (enteredCode.length != 6) {
                _showErrorMessage('Please enter a 6-digit code');
                return;
              }

              try {
                final success =
                    await _verificationService.verifyPhone(userId, enteredCode);
                Navigator.pop(context);

                if (success) {
                  // Reload profile data to show updated verification status
                  await _loadData();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number verified successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  _showErrorMessage('Invalid or expired verification code');
                }
              } catch (e) {
                Navigator.pop(context);
                _showErrorMessage('Verification failed. Please try again.');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: efficialsYellow),
            child:
                const Text('Verify', style: TextStyle(color: efficialsBlack)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestProfileVerification(int userId) async {
    // Profile verification requires admin approval
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Profile Verification',
          style: TextStyle(color: efficialsYellow),
        ),
        content: const Text(
          'Profile verification is done by administrators. Your profile will be reviewed and verified based on your experience, certifications, and game history. This process typically takes 1-3 business days.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitProfileForVerification(userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: efficialsYellow),
            child: const Text('Submit for Review',
                style: TextStyle(color: efficialsBlack)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProfileForVerification(int userId) async {
    try {
      // TODO: Implement admin notification system
      // For now, just show a success message

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Profile submitted for verification. You will be notified once it\'s reviewed.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error submitting profile for verification: $e');
      _showErrorMessage('Failed to submit profile for verification');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController();
    nameController.text = currentProfileData['name'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Edit Name',
          style: TextStyle(color: efficialsYellow),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: efficialsYellow),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: efficialsYellow),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) {
                _showErrorMessage('Name cannot be empty');
                return;
              }
              
              Navigator.pop(context);
              await _updateProfileName(newName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: efficialsYellow),
            child: const Text('Save', style: TextStyle(color: efficialsBlack)),
          ),
        ],
      ),
    );
  }

  void _showEditProfilePhotoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Edit Profile Photo',
          style: TextStyle(color: efficialsYellow),
        ),
        content: const Text(
          'Photo upload functionality will be implemented in a future update. For now, your profile displays your initials.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: efficialsYellow)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfileName(String newName) async {
    try {
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();
      
      if (userId == null || _currentOfficial?.id == null) {
        _showErrorMessage('Unable to update profile');
        return;
      }

      // Update the official's name in the database
      await _officialRepo.rawQuery('''
        UPDATE officials 
        SET name = ? 
        WHERE id = ?
      ''', [newName, _currentOfficial!.id]);

      // Update local state
      setState(() {
        profileData['name'] = newName;
        // Note: Update _currentOfficial would require recreating the object
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile name updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile name: $e');
      _showErrorMessage('Failed to update profile name');
    }
  }

  void _showEditWorkPreferencesDialog() {
    final TextEditingController rateController = TextEditingController();
    final TextEditingController distanceController = TextEditingController();
    
    rateController.text = (currentProfileData['ratePerGame'] as double?)?.toStringAsFixed(0) ?? '0';
    distanceController.text = (currentProfileData['maxTravelDistance'] ?? 0).toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Edit Work Preferences',
          style: TextStyle(color: efficialsYellow),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Rate per Game (\$)',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: efficialsYellow),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: efficialsYellow),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: distanceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Max Travel Distance (miles)',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: efficialsYellow),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: efficialsYellow),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final rateText = rateController.text.trim();
              final distanceText = distanceController.text.trim();
              
              if (rateText.isEmpty || distanceText.isEmpty) {
                _showErrorMessage('Both fields are required');
                return;
              }
              
              final rate = double.tryParse(rateText);
              final distance = int.tryParse(distanceText);
              
              if (rate == null || rate < 0) {
                _showErrorMessage('Invalid rate amount');
                return;
              }
              
              if (distance == null || distance < 0 || distance > 999) {
                _showErrorMessage('Distance must be between 0 and 999 miles');
                return;
              }
              
              Navigator.pop(context);
              await _updateWorkPreferences(rate, distance);
            },
            style: ElevatedButton.styleFrom(backgroundColor: efficialsYellow),
            child: const Text('Save', style: TextStyle(color: efficialsBlack)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWorkPreferences(double rate, int distance) async {
    try {
      final userSession = UserSessionService.instance;
      final userId = await userSession.getCurrentUserId();
      
      if (userId == null) {
        _showErrorMessage('Unable to update preferences');
        return;
      }

      // Save to user settings
      await _userRepo.setSetting(userId, 'ratePerGame', rate.toString());
      await _userRepo.setSetting(userId, 'maxTravelDistance', distance.toString());

      // Update local state
      setState(() {
        profileData['ratePerGame'] = rate;
        profileData['maxTravelDistance'] = distance;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work preferences updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating work preferences: $e');
      _showErrorMessage('Failed to update work preferences');
    }
  }
}
