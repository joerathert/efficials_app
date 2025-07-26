import 'package:flutter/material.dart';

class GameTemplate {
  final String id; // Added id field
  final String name; // Made non-nullable with default
  final String? scheduleName;
  final String? sport;
  final DateTime? date;
  final TimeOfDay? time;
  final String? location;
  final bool isAwayGame;
  final String? levelOfCompetition;
  final String? gender;
  final int? officialsRequired;
  final String? gameFee;
  final String? opponent;
  final bool? hireAutomatically;
  final String? method;
  final List<Map<String, dynamic>>? selectedOfficials;
  final List<Map<String, dynamic>>? selectedLists; // Added for advanced method
  final String? officialsListName;
  final bool includeScheduleName;
  final bool includeSport;
  final bool includeDate;
  final bool includeTime;
  final bool includeLocation;
  final bool includeIsAwayGame;
  final bool includeLevelOfCompetition;
  final bool includeGender;
  final bool includeOfficialsRequired;
  final bool includeGameFee;
  final bool includeOpponent;
  final bool includeHireAutomatically;
  final bool includeSelectedOfficials;
  final bool includeOfficialsList;

  GameTemplate({
    required this.id, // Added required id parameter
    String? name, // Allow null in constructor, but provide default
    this.scheduleName,
    this.sport,
    this.date,
    this.time,
    this.location,
    this.isAwayGame = false,
    this.levelOfCompetition,
    this.gender,
    this.officialsRequired,
    this.gameFee,
    this.opponent,
    this.hireAutomatically,
    this.method,
    this.selectedOfficials,
    this.selectedLists, // Added for advanced method
    this.officialsListName,
    this.includeScheduleName = false,
    this.includeSport = false,
    this.includeDate = false,
    this.includeTime = false,
    this.includeLocation = false,
    this.includeIsAwayGame = false,
    this.includeLevelOfCompetition = false,
    this.includeGender = false,
    this.includeOfficialsRequired = false,
    this.includeGameFee = false,
    this.includeOpponent = false,
    this.includeHireAutomatically = false,
    this.includeSelectedOfficials = false,
    this.includeOfficialsList = false,
  }) : name = name ?? 'Unnamed Template'; // Default value for name

  // Convert GameTemplate to Map for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Added id to serialization
      'name': name,
      'scheduleName': scheduleName,
      'sport': sport,
      'date': date?.toIso8601String(),
      'time': time != null ? {'hour': time!.hour, 'minute': time!.minute} : null,
      'location': location,
      'isAwayGame': isAwayGame,
      'levelOfCompetition': levelOfCompetition,
      'gender': gender,
      'officialsRequired': officialsRequired,
      'gameFee': gameFee,
      'opponent': opponent,
      'hireAutomatically': hireAutomatically,
      'method': method,
      'selectedOfficials': selectedOfficials,
      'selectedLists': selectedLists, // Added for advanced method
      'officialsListName': officialsListName,
      'includeScheduleName': includeScheduleName,
      'includeSport': includeSport,
      'includeDate': includeDate,
      'includeTime': includeTime,
      'includeLocation': includeLocation,
      'includeIsAwayGame': includeIsAwayGame,
      'includeLevelOfCompetition': includeLevelOfCompetition,
      'includeGender': includeGender,
      'includeOfficialsRequired': includeOfficialsRequired,
      'includeGameFee': includeGameFee,
      'includeOpponent': includeOpponent,
      'includeHireAutomatically': includeHireAutomatically,
      'includeSelectedOfficials': includeSelectedOfficials,
      'includeOfficialsList': includeOfficialsList,
    };
  }

  // Create GameTemplate from Map (deserialization)
  factory GameTemplate.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time;
    if (json['time'] != null) {
      if (json['time'] is Map) {
        // Format: {"hour": "23", "minute": "0"} or {"hour": 23, "minute": 0}
        time = TimeOfDay(
          hour: int.parse(json['time']['hour'].toString()),
          minute: int.parse(json['time']['minute'].toString()),
        );
      } else if (json['time'] is String) {
        // Format: "23:00"
        final parts = (json['time'] as String).split(':');
        if (parts.length == 2) {
          time = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
    }

    List<Map<String, dynamic>>? selectedOfficials;
    if (json['selectedOfficials'] != null) {
      if (json['selectedOfficials'] is List) {
        final officialsList = json['selectedOfficials'] as List;
        if (officialsList.isNotEmpty) {
          if (officialsList.first is Map) {
            // Expected format: [{"name": "John Doe"}, {"name": "Jane Smith"}]
            selectedOfficials = List<Map<String, dynamic>>.from(officialsList);
          } else if (officialsList.first is String) {
            // Format: ["John Doe", "Jane Smith"]
            selectedOfficials = officialsList.map((name) => {'name': (name as String?) ?? 'Unknown Official'}).toList();
          } else {
            selectedOfficials = null;
          }
        } else {
          selectedOfficials = [];
        }
      } else if (json['selectedOfficials'] is String) {
        // Legacy format: "John Doe, Jane Smith"
        final officialsString = json['selectedOfficials'] as String;
        if (officialsString.isNotEmpty) {
          selectedOfficials = officialsString.split(',').map((name) => {'name': name.trim()}).toList();
        } else {
          selectedOfficials = [];
        }
      } else {
        // Unexpected format: set to null and log the issue
        selectedOfficials = null;
      }
    }

    return GameTemplate(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(), // Fallback if id is missing
      name: json['name'] as String?,
      scheduleName: json['scheduleName'] as String?,
      sport: json['sport'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      time: time,
      location: json['location'] as String?,
      isAwayGame: json['isAwayGame'] as bool? ?? false,
      levelOfCompetition: json['levelOfCompetition'] as String?,
      gender: json['gender'] as String?,
      officialsRequired: json['officialsRequired'] as int?,
      gameFee: json['gameFee'] as String?,
      opponent: json['opponent'] as String?,
      hireAutomatically: json['hireAutomatically'] as bool?,
      method: json['method'] as String?,
      selectedOfficials: selectedOfficials,
      selectedLists: json['selectedLists'] != null 
          ? List<Map<String, dynamic>>.from(json['selectedLists'] as List)
          : null,
      officialsListName: json['officialsListName'] as String?,
      includeScheduleName: json['includeScheduleName'] as bool? ?? false,
      includeSport: json['includeSport'] as bool? ?? false,
      includeDate: json['includeDate'] as bool? ?? false,
      includeTime: json['includeTime'] as bool? ?? false,
      includeLocation: json['includeLocation'] as bool? ?? false,
      includeIsAwayGame: json['includeIsAwayGame'] as bool? ?? false,
      includeLevelOfCompetition: json['includeLevelOfCompetition'] as bool? ?? false,
      includeGender: json['includeGender'] as bool? ?? false,
      includeOfficialsRequired: json['includeOfficialsRequired'] as bool? ?? false,
      includeGameFee: json['includeGameFee'] as bool? ?? false,
      includeOpponent: json['includeOpponent'] as bool? ?? false,
      includeHireAutomatically: json['includeHireAutomatically'] as bool? ?? false,
      includeSelectedOfficials: json['includeSelectedOfficials'] as bool? ?? false,
      includeOfficialsList: json['includeOfficialsList'] as bool? ?? false,
    );
  }
}