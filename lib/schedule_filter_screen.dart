import 'package:flutter/material.dart';
import 'theme.dart';

class ScheduleFilterScreen extends StatefulWidget {
  final Map<String, Map<String, bool>> scheduleFilters;
  final Function(Map<String, Map<String, bool>>) onFiltersChanged;

  const ScheduleFilterScreen({
    super.key,
    required this.scheduleFilters,
    required this.onFiltersChanged,
  });

  @override
  State<ScheduleFilterScreen> createState() => _ScheduleFilterScreenState();
}

class _ScheduleFilterScreenState extends State<ScheduleFilterScreen> {
  late Map<String, Map<String, bool>> scheduleFilters;
  Map<String, bool> sportExpanded = {};

  @override
  void initState() {
    super.initState();
    scheduleFilters = Map.from(widget.scheduleFilters);
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
    widget.onFiltersChanged(scheduleFilters);
  }

  void _toggleSchedule(String sport, String schedule, bool? value) {
    setState(() {
      scheduleFilters[sport]![schedule] = value ?? false;
    });
    widget.onFiltersChanged(scheduleFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        title: const Text('Filter Schedules', style: appBarTextStyle),
      ),
      body: ListView(
        children: scheduleFilters.keys.map((sport) {
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
                padding: const EdgeInsets.only(left: 16.0), // Indent the schedule names
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
      ),
    );
  }
}