import 'package:flutter/material.dart';

IconData getSportIcon(String sport) {
  switch (sport.toLowerCase()) {
    case 'football':
      return Icons.sports_football;
    case 'basketball':
      return Icons.sports_basketball;
    case 'baseball':
      return Icons.sports_baseball;
    case 'soccer':
      return Icons.sports_soccer;
    case 'volleyball':
      return Icons.sports_volleyball;
    default:
      return Icons.sports;
  }
}