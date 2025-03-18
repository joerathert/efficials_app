import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';

class ReviewGameInfoScreen extends StatelessWidget {
  const ReviewGameInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final isAdultLevel = (args['levelOfCompetition'] as String? ?? '').toLowerCase() == 'college' ||
        (args['levelOfCompetition'] as String? ?? '').toLowerCase() == 'adult';

    final gameDetails = {
      'Sport': args['sport'] as String? ?? 'Unknown',
      'Schedule Name': args['scheduleName'] as String? ?? 'Unnamed',
      'Date': args['date'] != null ? DateFormat('MMMM d, yyyy').format(args['date'] as DateTime) : 'Not set',
      'Time': args['time'] != null ? (args['time'] as TimeOfDay).format(context) : 'Not set',
      'Location': args['location'] as String? ?? 'Not set',
      'Officials Required': args['officialsRequired'] as String? ?? '0',
      'Game Fee per Official': args['gameFee'] != null ? '\$${args['gameFee']}' : 'Not set',
      'Method': args['method'] == 'standard' ? 'Standard' : (args['method'] as String? ?? 'Not specified'),
      'Gender': args['gender'] != null
          ? (isAdultLevel
              ? {'boys': 'Men', 'girls': 'Women', 'co-ed': 'Co-ed'}[(args['gender'] as String).toLowerCase()] ??
                  'Not set'
              : args['gender'] as String)
          : 'Not set',
      'Competition Level': args['levelOfCompetition'] as String? ?? 'Not set',
      'Hire Automatically': args['hireAutomatically'] == true ? 'Yes' : 'No',
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: efficialsBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Review Game Info', style: appBarTextStyle),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverHeaderDelegate(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Game Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'edit'),
                      child: const Text('Edit', style: TextStyle(color: efficialsBlue, fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...gameDetails.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Selected Officials', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (args['selectedOfficials'] == null || (args['selectedOfficials'] as List).isEmpty)
                        const Text('No officials selected.', style: TextStyle(fontSize: 16, color: Colors.grey))
                      else
                        ...((args['selectedOfficials'] as List<Map<String, dynamic>>).map(
                          (official) => ListTile(
                            title: Text(official['name'] as String),
                            subtitle: Text('Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi'),
                          ),
                        )),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game published!')),
                );
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              style: elevatedButtonStyle(),
              child: const Text('Publish Game', style: signInButtonTextStyle),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game saved for later!')),
                );
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              style: elevatedButtonStyle(),
              child: const Text('Publish Later', style: signInButtonTextStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80; // Increased height to fit content

  @override
  double get minExtent => 80; // Same as maxExtent to prevent shrinking

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}