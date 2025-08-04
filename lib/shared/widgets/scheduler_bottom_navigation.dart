import 'package:flutter/material.dart';
import '../theme.dart';

enum SchedulerType { coach, assigner, athleticDirector }

class SchedulerBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final SchedulerType schedulerType;
  final int unreadNotificationCount;

  const SchedulerBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.schedulerType,
    this.unreadNotificationCount = 0,
  });

  List<BottomNavigationBarItem> _getNavigationItems() {
    switch (schedulerType) {
      case SchedulerType.coach:
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Officials',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Locations',
          ),
          BottomNavigationBarItem(
            icon: _buildNotificationIcon(),
            label: 'Notifications',
          ),
        ];
      case SchedulerType.assigner:
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedules',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Officials',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.copy),
            label: 'Templates',
          ),
          BottomNavigationBarItem(
            icon: _buildNotificationIcon(),
            label: 'Notifications',
          ),
        ];
      case SchedulerType.athleticDirector:
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedules',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.filter_list),
            label: 'Filter',
          ),
          BottomNavigationBarItem(
            icon: _buildNotificationIcon(),
            label: 'Notifications',
          ),
        ];
    }
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        const Icon(Icons.notifications),
        if (unreadNotificationCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadNotificationCount > 99 ? '99+' : unreadNotificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: efficialsBlack,
      selectedItemColor: efficialsYellow,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: onTap,
      items: _getNavigationItems(),
    );
  }
}