import 'package:flutter/material.dart';
import 'theme.dart';

class EditGameInfoScreen extends StatefulWidget {
  const EditGameInfoScreen({super.key});

  @override
  _EditGameInfoScreenState createState() => _EditGameInfoScreenState();
}

class _EditGameInfoScreenState extends State<EditGameInfoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    print('didChangeDependencies - EditGameInfo Args: $args');
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final scheduleName = args['scheduleName'] as String? ?? 'Unnamed Schedule';
    final sport = args['sport'] as String? ?? 'Unknown Sport';
    final location = args['location'] as String? ?? 'Unknown Location';
    final date = args['date'] as DateTime? ?? DateTime.now();
    final time = args['time'] as TimeOfDay? ?? const TimeOfDay(hour: 12, minute: 0);
    final levelOfCompetition = args['levelOfCompetition'] as String?;
    final gender = args['gender'] as String?;
    final officialsRequired = args['officialsRequired'] as String?;
    final gameFee = args['gameFee'] as String?;
    final hireAutomatically = args['hireAutomatically'] as bool?;
    final selectedOfficials = args['selectedOfficials'] as List<Map<String, dynamic>>? ?? [];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Game Info',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/choose_location', arguments: {
                          ...args,
                          'isEdit': true,
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: MaterialStateProperty.all(const Size(300, 60)),
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
                      ),
                      child: const Text(
                        'Location',
                        style: signInButtonTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/date_time', arguments: {
                          ...args,
                          'isEdit': true,
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: MaterialStateProperty.all(const Size(300, 60)),
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
                      ),
                      child: const Text(
                        'Date/Time',
                        style: signInButtonTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/additional_game_info', arguments: {
                          ...args,
                          'isEdit': true,
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: MaterialStateProperty.all(const Size(300, 60)),
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
                      ),
                      child: const Text(
                        'Additional Game Info',
                        style: signInButtonTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/populate_roster', arguments: {
                          'sport': sport,
                          'listName': scheduleName,
                          'selectedOfficials': selectedOfficials,
                          'method': 'standard',
                          'isEdit': true,
                        }).then((result) {
                          if (result != null) {
                            final updatedOfficials = (result as Map<String, dynamic>)['officials'] as List<Map<String, dynamic>>;
                            Navigator.pop(context, {
                              ...args,
                              'selectedOfficials': updatedOfficials,
                            });
                          }
                        });
                      },
                      style: elevatedButtonStyle().copyWith(
                        minimumSize: MaterialStateProperty.all(const Size(300, 60)),
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
                      ),
                      child: const Text(
                        'Selected Officials',
                        style: signInButtonTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}