import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'theme.dart';

IconData getSportIcon(String sport) {
  switch (sport.toLowerCase()) {
    case 'football':
      return FontAwesomeIcons.football; // Football
    case 'basketball':
      return FontAwesomeIcons.basketball; // Basketball
    case 'baseball':
      return FontAwesomeIcons.baseball; // Baseball
    case 'soccer':
      return FontAwesomeIcons.futbol; // Soccer ball
    case 'volleyball':
      return FontAwesomeIcons.volleyball; // Volleyball
    case 'field hockey':
      return FontAwesomeIcons.hockeyPuck; // Hockey puck
    case 'ice hockey':
      return FontAwesomeIcons.hockeyPuck; // Hockey puck
    case 'tennis':
      return FontAwesomeIcons.tableTennisPaddleBall; // Table tennis paddle
    case 'track':
      return FontAwesomeIcons.personRunning; // Running person
    case 'swimming':
      return FontAwesomeIcons.personSwimming; // Swimmer
    case 'wrestling':
      return FontAwesomeIcons.userNinja; // Martial arts icon for wrestling
    case 'golf':
      return FontAwesomeIcons.golfBallTee; // Golf ball
    case 'lacrosse':
      return FontAwesomeIcons.trophy; // Trophy for lacrosse (no specific icon)
    default:
      return FontAwesomeIcons.medal; // Medal for default
  }
}

// All sports will use the Friday night lights yellow color
Color getSportIconColor(String sport) {
  return efficialsYellow;
}
