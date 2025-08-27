import 'package:flutter/material.dart';
import 'dart:convert';

// User model
class User {
  final int? id;
  final String schedulerType;
  final bool setupCompleted;
  final String? schoolName;
  final String? mascot;
  final String? schoolAddress;
  final String? teamName;
  final String? sport;
  final String? grade;
  final String? gender;
  final String? leagueName;
  final String userType;
  final String? email;
  final String? passwordHash;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final DateTime createdAt;

  User({
    this.id,
    required this.schedulerType,
    this.setupCompleted = false,
    this.schoolName,
    this.mascot,
    this.schoolAddress,
    this.teamName,
    this.sport,
    this.grade,
    this.gender,
    this.leagueName,
    this.userType = 'scheduler',
    this.email,
    this.passwordHash,
    this.firstName,
    this.lastName,
    this.phone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scheduler_type': schedulerType,
      'setup_completed': setupCompleted ? 1 : 0,
      'school_name': schoolName,
      'mascot': mascot,
      'school_address': schoolAddress,
      'team_name': teamName,
      'sport': sport,
      'grade': grade,
      'gender': gender,
      'league_name': leagueName,
      'user_type': userType,
      'email': email,
      'password_hash': passwordHash,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
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
      schoolAddress: map['school_address'],
      teamName: map['team_name'],
      sport: map['sport'],
      grade: map['grade'],
      gender: map['gender'],
      leagueName: map['league_name'],
      userType: map['user_type'] ?? 'scheduler',
      email: map['email'],
      passwordHash: map['password_hash'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      phone: map['phone'],
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
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
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
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
  final String? homeTeamName;
  final DateTime createdAt;

  // Joined data
  final String? sportName;

  Schedule({
    this.id,
    required this.name,
    required this.sportId,
    required this.userId,
    this.homeTeamName,
    DateTime? createdAt,
    this.sportName,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap(
      {bool excludeId = false, bool excludeCreatedAt = false}) {
    final map = <String, dynamic>{
      'name': name,
      'sport_id': sportId,
      'user_id': userId,
      'home_team_name': homeTeamName,
    };

    if (!excludeId) {
      map['id'] = id;
    }

    if (!excludeCreatedAt) {
      map['created_at'] = createdAt.toIso8601String();
    }

    return map;
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      sportId: map['sport_id']?.toInt() ?? 0,
      userId: map['user_id']?.toInt() ?? 0,
      homeTeamName: map['home_team_name'],
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      sportName: map['sport_name'],
    );
  }

  Schedule copyWith({
    int? id,
    String? name,
    int? sportId,
    int? userId,
    String? homeTeamName,
    DateTime? createdAt,
    String? sportName,
  }) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      sportId: sportId ?? this.sportId,
      userId: userId ?? this.userId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
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
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
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
  final int? officialUserId;
  final String? email;
  final String? phone;
  final String? city;
  final String? state;
  final String availabilityStatus;
  final String? profileImageUrl;
  final String? bio;
  final int? experienceYears;
  final String? certificationLevel;
  final bool isUserAccount;
  final double followThroughRate;
  final int totalAcceptedGames;
  final int totalBackedOutGames;
  final DateTime createdAt;

  // Joined data
  final String? sportName;

  Official({
    this.id,
    required this.name,
    this.sportId,
    this.rating,
    required this.userId,
    this.officialUserId,
    this.email,
    this.phone,
    this.city,
    this.state,
    this.availabilityStatus = 'available',
    this.profileImageUrl,
    this.bio,
    this.experienceYears,
    this.certificationLevel,
    this.isUserAccount = false,
    this.followThroughRate = 100.0,
    this.totalAcceptedGames = 0,
    this.totalBackedOutGames = 0,
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
      'official_user_id': officialUserId,
      'email': email,
      'phone': phone,
      'city': city,
      'state': state,
      'availability_status': availabilityStatus,
      'profile_image_url': profileImageUrl,
      'bio': bio,
      'experience_years': experienceYears,
      'certification_level': certificationLevel,
      'is_user_account': isUserAccount ? 1 : 0,
      'follow_through_rate': followThroughRate,
      'total_accepted_games': totalAcceptedGames,
      'total_backed_out_games': totalBackedOutGames,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Official.fromMap(Map<String, dynamic> map) {
    return Official(
      id: map['id']?.toInt(),
      name: map['name']?.toString() ?? '',
      sportId: map['sport_id']?.toInt(),
      rating: map['rating']?.toString(),
      userId: map['user_id']?.toInt() ?? 0,
      officialUserId: map['official_user_id']?.toInt(),
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      city: map['city']?.toString(),
      state: map['state']?.toString(),
      availabilityStatus: map['availability_status']?.toString() ?? 'available',
      profileImageUrl: map['profile_image_url']?.toString(),
      bio: map['bio']?.toString(),
      experienceYears: map['experience_years']?.toInt(),
      certificationLevel: map['certification_level']?.toString(),
      isUserAccount: (map['is_user_account'] ?? 0) == 1,
      followThroughRate: (map['follow_through_rate'] ?? 100.0).toDouble(),
      totalAcceptedGames: map['total_accepted_games']?.toInt() ?? 0,
      totalBackedOutGames: map['total_backed_out_games']?.toInt() ?? 0,
      createdAt: DateTime.parse(
          map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      sportName: map['sport_name']?.toString(),
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
  final String? homeTeam;
  final bool hireAutomatically;
  final String? method;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? scheduleName;
  final String? scheduleHomeTeamName;
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
    this.homeTeam,
    this.hireAutomatically = false,
    this.method,
    this.status = 'Unpublished',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.scheduleName,
    this.scheduleHomeTeamName,
    this.sportName,
    this.locationName,
    this.assignedOfficials = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'sport_id': sportId,
      'location_id': locationId,
      'user_id': userId,
      'date': date?.toIso8601String(),
      'time': time != null
          ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
          : null,
      'is_away': isAway ? 1 : 0,
      'level_of_competition': levelOfCompetition,
      'gender': gender,
      'officials_required': officialsRequired,
      'officials_hired': officialsHired,
      'game_fee': gameFee,
      'opponent': opponent,
      'home_team': homeTeam,
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
      // Handle different types that might come from time field
      if (map['time'] is TimeOfDay) {
        gameTime = map['time'] as TimeOfDay;
      } else if (map['time'] is String) {
        final timeParts = (map['time'] as String).split(':');
        if (timeParts.length == 2) {
          gameTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      }
    }

    final homeTeamFromMap = map['home_team'];

    final game = Game(
      id: map['id']?.toInt(),
      scheduleId: map['schedule_id']?.toInt(),
      sportId: map['sport_id']?.toInt() ?? 0,
      locationId: map['location_id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      date: map['date'] != null
          ? (map['date'] is DateTime
              ? map['date'] as DateTime
              : DateTime.parse(
                  (map['date'] as String?) ?? DateTime.now().toIso8601String()))
          : null,
      time: gameTime,
      isAway: (map['is_away'] ?? 0) == 1,
      levelOfCompetition: map['level_of_competition'],
      gender: map['gender'],
      officialsRequired: map['officials_required']?.toInt() ?? 0,
      officialsHired: map['officials_hired']?.toInt() ?? 0,
      gameFee: map['game_fee'],
      opponent: map['opponent'],
      homeTeam: homeTeamFromMap,
      hireAutomatically: (map['hire_automatically'] ?? 0) == 1,
      method: map['method'],
      status: map['status'] ?? 'Unpublished',
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      scheduleName: map['schedule_name'],
      scheduleHomeTeamName: map['schedule_home_team_name'],
      sportName: map['sport_name'],
      locationName: map['location_name'],
    );

    return game;
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
    String? homeTeam,
    bool? hireAutomatically,
    String? method,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? scheduleName,
    String? scheduleHomeTeamName,
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
      homeTeam: homeTeam ?? this.homeTeam,
      hireAutomatically: hireAutomatically ?? this.hireAutomatically,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      scheduleName: scheduleName ?? this.scheduleName,
      scheduleHomeTeamName: scheduleHomeTeamName ?? this.scheduleHomeTeamName,
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
  final List<Map<String, dynamic>>? selectedLists; // Added for advanced method
  final List<Map<String, dynamic>>? selectedCrews; // Added for crew method
  final String? selectedCrewListName; // Added for crew list name
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
    this.selectedLists, // Added for advanced method
    this.selectedCrews, // Added for crew method
    this.selectedCrewListName, // Added for crew list name
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
      'time': time != null
          ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
          : null,
      'location_id': locationId,
      'is_away_game': isAwayGame ? 1 : 0,
      'level_of_competition': levelOfCompetition,
      'gender': gender,
      'officials_required': officialsRequired,
      'game_fee': gameFee,
      'opponent': opponent,
      'hire_automatically':
          hireAutomatically != null ? (hireAutomatically! ? 1 : 0) : null,
      'method': method,
      'officials_list_id': officialsListId,
      'selected_lists':
          selectedLists != null ? jsonEncode(selectedLists) : null,
      'selected_crews':
          selectedCrews != null ? jsonEncode(selectedCrews) : null,
      'selected_crew_list_name': selectedCrewListName,
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
      final timeParts = ((map['time'] as String?) ?? '0:0').split(':');
      if (timeParts.length == 2) {
        gameTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }

    List<Map<String, dynamic>>? selectedLists;
    if (map['selected_lists'] != null) {
      try {
        final decoded = jsonDecode(map['selected_lists']);
        if (decoded is List) {
          selectedLists = List<Map<String, dynamic>>.from(decoded);
        }
      } catch (e) {
        debugPrint('Error decoding selected_lists: $e');
      }
    }

    List<Map<String, dynamic>>? selectedOfficials;
    if (map['selected_officials'] != null) {
      try {
        final decoded = jsonDecode(map['selected_officials']);
        if (decoded is List) {
          selectedOfficials = List<Map<String, dynamic>>.from(decoded);
        }
      } catch (e) {
        debugPrint('Error decoding selected_officials: $e');
      }
    }

    List<Map<String, dynamic>>? selectedCrews;
    if (map['selected_crews'] != null) {
      try {
        final decoded = jsonDecode(map['selected_crews']);
        if (decoded is List) {
          selectedCrews = List<Map<String, dynamic>>.from(decoded);
        }
      } catch (e) {
        debugPrint('Error decoding selected_crews: $e');
      }
    }

    return GameTemplate(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      sportId: map['sport_id']?.toInt() ?? 0,
      userId: map['user_id']?.toInt() ?? 0,
      scheduleName: map['schedule_name'],
      date: map['date'] != null
          ? (map['date'] is DateTime
              ? map['date'] as DateTime
              : DateTime.parse(
                  (map['date'] as String?) ?? DateTime.now().toIso8601String()))
          : null,
      time: gameTime,
      locationId: map['location_id']?.toInt(),
      isAwayGame: (map['is_away_game'] ?? 0) == 1,
      levelOfCompetition: map['level_of_competition'],
      gender: map['gender'],
      officialsRequired: map['officials_required']?.toInt(),
      gameFee: map['game_fee'],
      opponent: map['opponent'],
      hireAutomatically: map['hire_automatically'] != null
          ? (map['hire_automatically'] == 1)
          : null,
      method: map['method'],
      officialsListId: map['officials_list_id']?.toInt(),
      selectedOfficials: selectedOfficials,
      selectedLists: selectedLists,
      selectedCrews: selectedCrews,
      selectedCrewListName: map['selected_crew_list_name'],
      includeScheduleName: (map['include_schedule_name'] ?? 0) == 1,
      includeSport: (map['include_sport'] ?? 0) == 1,
      includeDate: (map['include_date'] ?? 0) == 1,
      includeTime: (map['include_time'] ?? 0) == 1,
      includeLocation: (map['include_location'] ?? 0) == 1,
      includeIsAwayGame: (map['include_is_away_game'] ?? 0) == 1,
      includeLevelOfCompetition:
          (map['include_level_of_competition'] ?? 0) == 1,
      includeGender: (map['include_gender'] ?? 0) == 1,
      includeOfficialsRequired: (map['include_officials_required'] ?? 0) == 1,
      includeGameFee: (map['include_game_fee'] ?? 0) == 1,
      includeOpponent: (map['include_opponent'] ?? 0) == 1,
      includeHireAutomatically: (map['include_hire_automatically'] ?? 0) == 1,
      includeSelectedOfficials: (map['include_selected_officials'] ?? 0) == 1,
      includeOfficialsList: (map['include_officials_list'] ?? 0) == 1,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      sportName: map['sport_name'],
      locationName: map['location_name'],
      officialsListName: map['officials_list_name'],
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

// Official User model (for authentication)
class OfficialUser {
  final int? id;
  final String email;
  final String passwordHash;
  final String? phone;
  final String firstName;
  final String lastName;
  final bool profileVerified;
  final bool emailVerified;
  final bool phoneVerified;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  OfficialUser({
    this.id,
    required this.email,
    required this.passwordHash,
    this.phone,
    required this.firstName,
    required this.lastName,
    this.profileVerified = false,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'profile_verified': profileVerified ? 1 : 0,
      'email_verified': emailVerified ? 1 : 0,
      'phone_verified': phoneVerified ? 1 : 0,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory OfficialUser.fromMap(Map<String, dynamic> map) {
    return OfficialUser(
      id: map['id']?.toInt(),
      email: map['email']?.toString() ?? '',
      passwordHash: map['password_hash']?.toString() ?? '',
      phone: map['phone']?.toString(),
      firstName: map['first_name']?.toString() ?? '',
      lastName: map['last_name']?.toString() ?? '',
      profileVerified: (map['profile_verified'] ?? 0) == 1,
      emailVerified: (map['email_verified'] ?? 0) == 1,
      phoneVerified: (map['phone_verified'] ?? 0) == 1,
      status: map['status']?.toString() ?? 'active',
      createdAt: DateTime.parse(
          map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

// Game Assignment model
class GameAssignment {
  final int? id;
  final int gameId;
  final int officialId;
  final String? position;
  final String status;
  final int assignedBy;
  final DateTime assignedAt;
  final DateTime? respondedAt;
  final String? responseNotes;
  final double? feeAmount;
  final DateTime? backedOutAt;
  final String? backOutReason;
  final bool excusedBackout;
  final DateTime? excusedAt;
  final int? excusedBy;
  final String? excuseReason;

  // Additional fields from JOIN queries
  DateTime? _gameDate;
  DateTime? _gameTime;
  String? _sportName;
  String? _opponent;
  String? _homeTeam;
  String? _locationName;
  String? _locationAddress;
  String? _scheduleName;

  // Getters for the additional fields
  DateTime? get gameDate => _gameDate;
  DateTime? get gameTime => _gameTime;
  String? get sportName => _sportName;
  String? get opponent => _opponent;
  String? get homeTeam => _homeTeam;
  String? get locationName => _locationName;
  String? get locationAddress => _locationAddress;
  String? get scheduleName => _scheduleName;

  GameAssignment({
    this.id,
    required this.gameId,
    required this.officialId,
    this.position,
    this.status = 'pending',
    required this.assignedBy,
    DateTime? assignedAt,
    this.respondedAt,
    this.responseNotes,
    this.feeAmount,
    this.backedOutAt,
    this.backOutReason,
    this.excusedBackout = false,
    this.excusedAt,
    this.excusedBy,
    this.excuseReason,
  }) : assignedAt = assignedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'official_id': officialId,
      'position': position,
      'status': status,
      'assigned_by': assignedBy,
      'assigned_at': assignedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'response_notes': responseNotes,
      'fee_amount': feeAmount,
      'backed_out_at': backedOutAt?.toIso8601String(),
      'back_out_reason': backOutReason,
      'excused_backout': excusedBackout ? 1 : 0,
      'excused_at': excusedAt?.toIso8601String(),
      'excused_by': excusedBy,
      'excuse_reason': excuseReason,
    };
  }

  factory GameAssignment.fromMap(Map<String, dynamic> map) {
    final assignment = GameAssignment(
      id: map['id']?.toInt(),
      gameId: map['game_id']?.toInt() ?? 0,
      officialId: map['official_id']?.toInt() ?? 0,
      position: map['position']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      assignedBy: map['assigned_by']?.toInt() ?? 0,
      assignedAt: DateTime.parse(
          map['assigned_at']?.toString() ?? DateTime.now().toIso8601String()),
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'].toString())
          : null,
      responseNotes: map['response_notes']?.toString(),
      feeAmount: map['fee_amount'] != null
          ? double.tryParse(map['fee_amount'].toString()) ?? 0.0
          : 0.0,
      backedOutAt: map['backed_out_at'] != null
          ? DateTime.parse(map['backed_out_at'].toString())
          : null,
      backOutReason: map['back_out_reason']?.toString(),
      excusedBackout: (map['excused_backout'] ?? 0) == 1,
      excusedAt: map['excused_at'] != null
          ? DateTime.parse(map['excused_at'].toString())
          : null,
      excusedBy: map['excused_by']?.toInt(),
      excuseReason: map['excuse_reason']?.toString(),
    );

    // Add additional fields from JOIN queries if they exist
    if (map.containsKey('date')) {
      assignment._gameDate =
          map['date'] != null ? DateTime.parse(map['date'].toString()) : null;
    }
    if (map.containsKey('time')) {
      assignment._gameTime = map['time'] != null
          ? DateTime.parse('1970-01-01 ${map['time'].toString()}')
          : null;
    }
    if (map.containsKey('sport_name')) {
      assignment._sportName = map['sport_name']?.toString();
    }
    if (map.containsKey('opponent')) {
      assignment._opponent = map['opponent']?.toString();
    }
    if (map.containsKey('home_team')) {
      assignment._homeTeam = map['home_team']?.toString();
    }
    if (map.containsKey('location_name')) {
      assignment._locationName = map['location_name']?.toString();
    }
    if (map.containsKey('location_address')) {
      assignment._locationAddress = map['location_address']?.toString();
    }
    if (map.containsKey('schedule_name')) {
      assignment._scheduleName = map['schedule_name']?.toString();
    }

    return assignment;
  }
}

// Official Availability model
class OfficialAvailability {
  final int? id;
  final int officialId;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String status;
  final String? notes;
  final DateTime createdAt;

  OfficialAvailability({
    this.id,
    required this.officialId,
    required this.date,
    this.startTime,
    this.endTime,
    this.status = 'available',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'official_id': officialId,
      'date': date.toIso8601String().split('T')[0], // Date only
      'start_time':
          startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
      'end_time':
          endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OfficialAvailability.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      return null;
    }

    return OfficialAvailability(
      id: map['id']?.toInt(),
      officialId: map['official_id']?.toInt() ?? 0,
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      startTime: parseTime(map['start_time']),
      endTime: parseTime(map['end_time']),
      status: map['status'] ?? 'available',
      notes: map['notes'],
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Official Sports model
class OfficialSport {
  final int? id;
  final int officialId;
  final int sportId;
  final String? certificationLevel;
  final int? yearsExperience;
  final String? competitionLevels;
  final bool isPrimary;
  final DateTime createdAt;

  // Joined data
  final String? sportName;

  OfficialSport({
    this.id,
    required this.officialId,
    required this.sportId,
    this.certificationLevel,
    this.yearsExperience,
    this.competitionLevels,
    this.isPrimary = false,
    DateTime? createdAt,
    this.sportName,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'official_id': officialId,
      'sport_id': sportId,
      'certification_level': certificationLevel,
      'years_experience': yearsExperience,
      'competition_levels': competitionLevels,
      'is_primary': isPrimary ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OfficialSport.fromMap(Map<String, dynamic> map) {
    return OfficialSport(
      id: map['id']?.toInt(),
      officialId: map['official_id']?.toInt() ?? 0,
      sportId: map['sport_id']?.toInt() ?? 0,
      certificationLevel: map['certification_level']?.toString(),
      yearsExperience: map['years_experience']?.toInt(),
      competitionLevels: map['competition_levels']?.toString(),
      isPrimary: (map['is_primary'] ?? 0) == 1,
      createdAt: DateTime.parse(
          map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      sportName: map['sport_name']?.toString(),
    );
  }
}

// Official Notification model
class OfficialNotification {
  final int? id;
  final int officialId;
  final String type;
  final String title;
  final String message;
  final int? relatedGameId;
  final DateTime? readAt;
  final DateTime createdAt;

  OfficialNotification({
    this.id,
    required this.officialId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedGameId,
    this.readAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'official_id': officialId,
      'type': type,
      'title': title,
      'message': message,
      'related_game_id': relatedGameId,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OfficialNotification.fromMap(Map<String, dynamic> map) {
    return OfficialNotification(
      id: map['id']?.toInt(),
      officialId: map['official_id']?.toInt() ?? 0,
      type: map['type']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      relatedGameId: map['related_game_id']?.toInt(),
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'].toString())
          : null,
      createdAt: DateTime.parse(
          map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

// Official Settings model
class OfficialSetting {
  final int? id;
  final int officialId;
  final String settingKey;
  final String settingValue;

  OfficialSetting({
    this.id,
    required this.officialId,
    required this.settingKey,
    required this.settingValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'official_id': officialId,
      'setting_key': settingKey,
      'setting_value': settingValue,
    };
  }

  factory OfficialSetting.fromMap(Map<String, dynamic> map) {
    return OfficialSetting(
      id: map['id']?.toInt(),
      officialId: map['official_id']?.toInt() ?? 0,
      settingKey: map['setting_key'] ?? '',
      settingValue: map['setting_value'] ?? '',
    );
  }
}

// Official Backout Notification model
class OfficialBackoutNotification {
  final int? id;
  final int assignmentId;
  final int officialId;
  final int schedulerId;
  final int gameId;
  final DateTime backedOutAt;
  final String backOutReason;
  final DateTime? excusedAt;
  final int? excusedBy;
  final String? excuseReason;
  final DateTime? notificationSentAt;
  final DateTime? notificationReadAt;
  final DateTime createdAt;

  // Joined data for display
  final String? officialName;
  final String? gameSport;
  final String? gameOpponent;
  final String? gameDate;
  final String? gameTime;

  OfficialBackoutNotification({
    this.id,
    required this.assignmentId,
    required this.officialId,
    required this.schedulerId,
    required this.gameId,
    required this.backedOutAt,
    required this.backOutReason,
    this.excusedAt,
    this.excusedBy,
    this.excuseReason,
    this.notificationSentAt,
    this.notificationReadAt,
    DateTime? createdAt,
    this.officialName,
    this.gameSport,
    this.gameOpponent,
    this.gameDate,
    this.gameTime,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'official_id': officialId,
      'scheduler_id': schedulerId,
      'game_id': gameId,
      'backed_out_at': backedOutAt.toIso8601String(),
      'back_out_reason': backOutReason,
      'excused_at': excusedAt?.toIso8601String(),
      'excused_by': excusedBy,
      'excuse_reason': excuseReason,
      'notification_sent_at': notificationSentAt?.toIso8601String(),
      'notification_read_at': notificationReadAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OfficialBackoutNotification.fromMap(Map<String, dynamic> map) {
    return OfficialBackoutNotification(
      id: map['id']?.toInt(),
      assignmentId: map['assignment_id']?.toInt() ?? 0,
      officialId: map['official_id']?.toInt() ?? 0,
      schedulerId: map['scheduler_id']?.toInt() ?? 0,
      gameId: map['game_id']?.toInt() ?? 0,
      backedOutAt: DateTime.parse(
          map['backed_out_at'] ?? DateTime.now().toIso8601String()),
      backOutReason: map['back_out_reason'] ?? '',
      excusedAt:
          map['excused_at'] != null ? DateTime.parse(map['excused_at']) : null,
      excusedBy: map['excused_by']?.toInt(),
      excuseReason: map['excuse_reason'],
      notificationSentAt: map['notification_sent_at'] != null
          ? DateTime.parse(map['notification_sent_at'])
          : null,
      notificationReadAt: map['notification_read_at'] != null
          ? DateTime.parse(map['notification_read_at'])
          : null,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      officialName: map['official_name'],
      gameSport: map['game_sport'],
      gameOpponent: map['game_opponent'],
      gameDate: map['game_date'],
      gameTime: map['game_time'],
    );
  }

  bool get isExcused => excusedAt != null;
  bool get hasBeenRead => notificationReadAt != null;
}

// Sport Defaults model
class SportDefaults {
  final int? id;
  final int userId;
  final int? sportId;
  final String sportName;
  final String? gender;
  final int? officialsRequired;
  final String? gameFee;
  final String? levelOfCompetition;

  SportDefaults({
    this.id,
    required this.userId,
    this.sportId,
    required this.sportName,
    this.gender,
    this.officialsRequired,
    this.gameFee,
    this.levelOfCompetition,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'sport_id': sportId,
      'gender': gender,
      'officials_required': officialsRequired,
      'game_fee': gameFee,
      'level_of_competition': levelOfCompetition,
    };
  }

  factory SportDefaults.fromMap(Map<String, dynamic> map) {
    return SportDefaults(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      sportId: map['sport_id']?.toInt(),
      sportName: map['sport_name'] ?? '',
      gender: map['gender'],
      officialsRequired: map['officials_required']?.toInt(),
      gameFee: map['game_fee'],
      levelOfCompetition: map['level_of_competition'],
    );
  }
}

// Official Endorsement model
class OfficialEndorsement {
  final int? id;
  final int endorsedOfficialId;
  final int endorserUserId;
  final String endorserType; // 'scheduler' or 'official'
  final DateTime createdAt;

  OfficialEndorsement({
    this.id,
    required this.endorsedOfficialId,
    required this.endorserUserId,
    required this.endorserType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'endorsed_official_id': endorsedOfficialId,
      'endorser_user_id': endorserUserId,
      'endorser_type': endorserType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OfficialEndorsement.fromMap(Map<String, dynamic> map) {
    return OfficialEndorsement(
      id: map['id']?.toInt(),
      endorsedOfficialId: map['endorsed_official_id']?.toInt() ?? 0,
      endorserUserId: map['endorser_user_id']?.toInt() ?? 0,
      endorserType: map['endorser_type'] ?? '',
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Crew Type model
class CrewType {
  final int? id;
  final int sportId;
  final String levelOfCompetition;
  final int requiredOfficials;
  final String? description;
  final DateTime createdAt;

  // Joined data
  final String? sportName;

  CrewType({
    this.id,
    required this.sportId,
    required this.levelOfCompetition,
    required this.requiredOfficials,
    this.description,
    DateTime? createdAt,
    this.sportName,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sport_id': sportId,
      'level_of_competition': levelOfCompetition,
      'required_officials': requiredOfficials,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CrewType.fromMap(Map<String, dynamic> map) {
    return CrewType(
      id: map['id']?.toInt(),
      sportId: map['sport_id']?.toInt() ?? 0,
      levelOfCompetition: map['level_of_competition'] ?? '',
      requiredOfficials: map['required_officials']?.toInt() ?? 0,
      description: map['description'],
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      sportName: map['sport_name'],
    );
  }
}

// Crew model
class Crew {
  final int? id;
  final String name;
  final int crewTypeId;
  final int crewChiefId;
  final int createdBy;
  final bool isActive;
  final String paymentMethod;
  final double? crewFeePerGame;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? sportName;
  final String? levelOfCompetition;
  final int? requiredOfficials;
  final String? crewChiefName;
  final String? crewChiefCity;
  final String? crewChiefState;
  final List<CrewMember>? members;
  final List<String>? competitionLevels;

  Crew({
    this.id,
    required this.name,
    required this.crewTypeId,
    required this.crewChiefId,
    required this.createdBy,
    this.isActive = true,
    this.paymentMethod = 'equal_split',
    this.crewFeePerGame,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sportName,
    this.levelOfCompetition,
    this.requiredOfficials,
    this.crewChiefName,
    this.crewChiefCity,
    this.crewChiefState,
    this.members,
    this.competitionLevels,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'crew_type_id': crewTypeId,
      'crew_chief_id': crewChiefId,
      'created_by': createdBy,
      'is_active': isActive ? 1 : 0,
      'payment_method': paymentMethod,
      'crew_fee_per_game': crewFeePerGame,
      'competition_levels':
          competitionLevels != null ? jsonEncode(competitionLevels) : '[]',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Crew.fromMap(Map<String, dynamic> map) {
    return Crew(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      crewTypeId: map['crew_type_id']?.toInt() ?? 0,
      crewChiefId: map['crew_chief_id']?.toInt() ?? 0,
      createdBy: map['created_by']?.toInt() ?? 0,
      isActive: (map['is_active'] ?? 1) == 1,
      paymentMethod: map['payment_method'] ?? 'equal_split',
      crewFeePerGame: map['crew_fee_per_game']?.toDouble(),
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      sportName: map['sport_name'],
      levelOfCompetition: map['level_of_competition'],
      requiredOfficials: map['required_officials']?.toInt(),
      crewChiefName: map['crew_chief_name'],
      crewChiefCity: map['crew_chief_city'],
      crewChiefState: map['crew_chief_state'],
      competitionLevels: map['competition_levels'] != null
          ? List<String>.from(jsonDecode(map['competition_levels'] ?? '[]'))
          : null,
    );
  }

  // Computed properties
  bool get isFullyStaffed =>
      members != null && members!.length == requiredOfficials;
  bool get canBeHired => isActive && isFullyStaffed;
}

// Crew Member model
class CrewMember {
  final int? id;
  final int crewId;
  final int officialId;
  final String position;
  final String? gamePosition;
  final DateTime joinedAt;
  final String status;

  // Joined data
  final String? officialName;
  final String? phone;
  final String? email;

  CrewMember({
    this.id,
    required this.crewId,
    required this.officialId,
    this.position = 'member',
    this.gamePosition,
    DateTime? joinedAt,
    this.status = 'active',
    this.officialName,
    this.phone,
    this.email,
  }) : joinedAt = joinedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'crew_id': crewId,
      'official_id': officialId,
      'position': position,
      'game_position': gamePosition,
      'joined_at': joinedAt.toIso8601String(),
      'status': status,
    };
  }

  factory CrewMember.fromMap(Map<String, dynamic> map) {
    return CrewMember(
      id: map['id']?.toInt(),
      crewId: map['crew_id']?.toInt() ?? 0,
      officialId: map['official_id']?.toInt() ?? 0,
      position: map['position'] ?? 'member',
      gamePosition: map['game_position'],
      joinedAt:
          DateTime.parse(map['joined_at'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'active',
      officialName: map['official_name'],
      phone: map['phone'],
      email: map['email'],
    );
  }
}

// Crew Availability model
class CrewAvailability {
  final int? id;
  final int crewId;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String status;
  final String? notes;
  final int setBy;
  final DateTime createdAt;

  CrewAvailability({
    this.id,
    required this.crewId,
    required this.date,
    this.startTime,
    this.endTime,
    this.status = 'available',
    this.notes,
    required this.setBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'crew_id': crewId,
      'date': date.toIso8601String().split('T')[0],
      'start_time':
          startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
      'end_time':
          endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
      'status': status,
      'notes': notes,
      'set_by': setBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CrewAvailability.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      return null;
    }

    return CrewAvailability(
      id: map['id']?.toInt(),
      crewId: map['crew_id']?.toInt() ?? 0,
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      startTime: parseTime(map['start_time']),
      endTime: parseTime(map['end_time']),
      status: map['status'] ?? 'available',
      notes: map['notes'],
      setBy: map['set_by']?.toInt() ?? 0,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Crew Assignment model
class CrewAssignment {
  final int? id;
  final int gameId;
  final int crewId;
  final int assignedBy;
  final int crewChiefId;
  final String status;
  final DateTime assignedAt;
  final DateTime? respondedAt;
  final String? responseNotes;
  final double? totalFeeAmount;
  final String paymentMethod;
  final bool crewChiefResponseRequired;

  // Joined game data
  final DateTime? gameDate;
  final TimeOfDay? gameTime;
  final String? opponent;
  final String? homeTeam;
  final String? locationName;
  final String? sportName;

  // Crew data
  final String? crewName;
  final String? crewChiefName;
  final List<CrewMember>? crewMembers;

  CrewAssignment({
    this.id,
    required this.gameId,
    required this.crewId,
    required this.assignedBy,
    required this.crewChiefId,
    this.status = 'pending',
    DateTime? assignedAt,
    this.respondedAt,
    this.responseNotes,
    this.totalFeeAmount,
    this.paymentMethod = 'equal_split',
    this.crewChiefResponseRequired = true,
    this.gameDate,
    this.gameTime,
    this.opponent,
    this.homeTeam,
    this.locationName,
    this.sportName,
    this.crewName,
    this.crewChiefName,
    this.crewMembers,
  }) : assignedAt = assignedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'crew_id': crewId,
      'assigned_by': assignedBy,
      'crew_chief_id': crewChiefId,
      'status': status,
      'assigned_at': assignedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'response_notes': responseNotes,
      'total_fee_amount': totalFeeAmount,
      'payment_method': paymentMethod,
      'crew_chief_response_required': crewChiefResponseRequired ? 1 : 0,
    };
  }

  factory CrewAssignment.fromMap(Map<String, dynamic> map) {
    TimeOfDay? gameTime;
    if (map['time'] != null) {
      final timeParts = ((map['time'] as String?) ?? '0:0').split(':');
      if (timeParts.length == 2) {
        gameTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }

    return CrewAssignment(
      id: map['id']?.toInt(),
      gameId: map['game_id']?.toInt() ?? 0,
      crewId: map['crew_id']?.toInt() ?? 0,
      assignedBy: map['assigned_by']?.toInt() ?? 0,
      crewChiefId: map['crew_chief_id']?.toInt() ?? 0,
      status: map['status'] ?? 'pending',
      assignedAt: DateTime.parse(
          map['assigned_at'] ?? DateTime.now().toIso8601String()),
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'])
          : null,
      responseNotes: map['response_notes'],
      totalFeeAmount: map['total_fee_amount']?.toDouble(),
      paymentMethod: map['payment_method'] ?? 'equal_split',
      crewChiefResponseRequired:
          (map['crew_chief_response_required'] ?? 1) == 1,
      gameDate: map['date'] != null ? DateTime.parse(map['date']) : null,
      gameTime: gameTime,
      opponent: map['opponent'],
      homeTeam: map['home_team'],
      locationName: map['location_name'],
      sportName: map['sport_name'],
      crewName: map['crew_name'],
      crewChiefName: map['crew_chief_name'],
    );
  }
}

// Payment Distribution model
class PaymentDistribution {
  final int? id;
  final int crewAssignmentId;
  final int officialId;
  final double amount;
  final String? notes;
  final int createdBy;
  final DateTime createdAt;

  PaymentDistribution({
    this.id,
    required this.crewAssignmentId,
    required this.officialId,
    required this.amount,
    this.notes,
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'crew_assignment_id': crewAssignmentId,
      'official_id': officialId,
      'amount': amount,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PaymentDistribution.fromMap(Map<String, dynamic> map) {
    return PaymentDistribution(
      id: map['id']?.toInt(),
      crewAssignmentId: map['crew_assignment_id']?.toInt() ?? 0,
      officialId: map['official_id']?.toInt() ?? 0,
      amount: map['amount']?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdBy: map['created_by']?.toInt() ?? 0,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Crew Invitation model
class CrewInvitation {
  final int? id;
  final int crewId;
  final int invitedOfficialId;
  final int invitedBy;
  final String status;
  final DateTime invitedAt;
  final DateTime? respondedAt;
  final String? responseNotes;
  final String position;
  final String? gamePosition;

  // Additional fields populated from joins
  final String? crewName;
  final String? invitedOfficialName;
  final String? inviterName;
  final String? sportName;
  final String? levelOfCompetition;

  CrewInvitation({
    this.id,
    required this.crewId,
    required this.invitedOfficialId,
    required this.invitedBy,
    this.status = 'pending',
    DateTime? invitedAt,
    this.respondedAt,
    this.responseNotes,
    this.position = 'member',
    this.gamePosition,
    this.crewName,
    this.invitedOfficialName,
    this.inviterName,
    this.sportName,
    this.levelOfCompetition,
  }) : invitedAt = invitedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'crew_id': crewId,
      'invited_official_id': invitedOfficialId,
      'invited_by': invitedBy,
      'status': status,
      'invited_at': invitedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'response_notes': responseNotes,
      'position': position,
      'game_position': gamePosition,
    };
  }

  factory CrewInvitation.fromMap(Map<String, dynamic> map) {
    return CrewInvitation(
      id: map['id']?.toInt(),
      crewId: map['crew_id']?.toInt() ?? 0,
      invitedOfficialId: map['invited_official_id']?.toInt() ?? 0,
      invitedBy: map['invited_by']?.toInt() ?? 0,
      status: map['status'] ?? 'pending',
      invitedAt:
          DateTime.parse(map['invited_at'] ?? DateTime.now().toIso8601String()),
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'])
          : null,
      responseNotes: map['response_notes'],
      position: map['position'] ?? 'member',
      gamePosition: map['game_position'],
      crewName: map['crew_name'],
      invitedOfficialName: map['invited_official_name'],
      inviterName: map['inviter_name'],
      sportName: map['sport_name'],
      levelOfCompetition: map['level_of_competition'],
    );
  }
}

// User Settings model for managing user preferences
class UserSettings {
  final int? id;
  final int userId;

  // Notification preferences
  final bool emailNotifications;
  final bool pushNotifications;
  final bool textNotifications;
  final bool gameReminders;
  final bool scheduleUpdates;
  final bool assignmentAlerts;
  final bool emergencyNotifications;

  // Privacy preferences
  final bool shareProfile;
  final bool showAvailability;
  final bool allowContactFromOfficials;

  // App preferences
  final bool defaultDarkMode;
  final String notificationSound;
  final bool vibrationEnabled;
  final String dateFormat;
  final String timeFormat;
  final bool autoRefresh;
  final int refreshInterval;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    this.id,
    required this.userId,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.textNotifications = false,
    this.gameReminders = true,
    this.scheduleUpdates = true,
    this.assignmentAlerts = true,
    this.emergencyNotifications = true,
    this.shareProfile = true,
    this.showAvailability = true,
    this.allowContactFromOfficials = true,
    this.defaultDarkMode = false,
    this.notificationSound = 'default',
    this.vibrationEnabled = true,
    this.dateFormat = 'MM/dd/yyyy',
    this.timeFormat = '12',
    this.autoRefresh = true,
    this.refreshInterval = 30,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'email_notifications': emailNotifications ? 1 : 0,
      'push_notifications': pushNotifications ? 1 : 0,
      'text_notifications': textNotifications ? 1 : 0,
      'game_reminders': gameReminders ? 1 : 0,
      'schedule_updates': scheduleUpdates ? 1 : 0,
      'assignment_alerts': assignmentAlerts ? 1 : 0,
      'emergency_notifications': emergencyNotifications ? 1 : 0,
      'share_profile': shareProfile ? 1 : 0,
      'show_availability': showAvailability ? 1 : 0,
      'allow_contact_from_officials': allowContactFromOfficials ? 1 : 0,
      'default_dark_mode': defaultDarkMode ? 1 : 0,
      'notification_sound': notificationSound,
      'vibration_enabled': vibrationEnabled ? 1 : 0,
      'date_format': dateFormat,
      'time_format': timeFormat,
      'auto_refresh': autoRefresh ? 1 : 0,
      'refresh_interval': refreshInterval,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      emailNotifications: (map['email_notifications'] ?? 1) == 1,
      pushNotifications: (map['push_notifications'] ?? 1) == 1,
      textNotifications: (map['text_notifications'] ?? 0) == 1,
      gameReminders: (map['game_reminders'] ?? 1) == 1,
      scheduleUpdates: (map['schedule_updates'] ?? 1) == 1,
      assignmentAlerts: (map['assignment_alerts'] ?? 1) == 1,
      emergencyNotifications: (map['emergency_notifications'] ?? 1) == 1,
      shareProfile: (map['share_profile'] ?? 1) == 1,
      showAvailability: (map['show_availability'] ?? 1) == 1,
      allowContactFromOfficials:
          (map['allow_contact_from_officials'] ?? 1) == 1,
      defaultDarkMode: (map['default_dark_mode'] ?? 0) == 1,
      notificationSound: map['notification_sound'] ?? 'default',
      vibrationEnabled: (map['vibration_enabled'] ?? 1) == 1,
      dateFormat: map['date_format'] ?? 'MM/dd/yyyy',
      timeFormat: map['time_format'] ?? '12',
      autoRefresh: (map['auto_refresh'] ?? 1) == 1,
      refreshInterval: map['refresh_interval']?.toInt() ?? 30,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }
}

// General Notification model - replaces specific notification types
class Notification {
  final int? id;
  final int recipientId; // scheduler user ID
  final String
      type; // 'backout', 'game_filling', 'official_interest', 'official_claim'
  final String title;
  final String message;
  final Map<String, dynamic>? data; // JSON data specific to notification type
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  // Related data for display (populated from joins)
  final String? officialName;
  final String? gameSport;
  final String? gameOpponent;
  final DateTime? gameDate;
  final String? gameTime;

  Notification({
    this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    DateTime? createdAt,
    this.readAt,
    this.officialName,
    this.gameSport,
    this.gameOpponent,
    this.gameDate,
    this.gameTime,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipient_id': recipientId,
      'type': type,
      'title': title,
      'message': message,
      'data': data != null ? jsonEncode(data) : null,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id']?.toInt(),
      recipientId: map['recipient_id']?.toInt() ?? 0,
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      data: map['data'] != null ? jsonDecode(map['data']) : null,
      isRead: (map['is_read'] ?? 0) == 1,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      officialName: map['official_name'],
      gameSport: map['game_sport'],
      gameOpponent: map['game_opponent'],
      gameDate:
          map['game_date'] != null ? DateTime.parse(map['game_date']) : null,
      gameTime: map['game_time'],
    );
  }

  // Helper methods for different notification types
  static Notification createBackoutNotification({
    required int schedulerId,
    required String officialName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    required String reason,
    Map<String, dynamic>? additionalData,
  }) {
    return Notification(
      recipientId: schedulerId,
      type: 'backout',
      title: 'Official Backed Out',
      message:
          '$officialName backed out of $gameSport game ($gameOpponent) on ${gameDate.toString().split(' ')[0]} at $gameTime. Reason: $reason',
      data: {
        'official_name': officialName,
        'game_sport': gameSport,
        'game_opponent': gameOpponent,
        'game_date': gameDate.toIso8601String(),
        'game_time': gameTime,
        'reason': reason,
        ...?additionalData,
      },
    );
  }

  static Notification createCrewBackoutNotification({
    required int schedulerId,
    required String crewName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    required String reason,
    required Map<String, dynamic> crewData,
    Map<String, dynamic>? additionalData,
  }) {
    return Notification(
      recipientId: schedulerId,
      type: 'crew_backout',
      title: 'Crew Backed Out',
      message:
          '$crewName backed out of $gameSport game ($gameOpponent) on ${gameDate.toString().split(' ')[0]} at $gameTime. Reason: $reason',
      data: {
        'crew_name': crewName,
        'game_sport': gameSport,
        'game_opponent': gameOpponent,
        'game_date': gameDate.toIso8601String(),
        'game_time': gameTime,
        'reason': reason,
        'crew_data': crewData,
        ...?additionalData,
      },
    );
  }

  static Notification createGameFillingNotification({
    required int schedulerId,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    required int officialsNeeded,
    required int daysUntilGame,
    Map<String, dynamic>? additionalData,
  }) {
    return Notification(
      recipientId: schedulerId,
      type: 'game_filling',
      title: 'Game Needs Officials',
      message:
          '$gameSport game ($gameOpponent) on ${gameDate.toString().split(' ')[0]} at $gameTime needs $officialsNeeded more official${officialsNeeded == 1 ? '' : 's'}. Game is in $daysUntilGame day${daysUntilGame == 1 ? '' : 's'}.',
      data: {
        'game_sport': gameSport,
        'game_opponent': gameOpponent,
        'game_date': gameDate.toIso8601String(),
        'game_time': gameTime,
        'officials_needed': officialsNeeded,
        'days_until_game': daysUntilGame,
        ...?additionalData,
      },
    );
  }

  static Notification createOfficialInterestNotification({
    required int schedulerId,
    required String officialName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    Map<String, dynamic>? additionalData,
  }) {
    return Notification(
      recipientId: schedulerId,
      type: 'official_interest',
      title: 'Official Expressed Interest',
      message:
          '$officialName expressed interest in officiating $gameSport game ($gameOpponent) on ${gameDate.toString().split(' ')[0]} at $gameTime.',
      data: {
        'official_name': officialName,
        'game_sport': gameSport,
        'game_opponent': gameOpponent,
        'game_date': gameDate.toIso8601String(),
        'game_time': gameTime,
        ...?additionalData,
      },
    );
  }

  static Notification createOfficialClaimNotification({
    required int schedulerId,
    required String officialName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    Map<String, dynamic>? additionalData,
  }) {
    return Notification(
      recipientId: schedulerId,
      type: 'official_claim',
      title: 'Official Claimed Game',
      message:
          '$officialName claimed $gameSport game ($gameOpponent) on ${gameDate.toString().split(' ')[0]} at $gameTime.',
      data: {
        'official_name': officialName,
        'game_sport': gameSport,
        'game_opponent': gameOpponent,
        'game_date': gameDate.toIso8601String(),
        'game_time': gameTime,
        ...?additionalData,
      },
    );
  }

  /// Create notification to official when they are removed from a game
  static Notification createOfficialRemovalNotification({
    required int officialId,
    required String schedulerName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    Map<String, dynamic>? additionalData,
  }) {
    return Notification(
      recipientId: officialId,
      type: 'official_removal',
      title: 'Removed from Game',
      message:
          'You have been removed from the $gameSport game ($gameOpponent) on ${gameDate.toString().split(' ')[0]} at $gameTime by $schedulerName.',
      data: {
        'scheduler_name': schedulerName,
        'game_sport': gameSport,
        'game_opponent': gameOpponent,
        'game_date': gameDate.toIso8601String(),
        'game_time': gameTime,
        ...?additionalData,
      },
    );
  }

  static Notification createBackoutExcuseNotification({
    required int officialId,
    required String schedulerName,
    required String gameSport,
    required String gameOpponent,
    required DateTime gameDate,
    required String gameTime,
    required String excuseReason,
    Map<String, dynamic>? additionalData,
  }) {
    return Notification(
      recipientId: officialId,
      type: 'backout_excuse',
      title: 'Backout Excused - Follow-Through Rate Restored',
      message:
          'Your backout for the $gameSport game ($gameOpponent) on ${gameDate.toString().split(' ')[0]} at $gameTime has been excused by $schedulerName. Your follow-through rate has been restored. Reason: $excuseReason',
      data: {
        'scheduler_name': schedulerName,
        'game_sport': gameSport,
        'game_opponent': gameOpponent,
        'game_date': gameDate.toIso8601String(),
        'game_time': gameTime,
        'excuse_reason': excuseReason,
        ...?additionalData,
      },
    );
  }
}

// Notification Settings model for scheduler notification preferences
class NotificationSettings {
  final int? id;
  final int userId;

  // Game filling notifications
  final bool gameFillingNotificationsEnabled;
  final List<int>
      gameFillingReminderDays; // Days before game to send notifications

  // Official activity notifications
  final bool officialInterestNotificationsEnabled;
  final bool officialClaimNotificationsEnabled;

  // Backout notifications (always enabled for schedulers)
  final bool backoutNotificationsEnabled;

  // Communication preferences
  final bool emailEnabled;
  final bool smsEnabled;

  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationSettings({
    this.id,
    required this.userId,
    this.gameFillingNotificationsEnabled = true,
    this.gameFillingReminderDays = const [
      14,
      7,
      3,
      2,
      1
    ], // Default: 2 weeks, 1 week, 3/2/1 days
    this.officialInterestNotificationsEnabled = false,
    this.officialClaimNotificationsEnabled = false,
    this.backoutNotificationsEnabled = true,
    this.emailEnabled = false,
    this.smsEnabled = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'game_filling_notifications_enabled':
          gameFillingNotificationsEnabled ? 1 : 0,
      'game_filling_reminder_days': jsonEncode(gameFillingReminderDays),
      'official_interest_notifications_enabled':
          officialInterestNotificationsEnabled ? 1 : 0,
      'official_claim_notifications_enabled':
          officialClaimNotificationsEnabled ? 1 : 0,
      'backout_notifications_enabled': backoutNotificationsEnabled ? 1 : 0,
      'email_enabled': emailEnabled ? 1 : 0,
      'sms_enabled': smsEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      gameFillingNotificationsEnabled:
          (map['game_filling_notifications_enabled'] ?? 1) == 1,
      gameFillingReminderDays: map['game_filling_reminder_days'] != null
          ? List<int>.from(jsonDecode(map['game_filling_reminder_days']))
          : [14, 7, 3, 2, 1],
      officialInterestNotificationsEnabled:
          (map['official_interest_notifications_enabled'] ?? 0) == 1,
      officialClaimNotificationsEnabled:
          (map['official_claim_notifications_enabled'] ?? 0) == 1,
      backoutNotificationsEnabled:
          (map['backout_notifications_enabled'] ?? 1) == 1,
      emailEnabled: (map['email_enabled'] ?? 0) == 1,
      smsEnabled: (map['sms_enabled'] ?? 0) == 1,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  NotificationSettings copyWith({
    int? id,
    int? userId,
    bool? gameFillingNotificationsEnabled,
    List<int>? gameFillingReminderDays,
    bool? officialInterestNotificationsEnabled,
    bool? officialClaimNotificationsEnabled,
    bool? backoutNotificationsEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gameFillingNotificationsEnabled: gameFillingNotificationsEnabled ??
          this.gameFillingNotificationsEnabled,
      gameFillingReminderDays:
          gameFillingReminderDays ?? this.gameFillingReminderDays,
      officialInterestNotificationsEnabled:
          officialInterestNotificationsEnabled ??
              this.officialInterestNotificationsEnabled,
      officialClaimNotificationsEnabled: officialClaimNotificationsEnabled ??
          this.officialClaimNotificationsEnabled,
      backoutNotificationsEnabled:
          backoutNotificationsEnabled ?? this.backoutNotificationsEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Game List Quota model for Advanced Method (Multiple Lists)
class GameListQuota {
  final int? id;
  final int gameId;
  final int listId;
  final int minOfficials;
  final int maxOfficials;
  final int currentOfficials;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? listName;
  final String? sportName;

  GameListQuota({
    this.id,
    required this.gameId,
    required this.listId,
    required this.minOfficials,
    required this.maxOfficials,
    this.currentOfficials = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.listName,
    this.sportName,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'list_id': listId,
      'min_officials': minOfficials,
      'max_officials': maxOfficials,
      'current_officials': currentOfficials,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory GameListQuota.fromMap(Map<String, dynamic> map) {
    return GameListQuota(
      id: map['id']?.toInt(),
      gameId: map['game_id']?.toInt() ?? 0,
      listId: map['list_id']?.toInt() ?? 0,
      minOfficials: map['min_officials']?.toInt() ?? 0,
      maxOfficials: map['max_officials']?.toInt() ?? 0,
      currentOfficials: map['current_officials']?.toInt() ?? 0,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      listName: map['list_name'],
      sportName: map['sport_name'],
    );
  }

  GameListQuota copyWith({
    int? id,
    int? gameId,
    int? listId,
    int? minOfficials,
    int? maxOfficials,
    int? currentOfficials,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? listName,
    String? sportName,
  }) {
    return GameListQuota(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      listId: listId ?? this.listId,
      minOfficials: minOfficials ?? this.minOfficials,
      maxOfficials: maxOfficials ?? this.maxOfficials,
      currentOfficials: currentOfficials ?? this.currentOfficials,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      listName: listName ?? this.listName,
      sportName: sportName ?? this.sportName,
    );
  }

  // Check if this quota has been satisfied (min requirement met)
  bool get isMinimumSatisfied => currentOfficials >= minOfficials;

  // Check if this quota is at maximum capacity
  bool get isAtMaximum => currentOfficials >= maxOfficials;

  // Check if this quota can accept more officials
  bool get canAcceptMore => currentOfficials < maxOfficials;

  // Get remaining slots available
  int get remainingSlots => maxOfficials - currentOfficials;

  // Get shortfall (how many more needed to meet minimum)
  int get shortfall =>
      minOfficials > currentOfficials ? minOfficials - currentOfficials : 0;
}

// Official List Assignment model to track which officials from which lists are assigned to games
class OfficialListAssignment {
  final int? id;
  final int gameId;
  final int officialId;
  final int listId;
  final DateTime assignedAt;

  // Joined data
  final String? officialName;
  final String? listName;

  OfficialListAssignment({
    this.id,
    required this.gameId,
    required this.officialId,
    required this.listId,
    DateTime? assignedAt,
    this.officialName,
    this.listName,
  }) : assignedAt = assignedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'official_id': officialId,
      'list_id': listId,
      'assigned_at': assignedAt.toIso8601String(),
    };
  }

  factory OfficialListAssignment.fromMap(Map<String, dynamic> map) {
    return OfficialListAssignment(
      id: map['id']?.toInt(),
      gameId: map['game_id']?.toInt() ?? 0,
      officialId: map['official_id']?.toInt() ?? 0,
      listId: map['list_id']?.toInt() ?? 0,
      assignedAt: DateTime.parse(
          map['assigned_at'] ?? DateTime.now().toIso8601String()),
      officialName: map['official_name'],
      listName: map['list_name'],
    );
  }
}

// Game Dismissal model
class GameDismissal {
  final int? id;
  final int gameId;
  final int officialId;
  final String? reason;
  final DateTime dismissedAt;

  // Additional fields from JOIN queries
  String? _sportName;
  String? _opponent;
  String? _homeTeam;
  DateTime? _gameDate;
  DateTime? _gameTime;
  String? _locationName;

  // Getters for the additional fields
  String? get sportName => _sportName;
  String? get opponent => _opponent;
  String? get homeTeam => _homeTeam;
  DateTime? get gameDate => _gameDate;
  DateTime? get gameTime => _gameTime;
  String? get locationName => _locationName;

  GameDismissal({
    this.id,
    required this.gameId,
    required this.officialId,
    this.reason,
    DateTime? dismissedAt,
  }) : dismissedAt = dismissedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'official_id': officialId,
      'reason': reason,
      'dismissed_at': dismissedAt.toIso8601String(),
    };
  }

  factory GameDismissal.fromMap(Map<String, dynamic> map) {
    final dismissal = GameDismissal(
      id: map['id']?.toInt(),
      gameId: map['game_id']?.toInt() ?? 0,
      officialId: map['official_id']?.toInt() ?? 0,
      reason: map['reason'],
      dismissedAt: DateTime.parse(
          map['dismissed_at'] ?? DateTime.now().toIso8601String()),
    );

    // Add additional fields from JOIN queries if they exist
    if (map.containsKey('sport_name')) {
      dismissal._sportName = map['sport_name'];
    }
    if (map.containsKey('opponent')) {
      dismissal._opponent = map['opponent'];
    }
    if (map.containsKey('home_team')) {
      dismissal._homeTeam = map['home_team'];
    }
    if (map.containsKey('date')) {
      dismissal._gameDate =
          map['date'] != null ? DateTime.parse(map['date']) : null;
    }
    if (map.containsKey('time')) {
      dismissal._gameTime = map['time'] != null
          ? DateTime.parse('1970-01-01 ${map['time']}')
          : null;
    }
    if (map.containsKey('location_name')) {
      dismissal._locationName = map['location_name'];
    }

    return dismissal;
  }

  GameDismissal copyWith({
    int? id,
    int? gameId,
    int? officialId,
    String? reason,
    DateTime? dismissedAt,
  }) {
    return GameDismissal(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      officialId: officialId ?? this.officialId,
      reason: reason ?? this.reason,
      dismissedAt: dismissedAt ?? this.dismissedAt,
    );
  }
}

// Team model
class Team {
  final int? id;
  final String name;
  final int userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Team({
    this.id,
    required this.name,
    required this.userId,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'],
      name: map['name'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Team copyWith({
    int? id,
    String? name,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
