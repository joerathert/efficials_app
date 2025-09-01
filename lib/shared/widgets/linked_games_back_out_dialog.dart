import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/repositories/game_assignment_repository.dart';
import '../models/database_models.dart';
import 'package:intl/intl.dart';

class LinkedGamesBackOutDialog extends StatefulWidget {
  final List<GameAssignment> linkedAssignments;
  final Function(String reason) onConfirmBackOut;

  const LinkedGamesBackOutDialog({
    super.key,
    required this.linkedAssignments,
    required this.onConfirmBackOut,
  });

  @override
  State<LinkedGamesBackOutDialog> createState() =>
      _LinkedGamesBackOutDialogState();
}

class _LinkedGamesBackOutDialogState extends State<LinkedGamesBackOutDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final GameAssignmentRepository _assignmentRepo = GameAssignmentRepository();
  bool _showConfirmation = false;
  bool _isLoading = false;
  String? _selectedPreset;

  final List<String> _reasonPresets = [
    'Emergency',
    'Illness',
    'Schedule Conflict',
    'Family Emergency',
    'Work Conflict',
    'Transportation Issue',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _showSecondStep() {
    // Check if we have a preset selected or custom text entered
    final hasPreset = _selectedPreset != null;
    final hasCustomText = _reasonController.text.trim().isNotEmpty;

    if (!hasPreset && !hasCustomText) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason or provide details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If 'Other' is selected but no text provided
    if (_selectedPreset == 'Other' && !hasCustomText) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide details for your reason'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _showConfirmation = true;
    });
  }

  void _backToFirstStep() {
    setState(() {
      _showConfirmation = false;
    });
  }

  Future<void> _confirmBackOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reason = _reasonController.text.trim();
      await widget.onConfirmBackOut(reason);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error backing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPresetChanged(String? preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != null && preset != 'Other') {
        _reasonController.text = preset;
      } else if (preset == 'Other') {
        _reasonController.text = '';
      }
    });
  }

  String _formatGameTitle(GameAssignment assignment) {
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'TBD';
    return DateFormat('h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: darkSurface,
      title: Text(
        _showConfirmation
            ? 'Confirm Back Out of Linked Games'
            : 'Back Out of Linked Games',
        style: const TextStyle(color: efficialsYellow),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: double.maxFinite,
        ),
        child: SingleChildScrollView(
          child: _showConfirmation
              ? _buildConfirmationStep()
              : _buildWarningStep(),
        ),
      ),
      actions: _showConfirmation
          ? _buildConfirmationActions()
          : _buildWarningActions(),
    );
  }

  Widget _buildWarningStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              'Linked Games Warning',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: const Text(
            'These games are linked together by the scheduler. If you back out of one, you must back out of all linked games.',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'You will be backing out of the following games:',
          style:
              TextStyle(color: Colors.grey[300], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Column(
              children: widget.linkedAssignments.map((assignment) {
                final sportName = assignment.sportName ?? 'Sport';
                final gameTitle = _formatGameTitle(assignment);
                final dateString = _formatDate(assignment.gameDate);
                final timeString = _formatTime(assignment.gameTime);
                final locationName = assignment.locationName ?? 'TBD';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: darkBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: efficialsYellow.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$sportName: $gameTitle',
                        style: const TextStyle(
                          color: efficialsYellow,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateString at $timeString',
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                      Text(
                        locationName,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Reason for backing out:',
          style: TextStyle(color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPreset,
          decoration: InputDecoration(
            filled: true,
            fillColor: darkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: efficialsYellow),
            ),
            hintText: 'Select a reason...',
            hintStyle: TextStyle(color: Colors.grey[500]),
          ),
          dropdownColor: darkBackground,
          style: const TextStyle(color: Colors.white),
          items: _reasonPresets
              .map((preset) => DropdownMenuItem(
                    value: preset,
                    child: Text(preset),
                  ))
              .toList(),
          onChanged: _onPresetChanged,
        ),
        const SizedBox(height: 12),
        Text(
          _selectedPreset == 'Other'
              ? 'Please specify:'
              : 'Additional details (optional):',
          style: TextStyle(color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: _selectedPreset == 'Other'
                ? 'Please provide details...'
                : 'Any additional information...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: darkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: efficialsYellow),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'Final Confirmation',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Are you absolutely sure you want to back out of ALL these linked games?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(
            child: Column(
              children: widget.linkedAssignments.map((assignment) {
                final sportName = assignment.sportName ?? 'Sport';
                final gameTitle = _formatGameTitle(assignment);
                final dateString = _formatDate(assignment.gameDate);
                final timeString = _formatTime(assignment.gameTime);

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$sportName: $gameTitle - $dateString at $timeString',
                    style: const TextStyle(
                      color: efficialsYellow,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Reason: ${_getDisplayReason()}',
          style: TextStyle(
            color: Colors.grey[400],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Text(
            'Warning: This action cannot be undone. The scheduler will be notified of your cancellation for ALL ${widget.linkedAssignments.length} games.',
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWarningActions() {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(
          'Cancel',
          style: TextStyle(color: Colors.grey[400]),
        ),
      ),
      ElevatedButton(
        onPressed: _showSecondStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        child: const Text('Continue'),
      ),
    ];
  }

  List<Widget> _buildConfirmationActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : _backToFirstStep,
        child: Text(
          'Back',
          style: TextStyle(color: Colors.grey[400]),
        ),
      ),
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
        child: Text(
          'Cancel',
          style: TextStyle(color: Colors.grey[400]),
        ),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _confirmBackOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Back Out of All'),
      ),
    ];
  }

  String _getDisplayReason() {
    if (_selectedPreset != null && _selectedPreset != 'Other') {
      final customText = _reasonController.text.trim();
      if (customText.isNotEmpty) {
        return '$_selectedPreset - $customText';
      }
      return _selectedPreset!;
    }
    return _reasonController.text.trim();
  }
}
