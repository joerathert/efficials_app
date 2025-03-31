import 'package:flutter/material.dart';

class GameTemplate {
  final String name;
  final String sport;
  final bool includeSport;
  final TimeOfDay? time;
  final bool includeTime;
  final String? location;
  final bool includeLocation;
  final String? levelOfCompetition;
  final bool includeLevelOfCompetition;
  final String? gender;
  final bool includeGender;
  final int? officialsRequired;
  final bool includeOfficialsRequired;
  final String? gameFee; // Stored as a String
  final bool includeGameFee;
  final bool? hireAutomatically;
  final bool includeHireAutomatically;
  final String? officialsListName;
  final bool includeOfficialsList;
  final String? method;
  final List<String>? selectedOfficials;
  final bool includeSelectedOfficials;

  GameTemplate({
    required this.name,
    required this.sport,
    this.includeSport = true,
    this.time,
    this.includeTime = true,
    this.location,
    this.includeLocation = true,
    this.levelOfCompetition,
    this.includeLevelOfCompetition = true,
    this.gender,
    this.includeGender = true,
    this.officialsRequired,
    this.includeOfficialsRequired = true,
    this.gameFee,
    this.includeGameFee = true,
    this.hireAutomatically,
    this.includeHireAutomatically = true,
    this.officialsListName,
    this.includeOfficialsList = true,
    this.method,
    this.selectedOfficials,
    this.includeSelectedOfficials = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sport': sport,
        'includeSport': includeSport,
        'time': time != null ? '${time!.hour}:${time!.minute}' : null,
        'includeTime': includeTime,
        'location': location,
        'includeLocation': includeLocation,
        'levelOfCompetition': levelOfCompetition,
        'includeLevelOfCompetition': includeLevelOfCompetition,
        'gender': gender,
        'includeGender': includeGender,
        'officialsRequired': officialsRequired,
        'includeOfficialsRequired': includeOfficialsRequired,
        'gameFee': gameFee,
        'includeGameFee': includeGameFee,
        'hireAutomatically': hireAutomatically,
        'includeHireAutomatically': includeHireAutomatically,
        'officialsListName': officialsListName,
        'includeOfficialsList': includeOfficialsList,
        'method': method,
        'selectedOfficials': selectedOfficials,
        'includeSelectedOfficials': includeSelectedOfficials,
      };

  factory GameTemplate.fromJson(Map<String, dynamic> json) {
    final timeStr = json['time'] as String?;
    TimeOfDay? time;
    if (timeStr != null) {
      final parts = timeStr.split(':');
      time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    // Handle gameFee, which could be a String (new templates) or a double (old templates)
    String? gameFee;
    if (json['gameFee'] != null) {
      if (json['gameFee'] is String) {
        gameFee = json['gameFee'] as String;
      } else if (json['gameFee'] is double) {
        gameFee = (json['gameFee'] as double).toStringAsFixed(0); // Convert double to String, e.g., 100.0 -> "100"
      }
    }

    return GameTemplate(
      name: json['name'] as String,
      sport: json['sport'] as String,
      includeSport: json['includeSport'] as bool? ?? true,
      time: time,
      includeTime: json['includeTime'] as bool? ?? true,
      location: json['location'] as String?,
      includeLocation: json['includeLocation'] as bool? ?? true,
      levelOfCompetition: json['levelOfCompetition'] as String?,
      includeLevelOfCompetition: json['includeLevelOfCompetition'] as bool? ?? true,
      gender: json['gender'] as String?,
      includeGender: json['includeGender'] as bool? ?? true,
      officialsRequired: json['officialsRequired'] as int?,
      includeOfficialsRequired: json['includeOfficialsRequired'] as bool? ?? true,
      gameFee: gameFee,
      includeGameFee: json['includeGameFee'] as bool? ?? true,
      hireAutomatically: json['hireAutomatically'] as bool?,
      includeHireAutomatically: json['includeHireAutomatically'] as bool? ?? true,
      officialsListName: json['officialsListName'] as String?,
      includeOfficialsList: json['includeOfficialsList'] as bool? ?? true,
      method: json['method'] as String?,
      selectedOfficials: json['selectedOfficials'] != null ? List<String>.from(json['selectedOfficials']) : null,
      includeSelectedOfficials: json['includeSelectedOfficials'] as bool? ?? true,
    );
  }
}