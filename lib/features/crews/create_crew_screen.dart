import 'package:flutter/material.dart';
import 'dart:convert';
import '../../shared/theme.dart';
import '../../shared/services/repositories/crew_repository.dart';
import '../../shared/services/repositories/official_repository.dart';
import '../../shared/services/user_session_service.dart';
import '../../shared/models/database_models.dart';

class CreateCrewScreen extends StatefulWidget {
  const CreateCrewScreen({super.key});

  @override
  State<CreateCrewScreen> createState() => _CreateCrewScreenState();
}

class _CreateCrewScreenState extends State<CreateCrewScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  final OfficialRepository _officialRepo = OfficialRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<CrewType> _crewTypes = [];
  List<Official> _availableOfficials = [];
  List<Official> _selectedMembers = [];
  CrewType? _selectedCrewType;
  List<String> _selectedCompetitionLevels = [];
  bool _isLoading = true;
  bool _isCreating = false;
  int? _currentUserId;

  final List<String> _competitionLevels = [
    'Grade School (6U-11U)',
    'Middle School (11U-14U)',
    'Underclass (15U-16U)',
    'Junior Varsity (16U-17U)',
    'Varsity (17U-18U)',
    'College',
    'Adult',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userSession = UserSessionService.instance;
      _currentUserId = await userSession.getCurrentUserId();

      final crewTypes = await _crewRepo.getAllCrewTypes();
      final officials = await _officialRepo.getAllOfficials();

      if (mounted) {
        setState(() {
          _crewTypes = crewTypes;
          _availableOfficials = officials;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Failed to load data. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Create New Crew',
          style: TextStyle(color: efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: efficialsWhite),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: efficialsYellow),
            )
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCrewNameField(),
          const SizedBox(height: 24),
          _buildCrewTypeSelector(),
          const SizedBox(height: 24),
          if (_selectedCrewType != null) ...[
            _buildRequiredMembersInfo(),
            const SizedBox(height: 24),
            _buildCompetitionLevelsSelector(),
            const SizedBox(height: 24),
            _buildMemberSelector(),
            const SizedBox(height: 32),
            _buildCreateButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildCrewNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crew Name',
          style: TextStyle(
            color: efficialsWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: efficialsWhite),
          decoration: InputDecoration(
            hintText: 'Enter crew name (e.g., "Smith Football Crew")',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: efficialsBlack,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: efficialsYellow),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a crew name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCrewTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sport',
          style: TextStyle(
            color: efficialsWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: efficialsBlack,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CrewType>(
              value: _selectedCrewType,
              hint: Text(
                'Select sport and crew size',
                style: TextStyle(color: Colors.grey[600]),
              ),
              dropdownColor: efficialsBlack,
              style: const TextStyle(color: efficialsWhite),
              items: _crewTypes.map((crewType) {
                return DropdownMenuItem<CrewType>(
                  value: crewType,
                  child: Text(
                    '${crewType.sportName} - ${crewType.requiredOfficials} Officials',
                  ),
                );
              }).toList(),
              onChanged: (CrewType? newValue) {
                setState(() {
                  _selectedCrewType = newValue;
                  _selectedMembers.clear(); // Reset member selection
                  _selectedCompetitionLevels.clear(); // Reset competition levels
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredMembersInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: efficialsYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: efficialsYellow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: efficialsYellow,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This crew requires exactly ${_selectedCrewType!.requiredOfficials} members including yourself as crew chief.',
              style: const TextStyle(
                color: efficialsWhite,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitionLevelsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Competition Levels',
          style: TextStyle(
            color: efficialsWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the competition levels this crew can officiate:',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _competitionLevels.length,
            itemBuilder: (context, index) {
              final level = _competitionLevels[index];
              final isSelected = _selectedCompetitionLevels.contains(level);

              return CheckboxListTile(
                title: Text(
                  level,
                  style: const TextStyle(color: efficialsWhite),
                ),
                value: isSelected,
                activeColor: efficialsYellow,
                checkColor: efficialsBlack,
                tileColor: isSelected ? efficialsYellow.withOpacity(0.1) : null,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedCompetitionLevels.add(level);
                    } else {
                      _selectedCompetitionLevels.remove(level);
                    }
                  });
                },
              );
            },
          ),
        ),
        if (_selectedCompetitionLevels.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_outlined, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select at least one competition level.',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMemberSelector() {
    final requiredCount = _selectedCrewType!.requiredOfficials;
    final needToSelect = requiredCount - 1; // Subtract 1 for crew chief (current user)

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Crew Members (${_selectedMembers.length} of $needToSelect selected)',
          style: const TextStyle(
            color: efficialsWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You will be the crew chief. Select ${needToSelect - _selectedMembers.length} additional members:',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          clipBehavior: Clip.none,
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _availableOfficials.length,
            itemBuilder: (context, index) {
              final official = _availableOfficials[index];
              final isCurrentUser = official.id == _currentUserId;
              final isSelected = _selectedMembers.contains(official);
              final canSelect = !isCurrentUser && (_selectedMembers.length < needToSelect || isSelected);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? efficialsYellow.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CheckboxListTile(
                  title: Text(
                    isCurrentUser ? "${official.name} (You - Crew Chief)" : official.name,
                    style: TextStyle(
                      color: canSelect ? efficialsWhite : Colors.grey[600],
                    ),
                  ),
                  subtitle: official.phone != null
                      ? Text(
                          official.phone!,
                          style: TextStyle(
                            color: canSelect ? Colors.grey[400] : Colors.grey[700],
                          ),
                        )
                      : null,
                  value: isSelected,
                  activeColor: efficialsYellow,
                  checkColor: efficialsBlack,
                  onChanged: canSelect
                      ? (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedMembers.add(official);
                            } else {
                              _selectedMembers.remove(official);
                            }
                          });
                        }
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    final requiredCount = _selectedCrewType!.requiredOfficials;
    final needToSelect = requiredCount - 1;
    final canCreate = _selectedMembers.length == needToSelect && 
                     _nameController.text.trim().isNotEmpty &&
                     _selectedCompetitionLevels.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canCreate && !_isCreating ? _createCrew : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: efficialsYellow,
          foregroundColor: efficialsBlack,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isCreating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(efficialsBlack),
                ),
              )
            : const Text(
                'Create Crew',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _createCrew() async {
    if (!_formKey.currentState!.validate() || _currentUserId == null) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Create the crew
      final crew = Crew(
        name: _nameController.text.trim(),
        crewTypeId: _selectedCrewType!.id!,
        crewChiefId: _currentUserId!,
        createdBy: _currentUserId!,
        competitionLevels: _selectedCompetitionLevels,
      );

      final crewId = await _crewRepo.createCrew(crew);

      // Add crew chief as a member
      await _crewRepo.addCrewMember(
        crewId,
        _currentUserId!,
        'crew_chief',
        'Crew Chief',
      );

      // Send invitations to selected members (exclude current user since they're already crew chief)
      for (final member in _selectedMembers) {
        if (member.id != _currentUserId) {
          final invitation = CrewInvitation(
            crewId: crewId,
            invitedOfficialId: member.id!,
            invitedBy: _currentUserId!,
            position: 'member',
          );
          await _crewRepo.createCrewInvitation(invitation);
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crew "${crew.name}" created and invitations sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating crew: $e');
      if (mounted) {
        _showErrorDialog('Failed to create crew. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: efficialsBlack,
        title: const Text(
          'Error',
          style: TextStyle(color: efficialsWhite),
        ),
        content: Text(
          message,
          style: const TextStyle(color: efficialsWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: efficialsYellow),
            ),
          ),
        ],
      ),
    );
  }
}