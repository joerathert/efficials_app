import 'package:flutter/material.dart';
import '../../shared/theme.dart';

class OfficialProfileScreen extends StatefulWidget {
  const OfficialProfileScreen({super.key});

  @override
  State<OfficialProfileScreen> createState() => _OfficialProfileScreenState();
}

class _OfficialProfileScreenState extends State<OfficialProfileScreen> {
  // Mock profile data
  final Map<String, dynamic> profileData = {
    'name': 'John Smith',
    'email': 'john.smith@email.com',
    'phone': '(555) 123-4567',
    'location': 'Chicago, IL',
    'experienceYears': 8,
    'primarySport': 'Football',
    'certificationLevel': 'IHSA Certified',
    'bio': 'Experienced high school sports official with a passion for fair play and athletic development.',
    'ratePerGame': 60.0,
    'maxTravelDistance': 25,
    'joinedDate': DateTime(2023, 3, 15),
    'totalGames': 47,
    'rating': 4.8,
    'profileVerified': true,
    'emailVerified': true,
    'phoneVerified': false,
  };

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with profile picture and basic info
              _buildProfileHeader(),
              const SizedBox(height: 24),

              // Verification Status
              _buildVerificationStatus(),
              const SizedBox(height: 24),

              // Stats
              _buildStatsSection(),
              const SizedBox(height: 24),

              // Sports & Certifications
              _buildSportsSection(),
              const SizedBox(height: 24),

              // Contact & Location
              _buildContactSection(),
              const SizedBox(height: 24),

              // Preferences
              _buildPreferencesSection(),
              const SizedBox(height: 24),

              // Notification Settings
              _buildNotificationSettings(),
              const SizedBox(height: 24),

              // Account Actions
              _buildAccountActions(),
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
                    profileData['name'].split(' ').map((n) => n[0]).join(),
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
                      profileData['name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: efficialsYellow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profileData['experienceYears']} years experience',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${profileData['rating']} rating',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Edit button
              IconButton(
                onPressed: () {
                  // TODO: Navigate to edit profile
                },
                icon: const Icon(Icons.edit, color: efficialsYellow),
              ),
            ],
          ),
          if (profileData['bio'] != null) ...[
            const SizedBox(height: 16),
            Text(
              profileData['bio'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
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
                child: _buildStatItem('Total Games', '${profileData['totalGames']}'),
              ),
              Expanded(
                child: _buildStatItem('This Season', '12'),
              ),
              Expanded(
                child: _buildStatItem('Average Rating', '${profileData['rating']}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Member Since', '${profileData['joinedDate'].year}'),
              ),
              Expanded(
                child: _buildStatItem('Sports', '${sports.length}'),
              ),
              Expanded(
                child: _buildStatItem('Response Rate', '96%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: efficialsYellow,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
              TextButton(
                onPressed: () {
                  // TODO: Edit contact info
                },
                child: const Text('Edit', style: TextStyle(color: efficialsYellow)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContactItem(Icons.email, 'Email', profileData['email']),
          _buildContactItem(Icons.phone, 'Phone', profileData['phone']),
          _buildContactItem(Icons.location_on, 'Location', profileData['location']),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
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
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
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
            '\$${profileData['ratePerGame'].toStringAsFixed(0)}',
          ),
          _buildPreferenceItem(
            'Max Travel Distance',
            '${profileData['maxTravelDistance']} miles',
          ),
          _buildPreferenceItem(
            'Primary Sport',
            profileData['primarySport'],
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
}