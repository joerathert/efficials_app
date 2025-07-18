import 'package:flutter/material.dart';

// User model
class User {
  final int? id;
  final String schedulerType;
  final bool setupCompleted;
  final String? schoolName;
  final String? mascot;
  final String? teamName;
  final String? sport;
  final String? grade;
  final String? gender;
  final String? leagueName;
  final DateTime createdAt;

  User({
    this.id,
    required this.schedulerType,
    this.setupCompleted = false,
    this.schoolName,
    this.mascot,
    this.teamName,
    this.sport,
    this.grade,
    this.gender,
    this.leagueName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scheduler_type': schedulerType,
      'setup_completed': setupCompleted ? 1 : 0,
      'school_name': schoolName,
      'mascot': mascot,
      'team_name': teamName,
      'sport': sport,
      'grade': grade,
      'gender': gender,
      'league_name': leagueName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      schedulerType: map['scheduler_type'] ?? '',
      setupCompleted: (map['setup_completed'] ?? 0) == 1,
      schoolName: map['school_name'],
      mascot: map['mascot'],
      teamName: map['team_name'],
      sport: map['sport'],
      grade: map['grade'],
      gender: map['gender'],
      leagueName: map['league_name'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Sport model
class Sport {
  final int? id;
  final String name;
  final DateTime createdAt;

  Sport({
    this.id,
    required this.name,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Sport.fromMap(Map<String, dynamic> map) {
    return Sport(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Sport copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Sport(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Schedule model
class Schedule {
  final int? id;
  final String name;
  final int sportId;
  final int userId;
  final DateTime createdAt;

  // Joined data
  final String? sportName;

  Schedule({
    this.id,
    required this.name,
    required this.sportId,
    required this.userId,
    DateTime? createdAt,
    this.sportName,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sport_id': sportId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      sportId: map['sport_id']?.toInt() ?? 0,
      userId: map['user_id']?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      sportName: map['sport_name'],
    );
  }

  Schedule copyWith({
    int? id,
    String? name,
    int? sportId,
    int? userId,
    DateTime? createdAt,
    String? sportName,
  }) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      sportId: sportId ?? this.sportId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      sportName: sportName ?? this.sportName,
    );
  }
}

// Location model
class Location {
  final int? id;
  final String name;
  final String? address;
  final String? notes;
  final int userId;
  final DateTime createdAt;

  Location({
    this.id,
    required this.name,
    this.address,
    this.notes,
    required this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'notes': notes,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      address: map['address'],
      notes: map['notes'],
      userId: map['user_id']?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Official model
class Official {
  final int? id;
  final String name;
  final int? sportId;
  final String? rating;
  final int userId;
  final DateTime createdAt;

  // Joined data
  final String? sportName;

  Official({
    this.id,
    required this.name,
    this.sportId,
    this.rating,
    required this.userId,
    DateTime? createdAt,
    this.sportName,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sport_id': sportId,
      'rating': rating,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Official.fromMap(Map<String, dynamic> map) {
    return Official(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      sportId: map['sport_id']?.toInt(),
      rating: map['rating'],
      userId: map['user_id']?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      sportName: map['sport_name'],
    );
  }
}

// Game model
class Game {
  final int? id;
  final int? scheduleId;
  final int sportId;
  final int? locationId;
  final int userId;
  final DateTime? date;
  final TimeOfDay? time;
  final bool isAway;
  final String? levelOfCompetition;
  final String? gender;
  final int officialsRequired;
  final int officialsHired;
  final String? gameFee;
  final String? opponent;
  final bool hireAutomatically;
  final String? method;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? scheduleName;
  final String? sportName;
  final String? locationName;
  final List<Official> assignedOfficials;

  Game({
    this.id,
    this.scheduleId,
    required this.sportId,
    this.locationId,
    required this.userId,
    this.date,
    this.time,
    this.isAway = false,
    this.levelOfCompetition,
    this.gender,
    this.officialsRequired = 0,
    this.officialsHired = 0,
    this.gameFee,
    this.opponent,
    this.hireAutomatically = false,
    this.method,
    this.status = 'Unpublished',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.scheduleName,
    this.sportName,
    this.locationName,
    this.assignedOfficials = const [],
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'sport_id': sportId,
      'location_id': locationId,
      'user_id': userId,
      'date': date?.toIso8601String(),
      'time': time != null ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}' : null,
      'is_away': isAway ? 1 : 0,
      'level_of_competition': levelOfCompetition,
      'gender': gender,
      'officials_required': officialsRequired,
      'officials_hired': officialsHired,
      'game_fee': gameFee,
      'opponent': opponent,
      'hire_automatically': hireAutomatically ? 1 : 0,
      'method': method,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    TimeOfDay? gameTime;
    if (map['time'] != null) {
      final timeParts = (map['time'] as String).split(':');
      if (timeParts.length == 2) {
        gameTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }

    return Game(
      id: map['id']?.toInt(),
      scheduleId: map['schedule_id']?.toInt(),
      sportId: map['sport_id']?.toInt() ?? 0,
      locationId: map['location_id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
      time: gameTime,
      isAway: (map['is_away'] ?? 0) == 1,
      levelOfCompetition: map['level_of_competition'],
      gender: map['gender'],
      officialsRequired: map['officials_required']?.toInt() ?? 0,
      officialsHired: map['officials_hired']?.toInt() ?? 0,
      gameFee: map['game_fee'],
      opponent: map['opponent'],
      hireAutomatically: (map['hire_automatically'] ?? 0) == 1,
      method: map['method'],
      status: map['status'] ?? 'Unpublished',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      scheduleName: map['schedule_name'],
      sportName: map['sport_name'],
      locationName: map['location_name'],
    );
  }

  Game copyWith({
    int? id,
    int? scheduleId,
    int? sportId,
    int? locationId,
    int? userId,
    DateTime? date,
    TimeOfDay? time,
    bool? isAway,
    String? levelOfCompetition,
    String? gender,
    int? officialsRequired,
    int? officialsHired,
    String? gameFee,
    String? opponent,
    bool? hireAutomatically,
    String? method,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? scheduleName,
    String? sportName,
    String? locationName,
    List<Official>? assignedOfficials,
  }) {
    return Game(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      sportId: sportId ?? this.sportId,
      locationId: locationId ?? this.locationId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      time: time ?? this.time,
      isAway: isAway ?? this.isAway,
      levelOfCompetition: levelOfCompetition ?? this.levelOfCompetition,
      gender: gender ?? this.gender,
      officialsRequired: officialsRequired ?? this.officialsRequired,
      officialsHired: officialsHired ?? this.officialsHired,
      gameFee: gameFee ?? this.gameFee,
      opponent: opponent ?? this.opponent,
      hireAutomatically: hireAutomatically ?? this.hireAutomatically,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      scheduleName: scheduleName ?? this.scheduleName,
      sportName: sportName ?? this.sportName,
      locationName: locationName ?? this.locationName,
      assignedOfficials: assignedOfficials ?? this.assignedOfficials,
    );
  }
}

// Game Template model
class GameTemplate {
  final int? id;
  final String name;
  final int sportId;
  final int userId;
  final String? scheduleName;
  final DateTime? date;
  final TimeOfDay? time;
  final int? locationId;
  final bool isAwayGame;
  final String? levelOfCompetition;
  final String? gender;
  final int? officialsRequired;
  final String? gameFee;
  final String? opponent;
  final bool? hireAutomatically;
  final String? method;
  final int? officialsListId;
  final List<Map<String, dynamic>>? selectedOfficials;
  final String? officialsListName;
  
  // Include flags
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
  
  final DateTime createdAt;

  // Joined data
  final String? sportName;
  final String? locationName;

  GameTemplate({
    this.id,
    required this.name,
    required this.sportId,
    required this.userId,
    this.scheduleName,
    this.date,
    this.time,
    this.locationId,
    this.isAwayGame = false,
    this.levelOfCompetition,
    this.gender,
    this.officialsRequired,
    this.gameFee,
    this.opponent,
    this.hireAutomatically,
    this.method,
    this.officialsListId,
    this.selectedOfficials,
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
    DateTime? createdAt,
    this.sportName,
    this.locationName,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sport_id': sportId,
      'user_id': userId,
      'schedule_name': scheduleName,
      'date': date?.toIso8601String(),
      'time': time != null ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}' : null,
      'location_id': locationId,
      'is_away_game': isAwayGame ? 1 : 0,
      'level_of_competition': levelOfCompetition,
      'gender': gender,
      'officials_required': officialsRequired,
      'game_fee': gameFee,
      'opponent': opponent,
      'hire_automatically': hireAutomatically != null ? (hireAutomatically! ? 1 : 0) : null,
      'method': method,
      'officials_list_id': officialsListId,
      'include_schedule_name': includeScheduleName ? 1 : 0,
      'include_sport': includeSport ? 1 : 0,
      'include_date': includeDate ? 1 : 0,
      'include_time': includeTime ? 1 : 0,
      'include_location': includeLocation ? 1 : 0,
      'include_is_away_game': includeIsAwayGame ? 1 : 0,
      'include_level_of_competition': includeLevelOfCompetition ? 1 : 0,
      'include_gender': includeGender ? 1 : 0,
      'include_officials_required': includeOfficialsRequired ? 1 : 0,
      'include_game_fee': includeGameFee ? 1 : 0,
      'include_opponent': includeOpponent ? 1 : 0,
      'include_hire_automatically': includeHireAutomatically ? 1 : 0,
      'include_selected_officials': includeSelectedOfficials ? 1 : 0,
      'include_officials_list': includeOfficialsList ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GameTemplate.fromMap(Map<String, dynamic> map) {
    TimeOfDay? gameTime;
    if (map['time'] != null) {
      final timeParts = (map['time'] as String).split(':');
      if (timeParts.length == 2) {
        gameTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }

    return GameTemplate(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      sportId: map['sport_id']?.toInt() ?? 0,
      userId: map['user_id']?.toInt() ?? 0,
      scheduleName: map['schedule_name'],
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
      time: gameTime,
      locationId: map['location_id']?.toInt(),
      isAwayGame: (map['is_away_game'] ?? 0) == 1,
      levelOfCompetition: map['level_of_competition'],
      gender: map['gender'],
      officialsRequired: map['officials_required']?.toInt(),
      gameFee: map['game_fee'],
      opponent: map['opponent'],
      hireAutomatically: map['hire_automatically'] != null ? (map['hire_automatically'] == 1) : null,
      method: map['method'],
      officialsListId: map['officials_list_id']?.toInt(),
      includeScheduleName: (map['include_schedule_name'] ?? 0) == 1,
      includeSport: (map['include_sport'] ?? 0) == 1,
      includeDate: (map['include_date'] ?? 0) == 1,
      includeTime: (map['include_time'] ?? 0) == 1,
      includeLocation: (map['include_location'] ?? 0) == 1,
      includeIsAwayGame: (map['include_is_away_game'] ?? 0) == 1,
      includeLevelOfCompetition: (map['include_level_of_competition'] ?? 0) == 1,
      includeGender: (map['include_gender'] ?? 0) == 1,
      includeOfficialsRequired: (map['include_officials_required'] ?? 0) == 1,
      includeGameFee: (map['include_game_fee'] ?? 0) == 1,
      includeOpponent: (map['include_opponent'] ?? 0) == 1,
      includeHireAutomatically: (map['include_hire_automatically'] ?? 0) == 1,
      includeSelectedOfficials: (map['include_selected_officials'] ?? 0) == 1,
      includeOfficialsList: (map['include_officials_list'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      sportName: map['sport_name'],
      locationName: map['location_name'],
    );
  }
}

// User Setting model
class UserSetting {
  final int? id;
  final int userId;
  final String key;
  final String value;

  UserSetting({
    this.id,
    required this.userId,
    required this.key,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'key': key,
      'value': value,
    };
  }

  factory UserSetting.fromMap(Map<String, dynamic> map) {
    return UserSetting(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      key: map['key'] ?? '',
      value: map['value'] ?? '',
    );
  }
}