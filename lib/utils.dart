import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

IconData getSportIcon(String sport) {
  switch (sport.toLowerCase()) {
    case 'football':
      return FontAwesomeIcons.footballBall; // Football
    case 'basketball':
      return FontAwesomeIcons.basketballBall; // Basketball
    case 'baseball':
      return FontAwesomeIcons.baseballBall; // Baseball
    case 'soccer':
      return FontAwesomeIcons.futbol; // Soccer ball
    case 'volleyball':
      return FontAwesomeIcons.volleyball; // Volleyball
    case 'field hockey':
      return FontAwesomeIcons.hockeyPuck; // Hockey puck
    case 'ice hockey':
      return FontAwesomeIcons.hockeyPuck; // Hockey puck
    case 'tennis':
      return FontAwesomeIcons.tableTennis; // Table tennis paddle
    case 'track':
      return FontAwesomeIcons.running; // Running person
    case 'swimming':
      return FontAwesomeIcons.swimmer; // Swimmer
    case 'wrestling':
      return FontAwesomeIcons.userNinja; // Martial arts icon for wrestling
    case 'golf':
      return FontAwesomeIcons.golfBall; // Golf ball
    case 'lacrosse':
      return FontAwesomeIcons.trophy; // Trophy for lacrosse (no specific icon)
    default:
      return FontAwesomeIcons.medal; // Medal for default
  }
}

Color getSportIconColor(String sport) {
  switch (sport.toLowerCase()) {
    case 'football':
      return const Color(0xFF8B4513); // Brown for football
    case 'basketball':
      return const Color(0xFFFF6B00); // Orange for basketball
    case 'baseball':
      return const Color(0xFFDC3545); // Red for baseball
    case 'soccer':
      return const Color(0xFF28A745); // Green for soccer
    case 'volleyball':
      return const Color(0xFFFFC107); // Yellow for volleyball
    case 'field hockey':
      return const Color(0xFF6610F2); // Purple for field hockey
    case 'ice hockey':
      return const Color(0xFF0056B3); // Blue for ice hockey
    case 'tennis':
      return const Color(0xFF98FB98); // Light green for tennis
    case 'track':
      return const Color(0xFFE83E8C); // Pink for track
    case 'swimming':
      return const Color(0xFF17A2B8); // Cyan for swimming
    case 'wrestling':
      return const Color(0xFF6C757D); // Gray for wrestling
    case 'golf':
      return const Color(0xFF20C997); // Teal for golf
    case 'lacrosse':
      return const Color(0xFFD6336C); // Rose for lacrosse
    default:
      return const Color(0xFFFFD700); // Gold for default
  }
}
