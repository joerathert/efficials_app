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
    widget.onFiltersChanged(scheduleFilters, showAwayGames, showFullyCoveredGames);
  }

  void _toggleSchedule(String sport, String schedule, bool? value) {
    setState(() {
      scheduleFilters[sport]![schedule] = value ?? false;
    });
    widget.onFiltersChanged(scheduleFilters, showAwayGames, showFullyCoveredGames);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Text('Filter Schedules', style: appBarTextStyle),
      ),
      body: ListView(
        children: [
          // Add toggles at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Show Away Games', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Switch(
                      value: showAwayGames,
                      onChanged: (value) {
                        setState(() {
                          showAwayGames = value;
                        });
                        widget.onFiltersChanged(scheduleFilters, showAwayGames, showFullyCoveredGames);
                      },
                      activeColor: efficialsBlue,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Show Fully Covered', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Switch(
                      value: showFullyCoveredGames,
                      onChanged: (value) {
                        setState(() {
                          showFullyCoveredGames = value;
                        });
                        widget.onFiltersChanged(scheduleFilters, showAwayGames, showFullyCoveredGames);
                      },
                      activeColor: efficialsBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Existing schedule filters
          ...scheduleFilters.keys.map((sport) {
            return ExpansionTile(
              title: Row(
                children: [
                  Checkbox(
                    value: _areAllSchedulesSelected(sport),
                    onChanged: (value) => _toggleSport(sport, value),
                    activeColor: efficialsBlue,
                  ),
                  Text(sport),
                ],
              ),
              initiallyExpanded: sportExpanded[sport] ?? false,
              onExpansionChanged: (expanded) {
                setState(() {
                  sportExpanded[sport] = expanded;
                });
              },
              children: scheduleFilters[sport]!.keys.map((schedule) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: ListTile(
                    title: Row(
                      children: [
                        Checkbox(
                          value: scheduleFilters[sport]![schedule],
                          onChanged: (value) => _toggleSchedule(sport, schedule, value),
                          activeColor: efficialsBlue,
                        ),
                        Expanded(child: Text(schedule)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ],
      ),
    );
  }
}