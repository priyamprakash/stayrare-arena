enum CricketRole {
  bat('Batsman', '🏏', 'BAT'),
  bowl('Bowler', '🎯', 'BOWL'),
  allRounder('All-Rounder', '⚡', 'AR');

  final String label;
  final String icon;
  final String shortCode;
  const CricketRole(this.label, this.icon, this.shortCode);
}

class PlayerValuation {
  final String name;
  final int score; // Original Skill / Talent Score (0 - 100)
  int auctionScore; // Dynamic Market Auction Score (0 - 100 based on money spent across auctions)
  int historicalAvgPrice; // Historical average winning price in ₹
  int timesAuctioned; // Number of recorded auctions
  int adjustedRank; // Dynamic composite rank
  final int minCeiling;
  final int maxCeiling;
  final String roleDescription;
  final CricketRole role;
  final bool isMarqueeDefault;

  PlayerValuation({
    required this.name,
    required this.score,
    int? auctionScore,
    int? historicalAvgPrice,
    this.timesAuctioned = 1,
    this.adjustedRank = 0,
    required this.minCeiling,
    required this.maxCeiling,
    this.roleDescription = 'All-Rounder',
    this.role = CricketRole.allRounder,
    this.isMarqueeDefault = false,
  })  : auctionScore = auctionScore ?? score,
        historicalAvgPrice = historicalAvgPrice ?? ((minCeiling + maxCeiling) ~/ 2);

  int get baseCeiling => (minCeiling + maxCeiling) ~/ 2;

  /// Composite ranking score combining baseline player skill (60%) and real auction market demand (40%)
  int get compositeScore => ((score * 0.6) + (auctionScore * 0.4)).round();

  String get tierBadge {
    if (compositeScore >= 85) return 'ELITE (85+)';
    if (compositeScore >= 70) return 'STAR (70-84)';
    if (compositeScore >= 40) return 'CORE (40-69)';
    return 'VALUE (<40)';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'auction_score': auctionScore,
        'historical_avg_price': historicalAvgPrice,
        'times_auctioned': timesAuctioned,
        'adjusted_rank': adjustedRank,
        'min_ceiling': minCeiling,
        'max_ceiling': maxCeiling,
        'role': role.shortCode,
        'role_description': roleDescription,
        'is_marquee': isMarqueeDefault,
      };

  factory PlayerValuation.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String?)?.toLowerCase() ?? 'ar';
    CricketRole role;
    if (roleStr == 'bat') {
      role = CricketRole.bat;
    } else if (roleStr == 'bowl') {
      role = CricketRole.bowl;
    } else {
      role = CricketRole.allRounder;
    }

    return PlayerValuation(
      name: json['name'] ?? 'Unknown',
      score: (json['score'] as num?)?.toInt() ?? 50,
      auctionScore: (json['auction_score'] as num?)?.toInt(),
      historicalAvgPrice: (json['historical_avg_price'] as num?)?.toInt(),
      timesAuctioned: (json['times_auctioned'] as num?)?.toInt() ?? 1,
      adjustedRank: (json['adjusted_rank'] as num?)?.toInt() ?? 0,
      minCeiling: (json['min_ceiling'] as num?)?.toInt() ?? 750,
      maxCeiling: (json['max_ceiling'] as num?)?.toInt() ?? 750,
      role: role,
      roleDescription: json['role_description'] ?? 'All-Rounder',
      isMarqueeDefault: json['is_marquee'] ?? false,
    );
  }
}

class AiBidDecision {
  final String action; // 'bid' or 'pass'
  final int? amount;
  final String strategyNote;
  final String? trashTalk;

  AiBidDecision({
    required this.action,
    this.amount,
    String? strategyNote,
    String? confidenceNote,
    this.trashTalk,
  }) : strategyNote = strategyNote ?? confidenceNote ?? '';

  // Backward compatibility alias
  String get confidenceNote => strategyNote;

  bool get isBid => action == 'bid';
  bool get isPass => action == 'pass';

  Map<String, dynamic> toJson() => {
        'action': action,
        'amount': amount,
        'strategy_note': strategyNote,
        'trash_talk': trashTalk,
      };

  factory AiBidDecision.fromJson(Map<String, dynamic> json) => AiBidDecision(
        action: json['action'] ?? 'pass',
        amount: json['amount'] as int?,
        strategyNote: json['strategy_note'] ?? json['confidence_note'] ?? '',
        trashTalk: json['trash_talk'] as String?,
      );
}

class StayrarePlayerDatabase {
  static const Set<String> top7PlayerNames = {
    'Priyam',
    'Ashutosh',
    'Sangam',
    'Avinash',
    'Saurabh',
    'Sunny',
    'Rahul',
  };

  static bool isTop7Player(String name) {
    final clean = name.trim().toLowerCase();
    return top7PlayerNames.any((t) => t.toLowerCase() == clean);
  }

  static List<PlayerValuation> get officialValuations => [
        PlayerValuation(name: 'Priyam', score: 93, auctionScore: 95, historicalAvgPrice: 3400, minCeiling: 3000, maxCeiling: 3800, isMarqueeDefault: true, role: CricketRole.allRounder, roleDescription: 'Explosive All-Rounder & Striker'),
        PlayerValuation(name: 'Ashutosh', score: 89, auctionScore: 90, historicalAvgPrice: 3100, minCeiling: 2750, maxCeiling: 3500, isMarqueeDefault: true, role: CricketRole.allRounder, roleDescription: 'Bowling All-Rounder & Seamer'),
        PlayerValuation(name: 'Sangam', score: 89, auctionScore: 90, historicalAvgPrice: 3100, minCeiling: 2750, maxCeiling: 3500, isMarqueeDefault: true, role: CricketRole.allRounder, roleDescription: 'Batting All-Rounder & Striker'),
        PlayerValuation(name: 'Avinash', score: 86, auctionScore: 84, historicalAvgPrice: 2750, minCeiling: 2500, maxCeiling: 3000, isMarqueeDefault: true, role: CricketRole.allRounder, roleDescription: 'Anchor Batter & All-Rounder'),
        PlayerValuation(name: 'Saurabh', score: 82, auctionScore: 80, historicalAvgPrice: 2450, minCeiling: 2200, maxCeiling: 2750, isMarqueeDefault: true, role: CricketRole.allRounder, roleDescription: 'Clutch Finisher & All-Rounder'),
        PlayerValuation(name: 'Sunny', score: 75, auctionScore: 74, historicalAvgPrice: 2250, minCeiling: 2000, maxCeiling: 2500, isMarqueeDefault: true, role: CricketRole.bat, roleDescription: 'Dynamic Middle-Order Gun'),
        PlayerValuation(name: 'Rahul', score: 68, auctionScore: 70, historicalAvgPrice: 2150, minCeiling: 1900, maxCeiling: 2400, isMarqueeDefault: true, role: CricketRole.bat, roleDescription: 'Dependable Anchor Batsman'),
        PlayerValuation(name: 'Ritesh', score: 61, auctionScore: 60, historicalAvgPrice: 1250, minCeiling: 1250, maxCeiling: 1250, role: CricketRole.allRounder, roleDescription: 'Batting All-Rounder'),
        PlayerValuation(name: 'Aman', score: 59, auctionScore: 58, historicalAvgPrice: 1250, minCeiling: 1250, maxCeiling: 1250, role: CricketRole.allRounder, roleDescription: 'Wicket-Taker & Quick Run Getter'),
        PlayerValuation(name: 'Ikschit', score: 57, auctionScore: 56, historicalAvgPrice: 1250, minCeiling: 1250, maxCeiling: 1250, role: CricketRole.bat, roleDescription: 'Reliable Squad Batter'),
        PlayerValuation(name: 'Alok', score: 55, auctionScore: 54, historicalAvgPrice: 1250, minCeiling: 1250, maxCeiling: 1250, role: CricketRole.bowl, roleDescription: 'Steady Seamer & Utility Bowler'),
        PlayerValuation(name: 'Amit', score: 50, auctionScore: 48, historicalAvgPrice: 750, minCeiling: 750, maxCeiling: 750, role: CricketRole.bat, roleDescription: 'Reliable Middle-Order Batter'),
        PlayerValuation(name: 'Tinku', score: 50, auctionScore: 48, historicalAvgPrice: 750, minCeiling: 750, maxCeiling: 750, role: CricketRole.bowl, roleDescription: 'Pinch Hitter & Bowler'),
        PlayerValuation(name: 'Mohan', score: 45, auctionScore: 44, historicalAvgPrice: 750, minCeiling: 750, maxCeiling: 750, role: CricketRole.bowl, roleDescription: 'Death Overs Specialist'),
        PlayerValuation(name: 'Piyush', score: 45, auctionScore: 44, historicalAvgPrice: 750, minCeiling: 750, maxCeiling: 750, role: CricketRole.bowl, roleDescription: 'Solid Field & Swing Bowler'),
        PlayerValuation(name: 'Rohan', score: 41, auctionScore: 38, historicalAvgPrice: 500, minCeiling: 500, maxCeiling: 500, role: CricketRole.bat, roleDescription: 'Middle-Order Support Batter'),
        PlayerValuation(name: 'Satish', score: 41, auctionScore: 38, historicalAvgPrice: 500, minCeiling: 500, maxCeiling: 500, role: CricketRole.bowl, roleDescription: 'Pure Line & Length Bowler'),
        PlayerValuation(name: 'Niranjan', score: 30, auctionScore: 28, historicalAvgPrice: 300, minCeiling: 300, maxCeiling: 300, role: CricketRole.bat, roleDescription: 'Backup Squad Batter'),
        PlayerValuation(name: 'Mohit', score: 25, auctionScore: 24, historicalAvgPrice: 300, minCeiling: 300, maxCeiling: 300, role: CricketRole.bat, roleDescription: 'Emerging Batter'),
        PlayerValuation(name: 'Shaurya', score: 16, auctionScore: 16, historicalAvgPrice: 200, minCeiling: 200, maxCeiling: 200, role: CricketRole.bat, roleDescription: 'Late-Order Reserve'),
        PlayerValuation(name: 'Aashish', score: 11, auctionScore: 12, historicalAvgPrice: 200, minCeiling: 200, maxCeiling: 200, role: CricketRole.bat, roleDescription: 'Squad Depth Specialist'),
        PlayerValuation(name: 'Dev', score: 5, auctionScore: 5, historicalAvgPrice: 100, minCeiling: 100, maxCeiling: 100, role: CricketRole.bat, roleDescription: 'Base Entry Player'),
      ];

  static PlayerValuation getValuationFor(String playerName) {
    final clean = playerName.trim().toLowerCase();
    
    // Normalize alternate spellings like Ikchit -> Ikschit
    for (final val in officialValuations) {
      final valClean = val.name.toLowerCase();
      if (valClean == clean) return val;
      if (clean == 'ikchit' && valClean == 'ikschit') return val;
      if (clean == 'aditya' && valClean == 'priyam') {
        return PlayerValuation(name: 'Aditya', score: 78, minCeiling: 2200, maxCeiling: 2200, isMarqueeDefault: true, roleDescription: 'Top-Order Stroke Maker');
      }
      if (clean == 'pawan' && valClean == 'rahul') {
        return PlayerValuation(name: 'Pawan', score: 48, minCeiling: 650, maxCeiling: 650, roleDescription: 'Medium Pacer');
      }
      if (clean == 'shubham' && valClean == 'mohan') {
        return PlayerValuation(name: 'Shubham', score: 52, minCeiling: 800, maxCeiling: 800, roleDescription: 'All-Rounder');
      }
    }

    // Default heuristic for custom / unknown players
    return PlayerValuation(
      name: playerName,
      score: 50,
      minCeiling: 750,
      maxCeiling: 750,
      roleDescription: 'Auction Pool Contender',
    );
  }
}
