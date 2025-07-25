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
  final int? officialUserId;
  final String? email;
  final String? phone;
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
      name: map['name'] ?? '',
      sportId: map['sport_id']?.toInt(),
      rating: map['rating'],
      userId: map['user_id']?.toInt() ?? 0,
      officialUserId: map['official_user_id']?.toInt(),
      email: map['email'],
      phone: map['phone'],
      availabilityStatus: map['availability_status'] ?? 'available',
      profileImageUrl: map['profile_image_url'],
      bio: map['bio'],
      experienceYears: map['experience_years']?.toInt(),
      certificationLevel: map['certification_level'],
      isUserAccount: (map['is_user_account'] ?? 0) == 1,
      followThroughRate: (map['follow_through_rate'] ?? 100.0).toDouble(),
      totalAcceptedGames: map['total_accepted_games']?.toInt() ?? 0,
      totalBackedOutGames: map['total_backed_out_games']?.toInt() ?? 0,
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
  final String? homeTeam;
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
    this.homeTeam,
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
    // Debug logging to track null homeTeam values
    if (homeTeam == null || homeTeam!.trim().isEmpty) {
    }
    
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
      final timeParts = ((map['time'] as String?) ?? '0:0').split(':');
      if (timeParts.length == 2) {
        gameTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }
    
    // Enhanced debug logging to track homeTeam issue
    final homeTeamFromMap = map['home_team'];
    print('🔍 Game.fromMap() DEBUG:');
    print('   Game ID: ${map['id']}');
    print('   Opponent: "${map['opponent']}"');
    print('   All map keys: ${map.keys.toList()}');

    final game = Game(
      id: map['id']?.toInt(),
      scheduleId: map['schedule_id']?.toInt(),
      sportId: map['sport_id']?.toInt() ?? 0,
      locationId: map['location_id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      date: map['date'] != null ? 
        (map['date'] is DateTime ? map['date'] as DateTime : DateTime.parse((map['date'] as String?) ?? DateTime.now().toIso8601String())) : null,
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
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      scheduleName: map['schedule_name'],
      sportName: map['sport_name'],
      locationName: map['location_name'],
    );
    
    print('🔍 End Game.fromMap() DEBUG');
    
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
      final timeParts = ((map['time'] as String?) ?? '0:0').split(':');
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
      date: map['date'] != null ? 
        (map['date'] is DateTime ? map['date'] as DateTime : DateTime.parse((map['date'] as String?) ?? DateTime.now().toIso8601String())) : null,
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
  }) : createdAt = createdAt ?? DateTime.now(),
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
      email: map['email'] ?? '',
      passwordHash: map['password_hash'] ?? '',
      phone: map['phone'],
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      profileVerified: (map['profile_verified'] ?? 0) == 1,
      emailVerified: (map['email_verified'] ?? 0) == 1,
      phoneVerified: (map['phone_verified'] ?? 0) == 1,
      status: map['status'] ?? 'active',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
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
  
  // Getters for the additional fields
  DateTime? get gameDate => _gameDate;
  DateTime? get gameTime => _gameTime;
  String? get sportName => _sportName;
  String? get opponent => _opponent;
  String? get homeTeam => _homeTeam;
  String? get locationName => _locationName;
  String? get locationAddress => _locationAddress;

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
      position: map['position'],
      status: map['status'] ?? 'pending',
      assignedBy: map['assigned_by']?.toInt() ?? 0,
      assignedAt: DateTime.parse(map['assigned_at'] ?? DateTime.now().toIso8601String()),
      respondedAt: map['responded_at'] != null ? DateTime.parse(map['responded_at']) : null,
      responseNotes: map['response_notes'],
      feeAmount: map['fee_amount']?.toDouble(),
      backedOutAt: map['backed_out_at'] != null ? DateTime.parse(map['backed_out_at']) : null,
      backOutReason: map['back_out_reason'],
      excusedBackout: (map['excused_backout'] ?? 0) == 1,
      excusedAt: map['excused_at'] != null ? DateTime.parse(map['excused_at']) : null,
      excusedBy: map['excused_by']?.toInt(),
      excuseReason: map['excuse_reason'],
    );
    
    // Add additional fields from JOIN queries if they exist
    if (map.containsKey('date')) {
      assignment._gameDate = map['date'] != null ? DateTime.parse(map['date']) : null;
    }
    if (map.containsKey('time')) {
      assignment._gameTime = map['time'] != null ? DateTime.parse('1970-01-01 ${map['time']}') : null;
    }
    if (map.containsKey('sport_name')) {
      assignment._sportName = map['sport_name'];
    }
    if (map.containsKey('opponent')) {
      assignment._opponent = map['opponent'];
    }
    if (map.containsKey('home_team')) {
      assignment._homeTeam = map['home_team'];
    }
    if (map.containsKey('location_name')) {
      assignment._locationName = map['location_name'];
    }
    if (map.containsKey('location_address')) {
      assignment._locationAddress = map['location_address'];
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
      'start_time': startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
      'end_time': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
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
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
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
      'is_primary': isPrimary ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OfficialSport.fromMap(Map<String, dynamic> map) {
    return OfficialSport(
      id: map['id']?.toInt(),
      officialId: map['official_id']?.toInt() ?? 0,
      sportId: map['sport_id']?.toInt() ?? 0,
      certificationLevel: map['certification_level'],
      yearsExperience: map['years_experience']?.toInt(),
      isPrimary: (map['is_primary'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      sportName: map['sport_name'],
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
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      relatedGameId: map['related_game_id']?.toInt(),
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
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
      backedOutAt: DateTime.parse(map['backed_out_at'] ?? DateTime.now().toIso8601String()),
      backOutReason: map['back_out_reason'] ?? '',
      excusedAt: map['excused_at'] != null ? DateTime.parse(map['excused_at']) : null,
      excusedBy: map['excused_by']?.toInt(),
      excuseReason: map['excuse_reason'],
      notificationSentAt: map['notification_sent_at'] != null ? DateTime.parse(map['notification_sent_at']) : null,
      notificationReadAt: map['notification_read_at'] != null ? DateTime.parse(map['notification_read_at']) : null,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
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
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
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
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
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
    this.members,
    this.competitionLevels,
  }) : createdAt = createdAt ?? DateTime.now(),
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
      'competition_levels': competitionLevels != null ? jsonEncode(competitionLevels) : '[]',
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
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      sportName: map['sport_name'],
      levelOfCompetition: map['level_of_competition'],
      requiredOfficials: map['required_officials']?.toInt(),
      crewChiefName: map['crew_chief_name'],
      competitionLevels: map['competition_levels'] != null 
          ? List<String>.from(jsonDecode(map['competition_levels'] ?? '[]'))
          : null,
    );
  }

  // Computed properties
  bool get isFullyStaffed => members != null && members!.length == requiredOfficials;
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
      joinedAt: DateTime.parse(map['joined_at'] ?? DateTime.now().toIso8601String()),
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
      'start_time': startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
      'end_time': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
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
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
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
      assignedAt: DateTime.parse(map['assigned_at'] ?? DateTime.now().toIso8601String()),
      respondedAt: map['responded_at'] != null ? DateTime.parse(map['responded_at']) : null,
      responseNotes: map['response_notes'],
      totalFeeAmount: map['total_fee_amount']?.toDouble(),
      paymentMethod: map['payment_method'] ?? 'equal_split',
      crewChiefResponseRequired: (map['crew_chief_response_required'] ?? 1) == 1,
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
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
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
      invitedAt: DateTime.parse(map['invited_at'] ?? DateTime.now().toIso8601String()),
      respondedAt: map['responded_at'] != null ? DateTime.parse(map['responded_at']) : null,
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