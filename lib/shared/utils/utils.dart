import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';

// Cache for sport icons to avoid repeated switch statements
final Map<String, IconData> _sportIconCache = {};

IconData getSportIcon(String sport) {
  final String lowercaseSport = sport.toLowerCase();
  
  // Return cached icon if available
  if (_sportIconCache.containsKey(lowercaseSport)) {
    return _sportIconCache[lowercaseSport]!;
  }
  
  // Calculate icon and cache it
  IconData icon;
  switch (lowercaseSport) {
    case 'football':
      icon = FontAwesomeIcons.football;
      break;
    case 'basketball':
      icon = FontAwesomeIcons.basketball;
      break;
    case 'baseball':
      icon = FontAwesomeIcons.baseball;
      break;
    case 'soccer':
      icon = FontAwesomeIcons.futbol;
      break;
    case 'volleyball':
      icon = FontAwesomeIcons.volleyball;
      break;
    case 'field hockey':
      icon = FontAwesomeIcons.hockeyPuck;
      break;
    case 'ice hockey':
      icon = FontAwesomeIcons.hockeyPuck;
      break;
    case 'tennis':
      icon = FontAwesomeIcons.tableTennisPaddleBall;
      break;
    case 'track':
      icon = FontAwesomeIcons.personRunning;
      break;
    case 'swimming':
      icon = FontAwesomeIcons.personSwimming;
      break;
    case 'wrestling':
      icon = FontAwesomeIcons.userNinja;
      break;
    case 'golf':
      icon = FontAwesomeIcons.golfBallTee;
      break;
    case 'lacrosse':
      icon = FontAwesomeIcons.trophy;
      break;
    default:
      icon = FontAwesomeIcons.medal;
  }
  
  _sportIconCache[lowercaseSport] = icon;
  return icon;
}

// All sports will use the Friday night lights yellow color
Color getSportIconColor(String sport) {
  return efficialsYellow;
}
