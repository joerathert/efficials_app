import 'package:flutter/material.dart';
import 'theme.dart';

class EditGameInfoScreen extends StatelessWidget {
  const EditGameInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Game Info', style: appBarTextStyle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/choose_location', arguments: {
                    'scheduleName': args['scheduleName'],
                    'sport': args['sport'],
                    'location': args['location'],
                    'fromEdit': true,
                  }).then((result) {
                    if (result != null) {
                      args['location'] = result;
                      print('EditGameInfoScreen Location callback - Updated Args: $args');
                      Navigator.pop(context, args); // Return updated args
                    } else {
                      print('EditGameInfoScreen Location callback - No change, Args: $args');
                      Navigator.pop(context, args); // Return original args if no change
                    }
                  }),
                  style: elevatedButtonStyle().copyWith(
                    minimumSize: MaterialStateProperty.all(const Size(250, 50)),
                  ),
                  child: const Text('Location', style: signInButtonTextStyle),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/date_time', arguments: {
                    'scheduleName': args['scheduleName'],
                    'sport': args['sport'],
                    'date': args['date'],
                    'time': args['time'],
                  }).then((result) {
                    if (result != null && result is Map<String, dynamic>) {
                      args['date'] = result['date'];
                      args['time'] = result['time'];
                      Navigator.pop(context, args);
                    }
                  }),
                  style: elevatedButtonStyle().copyWith(
                    minimumSize: MaterialStateProperty.all(const Size(250, 50)),
                  ),
                  child: const Text('Date/Time', style: signInButtonTextStyle),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/additional_game_info', arguments: {
                    'scheduleName': args['scheduleName'],
                    'sport': args['sport'],
                    'location': args['location'],
                    'date': args['date'],
                    'time': args['time'],
                    'levelOfCompetition': args['levelOfCompetition'],
                    'gender': args['gender'],
                    'officialsRequired': args['officialsRequired'],
                    'gameFee': args['gameFee'],
                    'hireAutomatically': args['hireAutomatically'],
                  }).then((result) {
                    if (result != null && result is Map<String, dynamic>) {
                      args.addAll(result);
                      Navigator.pop(context, args);
                    }
                  }),
                  style: elevatedButtonStyle().copyWith(
                    minimumSize: MaterialStateProperty.all(const Size(250, 50)),
                  ),
                  child: const Text('Other Game Information', style: signInButtonTextStyle),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/select_officials', arguments: {
                    'scheduleName': args['scheduleName'],
                    'sport': args['sport'],
                    'location': args['location'],
                    'date': args['date'],
                    'time': args['time'],
                    'method': 'standard',
                    'selectedOfficials': args['selectedOfficials'],
                  }).then((result) {
                    if (result != null && result is Map<String, dynamic>) {
                      args['selectedOfficials'] = result['selectedOfficials'];
                      Navigator.pop(context, args);
                    }
                  }),
                  style: elevatedButtonStyle().copyWith(
                    minimumSize: MaterialStateProperty.all(const Size(250, 50)),
                  ),
                  child: const Text('Selected Officials', style: signInButtonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}