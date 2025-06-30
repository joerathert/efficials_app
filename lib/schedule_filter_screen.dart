import 'package:flutter/material.dart';
import 'theme.dart';

class ScheduleFilterScreen extends StatefulWidget {
  final Map<String, Map<String, bool>> scheduleFilters;
  final bool showAwayGames;
  final bool showFullyCoveredGames;
  final Function(Map<String, Map<String, bool>>, bool, bool) onFiltersChanged;

  const ScheduleFilterScreen({
    super.key,
    required this.scheduleFilters,
    required this.showAwayGames,
    required this.showFullyCoveredGames,
    required this.onFiltersChanged,
  });

  @override
  State<ScheduleFilterScreen> createState() => _ScheduleFilterScreenState();
}

class _ScheduleFilterScreenState extends State<ScheduleFilterScreen> {
  late Map<String, Map<String, bool>> scheduleFilters;
  late bool showAwayGames;
  late bool showFullyCoveredGames;
  Map<String, bool> sportExpanded = {};

  @override
  void initState() {
    super.initState();
    scheduleFilters = Map.from(widget.scheduleFilters);
    showAwayGames = widget.showAwayGames;
    showFullyCoveredGames = widget.showFullyCoveredGames;
    for (var sport in scheduleFilters.keys) {
      sportExpanded[sport] = false;
    }
  }

  bool _areAllSchedulesSelected(String sport) {
    return scheduleFilters[sport]!.values.every((selected) => selected);
  }

  void _toggleSport(String sport, bool? value) {
    setState(() {
      for (var schedule in scheduleFilters[sport]!.keys) {
        scheduleFilters[sport]![schedule] = value ?? false;
      }
    });
    widget.onFiltersChanged(
        scheduleFilters, showAwayGames, showFullyCoveredGames);
  }

  void _toggleSchedule(String sport, String schedule, bool? value) {
    setState(() {
      scheduleFilters[sport]![schedule] = value ?? false;
    });
    widget.onFiltersChanged(
        scheduleFilters, showAwayGames, showFullyCoveredGames);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Icon(
          Icons.sports,
          color: Colors.white,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Options',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Customize which games appear on your home screen',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              // Game Type Filters
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Game Types',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      'Show Away Games',
                      'Include games played at opponent venues',
                      showAwayGames,
                      (value) {
                        setState(() {
                          showAwayGames = value;
                        });
                        widget.onFiltersChanged(scheduleFilters, showAwayGames,
                            showFullyCoveredGames);
                      },
                      Icons.flight_takeoff,
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      'Show Fully Covered Games',
                      'Include games that have all officials assigned',
                      showFullyCoveredGames,
                      (value) {
                        setState(() {
                          showFullyCoveredGames = value;
                        });
                        widget.onFiltersChanged(scheduleFilters, showAwayGames,
                            showFullyCoveredGames);
                      },
                      Icons.check_circle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Schedule Filters
              if (scheduleFilters.isNotEmpty) ...[
                const Text(
                  'Schedule Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: scheduleFilters.keys.map((sport) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: efficialsBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.sports,
                                    color: efficialsBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    sport,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Checkbox(
                                  value: _areAllSchedulesSelected(sport),
                                  onChanged: (value) =>
                                      _toggleSport(sport, value),
                                  activeColor: efficialsBlue,
                                ),
                              ],
                            ),
                            initiallyExpanded: sportExpanded[sport] ?? false,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                sportExpanded[sport] = expanded;
                              });
                            },
                            children:
                                scheduleFilters[sport]!.keys.map((schedule) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: scheduleFilters[sport]![schedule],
                                      onChanged: (value) => _toggleSchedule(
                                          sport, schedule, value),
                                      activeColor: efficialsBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        schedule,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No schedules to filter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create some games first to see filter options',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value,
      Function(bool) onChanged, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: efficialsBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: efficialsBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: efficialsBlue,
        ),
      ],
    );
  }
}
