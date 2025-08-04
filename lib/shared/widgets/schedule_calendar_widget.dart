import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme.dart';
import '../utils/utils.dart';

class ScheduleCalendarWidget extends StatelessWidget {
  final List<Map<String, dynamic>> games;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final String? teamName;
  final bool showTitle;
  final double titleFontSize;

  const ScheduleCalendarWidget({
    super.key,
    required this.games,
    required this.focusedDay,
    this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    this.teamName,
    this.showTitle = true,
    this.titleFontSize = 24,
  });

  List<Map<String, dynamic>> _getGamesForDay(DateTime day) {
    return games.where((game) {
      final gameDate = game['date'] as DateTime?;
      if (gameDate == null) return false;
      return gameDate.year == day.year &&
          gameDate.month == day.month &&
          gameDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle && teamName != null) ...[
          Text(
            '$teamName Schedule',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: efficialsBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
        Container(
          decoration: BoxDecoration(
            color: darkSurface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) {
              return selectedDay != null &&
                  day.year == selectedDay!.year &&
                  day.month == selectedDay!.month &&
                  day.day == selectedDay!.day;
            },
            onDaySelected: onDaySelected,
            onPageChanged: onPageChanged,
            eventLoader: (day) {
              return _getGamesForDay(day);
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: efficialsBlue.withOpacity(0.5),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(4),
              ),
              selectedDecoration: BoxDecoration(
                color: efficialsYellow,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(4),
              ),
              selectedTextStyle: const TextStyle(
                fontSize: 16,
                color: efficialsBlack,
                fontWeight: FontWeight.w600,
              ),
              defaultTextStyle: const TextStyle(
                  fontSize: 16, color: primaryTextColor),
              weekendTextStyle: const TextStyle(
                  fontSize: 16, color: primaryTextColor),
              outsideTextStyle: TextStyle(
                  fontSize: 16, color: Colors.grey[400]),
              markersMaxCount: 0,
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor),
              weekendStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: efficialsBlue),
              leftChevronIcon: Icon(Icons.chevron_left,
                  color: efficialsBlue, size: 28),
              rightChevronIcon: Icon(Icons.chevron_right,
                  color: efficialsBlue, size: 28),
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final events = _getGamesForDay(day);
                final hasEvents = events.isNotEmpty;
                final isToday = isSameDay(day, DateTime.now());
                final isOutsideMonth = day.month != focusedDay.month;
                final isSelected = selectedDay != null &&
                    day.year == selectedDay!.year &&
                    day.month == selectedDay!.month &&
                    day.day == selectedDay!.day;

                Color? backgroundColor;
                Color textColor = isOutsideMonth
                    ? Colors.grey[400]!
                    : primaryTextColor;

                if (hasEvents) {
                  bool allAway = true;
                  bool allFullyHired = true;
                  bool needsOfficials = false;

                  for (var event in events) {
                    final isEventAway = event['isAway'] as bool? ?? false;
                    final hiredOfficials = event['officialsHired'] as int? ?? 0;
                    final requiredOfficials = int.tryParse(
                            event['officialsRequired']?.toString() ?? '0') ??
                        0;
                    final isFullyHired = hiredOfficials >= requiredOfficials;

                    if (!isEventAway) allAway = false;
                    if (!isFullyHired) {
                      allFullyHired = false;
                    }
                    if (!isEventAway && !isFullyHired) {
                      needsOfficials = true;
                    }
                  }

                  if (allAway) {
                    backgroundColor = Colors.grey[300];
                    textColor = Colors.white;
                  } else if (needsOfficials) {
                    backgroundColor = Colors.red[400];
                    textColor = Colors.white;
                  } else if (allFullyHired) {
                    backgroundColor = Colors.green[400];
                    textColor = Colors.white;
                  }
                }

                // Override with selection styling when date is selected
                if (isSelected) {
                  backgroundColor = efficialsYellow;
                  textColor = efficialsBlack;
                }

                return Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected
                        ? Border.all(color: efficialsBlue, width: 2)
                        : isToday && backgroundColor == null
                            ? Border.all(
                                color: efficialsBlue.withOpacity(0.5),
                                width: 1)
                            : null,
                    boxShadow: hasEvents
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: hasEvents
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: textColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}