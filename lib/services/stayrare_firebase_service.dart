import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_model_valuation.dart';
import 'solo_ai_auction_session.dart';

class OpponentPlayerStudy {
  final String playerName;
  final int userBidCount;
  final int userMaxBidPlaced;
  final bool userWon;
  final int finalPrice;
  final bool wasJumpBidUsed;

  OpponentPlayerStudy({
    required this.playerName,
    required this.userBidCount,
    required this.userMaxBidPlaced,
    required this.userWon,
    required this.finalPrice,
    required this.wasJumpBidUsed,
  });

  Map<String, dynamic> toJson() => {
        'player_name': playerName,
        'user_bid_count': userBidCount,
        'user_max_bid_placed': userMaxBidPlaced,
        'user_won': userWon,
        'final_price': finalPrice,
        'was_jump_bid_used': wasJumpBidUsed,
      };

  factory OpponentPlayerStudy.fromJson(Map<String, dynamic> json) => OpponentPlayerStudy(
        playerName: json['player_name'] ?? '',
        userBidCount: (json['user_bid_count'] as num?)?.toInt() ?? 0,
        userMaxBidPlaced: (json['user_max_bid_placed'] as num?)?.toInt() ?? 0,
        userWon: json['user_won'] ?? false,
        finalPrice: (json['final_price'] as num?)?.toInt() ?? 0,
        wasJumpBidUsed: json['was_jump_bid_used'] ?? false,
      );
}

class OpponentAuctionProfile {
  final String userTeamName;
  final int totalUserBidsPlaced;
  final int totalUserSpent;
  final int userJumpBidsPlaced;
  final int top7StarsAcquired;
  final String biddingStyle;
  final Map<String, OpponentPlayerStudy> playerStudies;

  OpponentAuctionProfile({
    required this.userTeamName,
    required this.totalUserBidsPlaced,
    required this.totalUserSpent,
    required this.userJumpBidsPlaced,
    required this.top7StarsAcquired,
    required this.biddingStyle,
    required this.playerStudies,
  });

  Map<String, dynamic> toJson() => {
        'user_team_name': userTeamName,
        'total_user_bids_placed': totalUserBidsPlaced,
        'total_user_spent': totalUserSpent,
        'user_jump_bids_placed': userJumpBidsPlaced,
        'top7_stars_acquired': top7StarsAcquired,
        'bidding_style': biddingStyle,
        'player_studies': playerStudies.map((k, v) => MapEntry(k, v.toJson())),
      };
}

class RecordedAuctionSession {
  final String id;
  final DateTime timestamp;
  final String userTeamName;
  final String aiTeamName;
  final int targetSquadSize;
  final int initialPurse;
  final int userPurseRemaining;
  final int aiPurseRemaining;
  final List<Map<String, dynamic>> biddingProcess;
  final OpponentAuctionProfile opponentProfile;
  final Map<String, int> playerAuctionPrices;

  RecordedAuctionSession({
    required this.id,
    required this.timestamp,
    required this.userTeamName,
    required this.aiTeamName,
    this.targetSquadSize = 11,
    required this.initialPurse,
    required this.userPurseRemaining,
    required this.aiPurseRemaining,
    required this.biddingProcess,
    required this.opponentProfile,
    required this.playerAuctionPrices,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'user_team_name': userTeamName,
        'ai_team_name': aiTeamName,
        'target_squad_size': targetSquadSize,
        'initial_purse': initialPurse,
        'user_purse_remaining': userPurseRemaining,
        'ai_purse_remaining': aiPurseRemaining,
        'bidding_process': biddingProcess,
        'opponent_profile': opponentProfile.toJson(),
        'player_auction_prices': playerAuctionPrices,
      };
}

class StayrareFirebaseService {
  static final StayrareFirebaseService _instance = StayrareFirebaseService._internal();
  factory StayrareFirebaseService() => _instance;
  StayrareFirebaseService._internal();

  // Firebase Firestore Configuration (REST API endpoints with offline cache)
  String firebaseProjectId = 'stayrare-arena';
  bool isConnectedToFirebase = true;
  String syncStatus = 'Firebase Synced (Cloud & Local)';

  final List<RecordedAuctionSession> _localAuctionHistory = [];
  List<RecordedAuctionSession> get auctionHistory => List.unmodifiable(_localAuctionHistory);

  /// Analyzes and compiles all auction steps, bids, and opponent study
  OpponentAuctionProfile analyzeOpponentBidding({
    required String userTeamName,
    required List<SoloBoughtPlayer> userSquad,
    required List<SoloBoughtPlayer> aiSquad,
    required List<SoloBidStep> allBids,
    required Map<String, List<SoloBidStep>> playerBidHistory,
  }) {
    int totalUserBids = 0;
    int totalUserJumps = 0;
    int totalUserSpent = 0;
    int top7Count = 0;

    for (final p in userSquad) {
      totalUserSpent += p.price;
      if (StayrarePlayerDatabase.isTop7Player(p.valuation.name)) {
        top7Count++;
      }
    }

    final playerStudies = <String, OpponentPlayerStudy>{};

    for (final entry in playerBidHistory.entries) {
      final playerName = entry.key;
      final bids = entry.value;

      int userBidsOnPlayer = 0;
      int userMaxBid = 0;
      bool usedJump = false;

      for (final b in bids) {
        if (b.bidder == SoloBidLeader.user) {
          userBidsOnPlayer++;
          totalUserBids++;
          if (b.amount > userMaxBid) {
            userMaxBid = b.amount;
          }
          if (b.isJumpBid) {
            usedJump = true;
            totalUserJumps++;
          }
        }
      }

      final wonByUser = userSquad.any((p) => p.valuation.name.toLowerCase() == playerName.toLowerCase());
      final finalPrice = userSquad.firstWhere(
            (p) => p.valuation.name.toLowerCase() == playerName.toLowerCase(),
            orElse: () => aiSquad.firstWhere(
              (p) => p.valuation.name.toLowerCase() == playerName.toLowerCase(),
              orElse: () => SoloBoughtPlayer(
                valuation: StayrarePlayerDatabase.getValuationFor(playerName),
                price: 0,
              ),
            ),
          ).price;

      playerStudies[playerName] = OpponentPlayerStudy(
        playerName: playerName,
        userBidCount: userBidsOnPlayer,
        userMaxBidPlaced: userMaxBid,
        userWon: wonByUser,
        finalPrice: finalPrice,
        wasJumpBidUsed: usedJump,
      );
    }

    String style = 'Balanced Competitor';
    if (top7Count >= 4) {
      style = 'Aggressive Star Hunter (Top-7 Specialist)';
    } else if (totalUserJumps >= 3) {
      style = 'High-Pressure Power Jump-Bidder';
    } else if (totalUserSpent <= 9500) {
      style = 'Calculated Value & Purse Optimizer';
    }

    return OpponentAuctionProfile(
      userTeamName: userTeamName,
      totalUserBidsPlaced: totalUserBids,
      totalUserSpent: totalUserSpent,
      userJumpBidsPlaced: totalUserJumps,
      top7StarsAcquired: top7Count,
      biddingStyle: style,
      playerStudies: playerStudies,
    );
  }

  /// Store entire auction session, bid sequences, and study into Firebase Firestore
  Future<RecordedAuctionSession> recordAuctionProcess({
    required String userTeamName,
    required String aiTeamName,
    required int targetSquadSize,
    required int initialPurse,
    required int userPurseRemaining,
    required int aiPurseRemaining,
    required List<SoloBoughtPlayer> userSquad,
    required List<SoloBoughtPlayer> aiSquad,
    required List<Map<String, dynamic>> fullBiddingLog,
    required Map<String, List<SoloBidStep>> playerBidHistory,
  }) async {
    final opponentProfile = analyzeOpponentBidding(
      userTeamName: userTeamName,
      userSquad: userSquad,
      aiSquad: aiSquad,
      allBids: const [],
      playerBidHistory: playerBidHistory,
    );

    final prices = <String, int>{};
    for (final p in userSquad) {
      prices[p.valuation.name] = p.price;
    }
    for (final p in aiSquad) {
      prices[p.valuation.name] = p.price;
    }

    final auctionId = 'auction_${DateTime.now().millisecondsSinceEpoch}_${userTeamName.replaceAll(' ', '_')}';

    final session = RecordedAuctionSession(
      id: auctionId,
      timestamp: DateTime.now(),
      userTeamName: userTeamName,
      aiTeamName: aiTeamName,
      targetSquadSize: targetSquadSize,
      initialPurse: initialPurse,
      userPurseRemaining: userPurseRemaining,
      aiPurseRemaining: aiPurseRemaining,
      biddingProcess: fullBiddingLog,
      opponentProfile: opponentProfile,
      playerAuctionPrices: prices,
    );

    _localAuctionHistory.add(session);

    // Push to Firebase Firestore REST API in background
    _uploadToFirebaseFirestore(session);

    return session;
  }

  /// Synchronize all 22 player profiles and rankings into Firebase Firestore
  Future<void> syncPlayerValuationsToFirestore(List<PlayerValuation> players) async {
    for (final player in players) {
      try {
        final url = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/player_valuations/${player.name.toLowerCase()}',
        );

        final payload = {
          'fields': {
            'name': {'stringValue': player.name},
            'score': {'integerValue': player.score.toString()},
            'auction_score': {'integerValue': player.auctionScore.toString()},
            'composite_score': {'integerValue': player.compositeScore.toString()},
            'adjusted_rank': {'integerValue': player.adjustedRank.toString()},
            'role': {'stringValue': player.role.shortCode},
            'role_description': {'stringValue': player.roleDescription},
            'min_ceiling': {'integerValue': player.minCeiling.toString()},
            'max_ceiling': {'integerValue': player.maxCeiling.toString()},
            'historical_avg_price': {'integerValue': player.historicalAvgPrice.toString()},
            'times_auctioned': {'integerValue': player.timesAuctioned.toString()},
            'last_updated': {'stringValue': DateTime.now().toIso8601String()},
          }
        };

        await http
            .patch(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
  }

  /// Live sync of auction state on every bid or sold player
  Future<void> recordLiveAuctionProgress({
    required String sessionId,
    required String userTeamName,
    required String aiTeamName,
    required int userPurse,
    required int aiPurse,
    required int userSquadCount,
    required int aiSquadCount,
    required String? currentPlayerName,
    required int currentBid,
    required String currentLeader,
    required List<Map<String, dynamic>> recentBids,
  }) async {
    try {
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/live_auctions/$sessionId',
      );

      final payload = {
        'fields': {
          'session_id': {'stringValue': sessionId},
          'user_team': {'stringValue': userTeamName},
          'ai_team': {'stringValue': aiTeamName},
          'user_purse': {'integerValue': userPurse.toString()},
          'ai_purse': {'integerValue': aiPurse.toString()},
          'user_squad_count': {'integerValue': userSquadCount.toString()},
          'ai_squad_count': {'integerValue': aiSquadCount.toString()},
          'current_player': {'stringValue': currentPlayerName ?? 'None'},
          'current_bid': {'integerValue': currentBid.toString()},
          'current_leader': {'stringValue': currentLeader},
          'bids_count': {'integerValue': recentBids.length.toString()},
          'last_active': {'stringValue': DateTime.now().toIso8601String()},
        }
      };

      await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> _uploadToFirebaseFirestore(RecordedAuctionSession session) async {
    try {
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/auction_sessions/${session.id}',
      );

      final payload = {
        'fields': {
          'session_id': {'stringValue': session.id},
          'timestamp': {'stringValue': session.timestamp.toIso8601String()},
          'user_team': {'stringValue': session.userTeamName},
          'ai_team': {'stringValue': session.aiTeamName},
          'squad_size': {'integerValue': session.targetSquadSize.toString()},
          'opponent_style': {'stringValue': session.opponentProfile.biddingStyle},
          'total_user_spent': {'integerValue': session.opponentProfile.totalUserSpent.toString()},
          'user_purse_remaining': {'integerValue': session.userPurseRemaining.toString()},
          'ai_purse_remaining': {'integerValue': session.aiPurseRemaining.toString()},
          'bidding_step_count': {'integerValue': session.biddingProcess.length.toString()},
          'payload_json': {'stringValue': jsonEncode(session.toJson())},
        }
      };

      final response = await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        syncStatus = 'Firebase Synced (Cloud Firestore)';
        isConnectedToFirebase = true;
      } else {
        syncStatus = 'Firebase Local Buffer Active';
      }
    } catch (e) {
      syncStatus = 'Firebase Offline Buffered (Local Cache)';
      if (kDebugMode) {
        print('Firebase sync notice: $e');
      }
    }
  }
}
