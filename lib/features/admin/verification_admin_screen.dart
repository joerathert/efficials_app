import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/verification_service.dart';
import '../../shared/models/database_models.dart';

class VerificationAdminScreen extends StatefulWidget {
  const VerificationAdminScreen({super.key});

  @override
  State<VerificationAdminScreen> createState() => _VerificationAdminScreenState();
}

class _VerificationAdminScreenState extends State<VerificationAdminScreen> {
  final OfficialRepository _officialRepo = OfficialRepository();
  final VerificationService _verificationService = VerificationService();
  
  List<OfficialUser> _unverifiedOfficials = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUnverifiedOfficials();
  }
  
  Future<void> _loadUnverifiedOfficials() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // For now, we'll get all official users and filter unverified ones
      // In a real implementation, you'd add a method to get only unverified officials
      final allOfficials = await _getUnverifiedOfficials();
      
      setState(() {
        _unverifiedOfficials = allOfficials;
      });
    } catch (e) {
      print('Error loading unverified officials: $e');
      _showErrorMessage('Failed to load officials');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // This is a mock method - in reality you'd add a proper query to the repository
  Future<List<OfficialUser>> _getUnverifiedOfficials() async {
    // Mock implementation - returns officials with incomplete verification
    // In a real app, you'd query the database for unverified officials
    return [];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        iconTheme: const IconThemeData(color: efficialsWhite),
        title: const Text(
          'Verification Admin',
          style: TextStyle(color: efficialsYellow, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: efficialsYellow),
                  SizedBox(height: 16),
                  Text(
                    'Loading officials...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_unverifiedOfficials.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'All officials are verified!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: efficialsYellow,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no officials pending verification.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadUnverifiedOfficials,
      color: efficialsYellow,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _unverifiedOfficials.length,
        itemBuilder: (context, index) {
          final official = _unverifiedOfficials[index];
          return _buildOfficialCard(official);
        },
      ),
    );
  }
  
  Widget _buildOfficialCard(OfficialUser official) {
    return Card(
      color: darkSurface,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and basic info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: efficialsYellow,
                  child: Text(
                    '${official.firstName[0]}${official.lastName[0]}',
                    style: const TextStyle(
                      color: efficialsBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${official.firstName} ${official.lastName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: efficialsYellow,
                        ),
                      ),
                      Text(
                        official.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Verification status
            _buildVerificationStatus(official),
            
            const SizedBox(height: 16),
            
            // Admin actions
            if (!official.profileVerified)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => _denyProfileVerification(official),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Deny'),
                  ),
                  ElevatedButton(
                    onPressed: () => _approveProfileVerification(official),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve Profile'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerificationStatus(OfficialUser official) {
    return Column(
      children: [
        _buildStatusItem(
          'Profile Verified',
          official.profileVerified,
          'Administrative verification of profile completeness',
        ),
        _buildStatusItem(
          'Email Verified',
          official.emailVerified,
          'Email address confirmation',
        ),
        _buildStatusItem(
          'Phone Verified',
          official.phoneVerified,
          'Phone number confirmation',
        ),
      ],
    );
  }
  
  Widget _buildStatusItem(String title, bool isVerified, String description) {
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
        ],
      ),
    );
  }
  
  Future<void> _approveProfileVerification(OfficialUser official) async {
    try {
      await _verificationService.verifyProfile(official.id!, true);
      
      setState(() {
        _unverifiedOfficials.removeWhere((o) => o.id == official.id);
      });
      
      _showSuccessMessage('Profile verified for ${official.firstName} ${official.lastName}');
    } catch (e) {
      print('Error approving profile verification: $e');
      _showErrorMessage('Failed to approve verification');
    }
  }
  
  Future<void> _denyProfileVerification(OfficialUser official) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurface,
        title: const Text(
          'Deny Profile Verification',
          style: TextStyle(color: efficialsYellow),
        ),
        content: Text(
          'Are you sure you want to deny profile verification for ${official.firstName} ${official.lastName}?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deny'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _verificationService.verifyProfile(official.id!, false);
        
        setState(() {
          _unverifiedOfficials.removeWhere((o) => o.id == official.id);
        });
        
        _showErrorMessage('Profile verification denied for ${official.firstName} ${official.lastName}');
      } catch (e) {
        print('Error denying profile verification: $e');
        _showErrorMessage('Failed to deny verification');
      }
    }
  }
  
  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
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
}