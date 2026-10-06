import 'package:flutter/foundation.dart';
import '../models/ai_model_valuation.dart';
import 'stayrare_firebase_service.dart';

class LearnedAuctionInsight {
  final String playerName;
  final int oldAuctionScore;
  final int newAuctionScore;
  final int oldRank;
  final int newRank;
  final int finalWinningPrice;
  final String winner;
  final String learnedAdjustmentNote;

  LearnedAuctionInsight({
    required this.playerName,
    required this.oldAuctionScore,
    required this.newAuctionScore,
    required this.oldRank,
    required this.newRank,
    required this.finalWinningPrice,
    required this.winner,
    required this.learnedAdjustmentNote,
  });
}

class StayrareAiLearner extends ChangeNotifier {
  static final StayrareAiLearner _instance = StayrareAiLearner._internal();
  factory StayrareAiLearner() => _instance;
  StayrareAiLearner._internal() {
    _initLearnedValuations();
  }

  final Map<String, PlayerValuation> _learnedDatabase = {};
  final List<LearnedAuctionInsight> _latestAuctionInsights = [];
  int totalAuctionsLearned = 0;
  bool get hasLearnedData => totalAuctionsLearned > 0;

  List<PlayerValuation> get rankedPlayers {
    final list = _learnedDatabase.values.toList();
    list.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));
    for (int i = 0; i < list.length; i++) {
      list[i].adjustedRank = i + 1;
    }
    return list;
  }

  List<LearnedAuctionInsight> get latestInsights => List.unmodifiable(_latestAuctionInsights);

  void _initLearnedValuations() {
    _learnedDatabase.clear();
    for (final p in StayrarePlayerDatabase.officialValuations) {
      _learnedDatabase[p.name.toLowerCase()] = p;
    }
    _recalculateRankings();
  }

  void resetToDefaults() {
    totalAuctionsLearned = 0;
    _latestAuctionInsights.clear();
    _initLearnedValuations();
    notifyListeners();
  }

  PlayerValuation getPlayerValuation(String name) {
    return _learnedDatabase[name.trim().toLowerCase()] ?? StayrarePlayerDatabase.getValuationFor(name);
  }

  void _recalculateRankings() {
    final list = _learnedDatabase.values.toList();
    list.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));
    for (int i = 0; i < list.length; i++) {
      list[i].adjustedRank = i + 1;
    }
  }

  /// Process completed auction, learn opponent bidding behavior, update Auction Scores and Rankings
  List<LearnedAuctionInsight> learnFromCompletedAuction(RecordedAuctionSession session) {
    _latestAuctionInsights.clear();
    totalAuctionsLearned++;

    final oldRanks = <String, int>{};
    for (final p in rankedPlayers) {
      oldRanks[p.name] = p.adjustedRank;
    }

    final prices = session.playerAuctionPrices;
    final opponentStudies = session.opponentProfile.playerStudies;

    for (final entry in prices.entries) {
      final playerName = entry.key;
      final winningPrice = entry.value;
      final player = getPlayerValuation(playerName);
      final oldScore = player.auctionScore;
      final oldRank = oldRanks[player.name] ?? 10;

      // Calculate new historical average price with exponential smoothing (weighted towards recent)
      final n = player.timesAuctioned;
      final newAvg = ((player.historicalAvgPrice * n + winningPrice) / (n + 1)).round();
      player.historicalAvgPrice = newAvg;
      player.timesAuctioned = n + 1;

      // Compute normalized Auction Score (0 - 100 based on price relative to top star purse benchmarks)
      // ₹3800 = ~95-100 Auction Score, ₹2000 = ~70 Auction Score, ₹100 = ~5 Auction Score
      final rawScore = ((newAvg / 3800.0) * 100).round().clamp(5, 99);
      player.auctionScore = rawScore;

      // Adaptively scale future auction ceilings according to learned market prices!
      player.minCeiling = (newAvg * 0.85).round().clamp(100, 4000);
      player.maxCeiling = (newAvg * 1.25).round().clamp(150, 4500);

      // Opponent Study Insight Note
      final study = opponentStudies[playerName];
      String note;
      if (study != null && study.userBidCount > 2) {
        if (study.userWon) {
          note = 'Opponent aggressively pursued ${player.name} (Max bid ₹${study.userMaxBidPlaced}). Market demand elevated!';
        } else {
          note = 'Opponent pushed ${player.name} up to ₹${study.userMaxBidPlaced} before dropping out. AI extracted maximum purse!';
        }
      } else if (winningPrice <= 300) {
        note = 'Low contestation; player acquired near base price.';
      } else {
        note = 'Sold for ₹$winningPrice. Auction score calibrated.';
      }

      final winner = session.userSquadNames.contains(player.name) ? session.userTeamName : session.aiTeamName;

      _latestAuctionInsights.add(LearnedAuctionInsight(
        playerName: player.name,
        oldAuctionScore: oldScore,
        newAuctionScore: player.auctionScore,
        oldRank: oldRank,
        newRank: player.adjustedRank,
        finalWinningPrice: winningPrice,
        winner: winner,
        learnedAdjustmentNote: note,
      ));
    }

    _recalculateRankings();

    // Update ranks in insights
    for (int i = 0; i < _latestAuctionInsights.length; i++) {
      final ins = _latestAuctionInsights[i];
      final p = getPlayerValuation(ins.playerName);
      _latestAuctionInsights[i] = LearnedAuctionInsight(
        playerName: ins.playerName,
        oldAuctionScore: ins.oldAuctionScore,
        newAuctionScore: ins.newAuctionScore,
        oldRank: ins.oldRank,
        newRank: p.adjustedRank,
        finalWinningPrice: ins.finalWinningPrice,
        winner: ins.winner,
        learnedAdjustmentNote: ins.learnedAdjustmentNote,
      );
    }

    notifyListeners();
    return _latestAuctionInsights;
  }
}

extension SessionSquadNames on RecordedAuctionSession {
  List<String> get userSquadNames {
    return playerAuctionPrices.keys.where((k) => opponentProfile.playerStudies[k]?.userWon == true).toList();
  }
}
