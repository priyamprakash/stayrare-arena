enum PersonRole { owner, player }
enum PersonStatus { active, exited, pending }
enum PlayerCategory { normal, marquee }
enum SigningType { auction, rtm, latePool, replacement, trade }
enum AttendanceStatus { inStatus, outStatus, maybeStatus }
enum MatchRosterRole { playing, common, sitout }
enum RtmStage { increaseBid, confirmMatch }

extension PlayerCategoryExtension on PlayerCategory {
  int get basePrice {
    switch (this) {
      case PlayerCategory.marquee:
        return 500;
      case PlayerCategory.normal:
        return 100;
    }
  }

  String get label {
    switch (this) {
      case PlayerCategory.marquee:
        return 'Marquee';
      case PlayerCategory.normal:
        return 'Normal';
    }
  }
}

class Person {
  final String id;
  final String name;
  final PersonRole role;
  PlayerCategory category;
  PersonStatus status;

  Person({
    required this.id,
    required this.name,
    required this.role,
    this.category = PlayerCategory.normal,
    this.status = PersonStatus.active,
  });

  int get basePrice => category.basePrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'category': category.name,
        'status': status.name,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'],
        name: json['name'],
        role: PersonRole.values.byName(json['role']),
        category: PlayerCategory.values.byName(json['category'] ?? 'normal'),
        status: PersonStatus.values.byName(json['status'] ?? 'active'),
      );
}

class Signing {
  final String id;
  final String personId;
  final String teamId;
  final int price;
  final SigningType type;
  final DateTime timestamp;

  Signing({
    required this.id,
    required this.personId,
    required this.teamId,
    required this.price,
    required this.type,
    required this.timestamp,
  });
}

class Refund {
  final String id;
  final String signingId;
  final String personId;
  final String teamId;
  final int amount;
  final String reason;
  final DateTime timestamp;

  Refund({
    required this.id,
    required this.signingId,
    required this.personId,
    required this.teamId,
    required this.amount,
    required this.reason,
    required this.timestamp,
  });
}

class Bid {
  final String id;
  final String personId;
  final String teamId;
  final int amount;
  final DateTime timestamp;

  Bid({
    required this.id,
    required this.personId,
    required this.teamId,
    required this.amount,
    required this.timestamp,
  });
}

class CricketMatch {
  final int number;
  final DateTime date;
  bool isCompleted;

  CricketMatch({
    required this.number,
    required this.date,
    this.isCompleted = false,
  });
}

class Attendance {
  final int matchNumber;
  final String personId;
  AttendanceStatus status;
  DateTime updatedAt;

  Attendance({
    required this.matchNumber,
    required this.personId,
    required this.status,
    required this.updatedAt,
  });
}

class RosterEntry {
  final int matchNumber;
  final String personId;
  final String teamId;
  final MatchRosterRole role;

  RosterEntry({
    required this.matchNumber,
    required this.personId,
    required this.teamId,
    required this.role,
  });
}

class AuditLog {
  final String id;
  final String actor;
  final String action;
  final String details;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.actor,
    required this.action,
    required this.details,
    required this.timestamp,
  });
}

class TeamData {
  final String id;
  final String name;
  final String ownerPersonId;
  final String ownerName;

  TeamData({
    required this.id,
    required this.name,
    required this.ownerPersonId,
    required this.ownerName,
  });
}
