import 'dart:math';
import '../models/ai_model_valuation.dart';
import 'ai_brain_loader.dart';

class AiDecisionInput {
  final String player;
  final int currentBid;
  final String currentBidLeader; // 'user' | 'you' | 'none'
  final int nextIncrement;
  final int yourPurseRemaining;
  final int yourSquadCount;
  final int userPurseRemaining;
  final int userSquadCount;
  final int playersRemainingInPool;
  final List<PlayerValuation> playersRemainingList;
  final int targetSquadSize;
  final bool isAcceleratedRound;
  final bool isJumpBidByOpponent;
  final Map<CricketRole, int> yourRoleCounts;
  final List<String> yourSquadNames;
  final List<String> userSquadNames;

  const AiDecisionInput({
    required this.player,
    required this.currentBid,
    required this.currentBidLeader,
    required this.nextIncrement,
    required this.yourPurseRemaining,
    required this.yourSquadCount,
    required this.userPurseRemaining,
    required this.userSquadCount,
    required this.playersRemainingInPool,
    this.playersRemainingList = const [],
    this.targetSquadSize = 10,
    this.isAcceleratedRound = false,
    this.isJumpBidByOpponent = false,
    this.yourRoleCounts = const {},
    this.yourSquadNames = const [],
    this.userSquadNames = const [],
  });

  Map<String, dynamic> toJson() => {
        'player': player,
        'current_bid': currentBid,
        'current_bid_leader': currentBidLeader,
        'next_increment': nextIncrement,
        'your_purse_remaining': yourPurseRemaining,
        'your_squad_count': yourSquadCount,
        'user_purse_remaining': userPurseRemaining,
        'user_squad_count': userSquadCount,
        'players_remaining_in_pool': playersRemainingInPool,
        'is_accelerated': isAcceleratedRound,
      };
}

class StayrareAiEngine {
  final Random _rnd = Random();
  final AiBrainService _brainService = AiBrainService();

  // Track session state
  int _stretchedPicksCount = 0;
  int _evaluationsCount = 0;
  final Map<String, double> _playerJitterMap = {};
  final Map<String, int> _playerAiBumpsCount = {};
  final Set<String> _denialBidPlayers = {};

  void resetSession() {
    _stretchedPicksCount = 0;
    _evaluationsCount = 0;
    _playerJitterMap.clear();
    _playerAiBumpsCount.clear();
    _denialBidPlayers.clear();
  }

  AiBrainProfile get brain => _brainService.activeBrain;

  /// Evaluates whether the AI Rival Owner raises the bid or passes based on 8 Strategic Principles
  AiBidDecision decide(AiDecisionInput input) {
    _evaluationsCount++;
    final valuation = StayrarePlayerDatabase.getValuationFor(input.player);
    final score = valuation.score;
    final isOpening = input.currentBidLeader == 'none' || input.currentBid == 0;
    final basePrice = input.isAcceleratedRound
        ? (valuation.isMarqueeDefault ? 300 : 50)
        : (valuation.isMarqueeDefault ? 500 : 100);

    // Principle 8: Don't telegraph max - bid in realistic round-by-round increments
    final proposedBid = isOpening ? max(basePrice, input.currentBid) : input.currentBid + input.nextIncrement;

    // Remaining slots calculation (Full 10-player target per squad)
    final remainingSlotsToFill = max(0, input.targetSquadSize - input.yourSquadCount);

    // If squad already full, pass
    if (remainingSlotsToFill == 0) {
      return AiBidDecision(
        action: 'pass',
        amount: null,
        strategyNote: 'Squad already full (${input.yourSquadCount}/${input.targetSquadSize} slots filled)',
        trashTalk: "My squad is locked and loaded. You can have this one.",
      );
    }

    // Check: Absolute purse check
    if (proposedBid > input.yourPurseRemaining) {
      return AiBidDecision(
        action: 'pass',
        amount: null,
        strategyNote: 'Insufficient purse (need ₹$proposedBid, have ₹${input.yourPurseRemaining})',
        trashTalk: "Too rich for my blood right now. Take him.",
      );
    }

    // Principle 5: Protect squad-fill math at all times
    // your_purse_remaining - bid_amount >= (remaining_slots_after_this - 1) * reserve_floor
    if (remainingSlotsToFill > 1) {
      final purseAfterBid = input.yourPurseRemaining - proposedBid;
      final requiredReserve = (remainingSlotsToFill - 1) * brain.squadReserveFloor;
      if (purseAfterBid < requiredReserve) {
        return AiBidDecision(
          action: 'pass',
          amount: null,
          strategyNote: 'Protecting squad-fill math: ₹$purseAfterBid remaining < ₹$requiredReserve reserve for ${remainingSlotsToFill - 1} open slots',
          trashTalk: "I need to keep my reserve intact for the rest of the squad. All yours!",
        );
      }
    }

    // Rule: Shaurya & Dev Mutual Exclusion (No team wants both low-tier reserve picks)
    final cleanPlayerName = valuation.name.trim().toLowerCase();
    if (cleanPlayerName == 'dev' && input.yourSquadNames.any((n) => n.trim().toLowerCase() == 'shaurya')) {
      return AiBidDecision(
        action: 'pass',
        amount: null,
        strategyNote: 'Mutual exclusion: Already have Shaurya, passing on Dev to prevent low-tier surplus',
        trashTalk: "Nice try! I already have my reserve depth. Dev is all yours.",
      );
    }
    if (cleanPlayerName == 'shaurya' && input.yourSquadNames.any((n) => n.trim().toLowerCase() == 'dev')) {
      return AiBidDecision(
        action: 'pass',
        amount: null,
        strategyNote: 'Mutual exclusion: Already have Dev, passing on Shaurya to prevent low-tier surplus',
        trashTalk: "Nice try! I already have Dev. Shaurya is all yours.",
      );
    }

    // Squad Role Constraints: Max 5 Pure Batsmen & Min 5 Bowling Options (Bowl + All-Rounder)
    final currentBatCount = input.yourRoleCounts[CricketRole.bat] ?? 0;
    final currentBowlCount = input.yourRoleCounts[CricketRole.bowl] ?? 0;
    final currentArCount = input.yourRoleCounts[CricketRole.allRounder] ?? 0;
    final currentBowlingOptions = currentBowlCount + currentArCount;
    final bowlingShortfall = max(0, brain.minBowlingOptions - currentBowlingOptions);

    if (valuation.role == CricketRole.bat && currentBatCount >= brain.maxPureBatters) {
      return AiBidDecision(
        action: 'pass',
        amount: null,
        strategyNote: 'Pure batsmen cap reached ($currentBatCount/${brain.maxPureBatters}): Must draft bowling depth',
        trashTalk: "My batting lineup is fully loaded. Looking for bowling firepower now.",
      );
    }

    if (valuation.role == CricketRole.bat && remainingSlotsToFill <= bowlingShortfall) {
      return AiBidDecision(
        action: 'pass',
        amount: null,
        strategyNote: 'Bowling mandate: Reserving remaining $remainingSlotsToFill slots to reach min ${brain.minBowlingOptions} bowling options (currently $currentBowlingOptions)',
        trashTalk: "I need all-rounders and bowlers to finish my attack. Passing on this batter.",
      );
    }

    // Principle 2: Read opponent's purse (not just our own)
    final userSlotsNeeded = max(0, input.targetSquadSize - input.userSquadCount);
    final userReserve = userSlotsNeeded > 1 ? (userSlotsNeeded - 1) * 200 : 0;
    final userRealisticMax = max(0, input.userPurseRemaining - userReserve);

    // Principle 6: Endgame logic (last 3-4 players in pool)
    final isEndgame = input.playersRemainingInPool <= 4;
    final isBehindInSquad = input.yourSquadCount < input.userSquadCount;
    final urgentSquadFill = isEndgame && isBehindInSquad && remainingSlotsToFill > 0;

    // Top 7 Marquee Strategy: Aim to get at least 3 of Top 7 players (Priyam, Ashutosh, Sangam, Avinash, Saurabh, Sunny, Rahul)
    final isTop7 = StayrarePlayerDatabase.isTop7Player(valuation.name);
    final aiTop7Count = input.yourSquadNames.where((n) => StayrarePlayerDatabase.isTop7Player(n)).length;
    final top7RemainingInPool = input.playersRemainingList.where((p) => StayrarePlayerDatabase.isTop7Player(p.name)).length;
    final top7Needed = max(0, brain.top7TargetCount - aiTop7Count);
    final isTop7Urgency = isTop7 && aiTop7Count < brain.top7TargetCount;

    // Smart Opening Pass Evaluation: If user passed opening bid, AI does NOT auto-buy low-tier players
    if (isOpening) {
      final hasHigherTierRemaining = input.playersRemainingList.any((p) => p.score >= 50);
      final isLowTier = score < 45;
      if (isLowTier && hasHigherTierRemaining && !urgentSquadFill) {
        return AiBidDecision(
          action: 'pass',
          amount: null,
          strategyNote: 'Passing opening bid on ${valuation.name} ($score/100) to preserve purse for stars',
          trashTalk: _getRandomTrashTalk('opening_pass', valuation.name, proposedBid),
        );
      }
    }

    // Calculate base dynamic ceiling with mild randomness (±10%)
    if (!_playerJitterMap.containsKey(valuation.name)) {
      final jitter = (_rnd.nextDouble() * 0.20) - 0.10;
      _playerJitterMap[valuation.name] = jitter;
    }
    final jitter = _playerJitterMap[valuation.name]!;
    var dynamicCeiling = (valuation.baseCeiling * (1.0 + jitter)).round();

    // Human-like Purse Depth & Top 7 Scaling:
    // If player is in Top 7 and AI hasn't secured 3 of them yet, stretch ceiling aggressively according to available purse!
    final safeMaxForStar = max(0, input.yourPurseRemaining - (remainingSlotsToFill - 1) * brain.squadReserveFloor);
    if (isTop7Urgency) {
      // Calibrated hierarchy by score: Priyam (93) is highest at ₹3800, Ashutosh/Sangam (89) at ₹3500, Avinash (86) capped at ₹3000
      int targetTop7Base;
      if (score >= 90) {
        targetTop7Base = 3800; // Priyam (MVP)
      } else if (score >= 88) {
        targetTop7Base = 3500; // Ashutosh & Sangam
      } else if (score >= 85) {
        targetTop7Base = 3000; // Avinash
      } else if (score >= 80) {
        targetTop7Base = 2750; // Saurabh
      } else if (score >= 70) {
        targetTop7Base = 2500; // Sunny
      } else {
        targetTop7Base = 2400; // Rahul
      }

      if (input.yourPurseRemaining >= 6500) {
        dynamicCeiling = max(dynamicCeiling, min(safeMaxForStar, targetTop7Base));
      }

      // If scarce top-7 stars remain (e.g. need 2, only 2 left in pool), activate critical must-win bidding!
      if (top7RemainingInPool <= top7Needed) {
        final mustWinCeiling = (targetTop7Base * 1.05).round();
        dynamicCeiling = max(dynamicCeiling, min(safeMaxForStar, mustWinCeiling));
      }
    } else {
      // Practical Purse-Depth Stretch for regular players
      final aiPursePerSlot = input.yourPurseRemaining / max(1, remainingSlotsToFill);
      if (brain.allowDynamicStretchAboveCeiling && aiPursePerSlot >= 1400 && score >= 65) {
        final stretchRatio = score >= 85 ? (brain.dynamicPurseStretchRatio * 1.3) : brain.dynamicPurseStretchRatio;
        dynamicCeiling = (dynamicCeiling * (1.0 + stretchRatio)).round();
      }
    }

    // Principle 1: Value over replacement, not raw score
    // Check how many similar-tier players (within ±10 score) are still remaining in the pool
    final similarReplacements = input.playersRemainingList.where((p) {
      return p.name.toLowerCase() != valuation.name.toLowerCase() && (p.score - score).abs() <= 10;
    }).toList();

    var scarcityBoostApplied = false;
    if (similarReplacements.isEmpty && score >= 50 && !isEndgame) {
      // LAST strong player of its tier left -> raise effective ceiling by scarcityMultiplier
      dynamicCeiling = (dynamicCeiling * brain.scarcityMultiplier).round();
      scarcityBoostApplied = true;
    }

    // 85+ score top marquee pick stretch logic (max stretch picks per brain)
    var isStretching = false;
    if (score >= 85 && input.yourSquadCount < 3 && _stretchedPicksCount < brain.maxStretchPicks) {
      final stretchedCeiling = (dynamicCeiling * brain.marqueeStretchMultiplier).round();
      if (proposedBid > dynamicCeiling && proposedBid <= stretchedCeiling) {
        dynamicCeiling = stretchedCeiling;
        isStretching = true;
      }
    }

    final currentBumps = _playerAiBumpsCount[valuation.name] ?? 0;

    // Principle 2: Opponent pricing ceiling clamp - never pay more than necessary!
    final userWinThreshold = userRealisticMax + input.nextIncrement;
    if (input.currentBidLeader == 'user' && proposedBid > userWinThreshold && proposedBid > dynamicCeiling) {
      return AiBidDecision(
        action: 'pass',
        amount: null,
        strategyNote: 'Opponent max reached (User realistic max ₹$userRealisticMax): letting user overpay',
        trashTalk: _getRandomTrashTalk('over_ceiling', valuation.name, proposedBid),
      );
    }

    // Principle 3: Denial bidding on 80+ score players when opponent is purse-rich
    final userLooksPurseRich = input.userPurseRemaining >= brain.denialPurseThreshold && (input.userPurseRemaining > input.yourPurseRemaining + brain.denialPurseGap);
    final isAiPurseHealthy = input.yourPurseRemaining >= 5500;
    final isDenialOpportunity = brain.denialBiddingEnabled && score >= 80 && userLooksPurseRich && isAiPurseHealthy && currentBumps == 0 && input.currentBidLeader == 'user' && !_denialBidPlayers.contains(valuation.name);

    if (isDenialOpportunity && proposedBid <= (valuation.maxCeiling * 1.10)) {
      _denialBidPlayers.add(valuation.name);
      _playerAiBumpsCount[valuation.name] = currentBumps + 1;
      return AiBidDecision(
        action: 'bid',
        amount: proposedBid,
        strategyNote: 'Denial bid: draining user purse before subsequent targets',
        trashTalk: _getRandomTrashTalk('price_jack', valuation.name, proposedBid),
      );
    }

    // Principle 4: Bluff occasionally on mid-tier players (40-60 score)
    final isBluffCandidate = score >= 40 && score <= 60 && (_evaluationsCount % brain.bluffFrequency == 0) && currentBumps == 0 && input.currentBidLeader == 'user';
    if (isBluffCandidate && proposedBid <= (valuation.baseCeiling * brain.bluffCeilingFactor) && input.yourPurseRemaining >= 4000) {
      _playerAiBumpsCount[valuation.name] = currentBumps + 1;
      return AiBidDecision(
        action: 'bid',
        amount: proposedBid,
        strategyNote: 'Bluff raise: keeping opponent guessing on mid-tier value',
        trashTalk: _getRandomTrashTalk('normal_bid', valuation.name, proposedBid),
      );
    }

    // Opponent Power Jump Bid Reaction
    if (input.isJumpBidByOpponent && proposedBid > (dynamicCeiling * 0.92)) {
      return AiBidDecision(
        action: 'pass',
        amount: null,
        strategyNote: 'Opponent power jump exceeded tactical value ceiling',
        trashTalk: _getRandomTrashTalk('jump_bid_pass', valuation.name, proposedBid),
      );
    }

    // Principle 1 (Replacement count check): If $\ge 2$ similar replacements exist and bid is high, let go cheap (unless top-7 urgency!)
    if (similarReplacements.length >= 2 && score < 70 && !urgentSquadFill && !isTop7Urgency) {
      if (proposedBid > (dynamicCeiling * 0.85) && currentBumps >= 1 && input.currentBidLeader == 'user') {
        return AiBidDecision(
          action: 'pass',
          amount: null,
          strategyNote: 'Value over replacement: ${similarReplacements.length} similar-tier players remain in pool',
          trashTalk: _getRandomTrashTalk('cautious_pass', valuation.name, proposedBid),
        );
      }
    }

    // Sub-40 score players -> let go cheap unless urgent squad fill
    if (score < 40 && !urgentSquadFill) {
      if (!isEndgame && (proposedBid > 200 || currentBumps >= 1)) {
        return AiBidDecision(
          action: 'pass',
          amount: null,
          strategyNote: 'Sub-40 player ($score/100): letting go cheap to save purse',
          trashTalk: _getRandomTrashTalk('sub40_pass', valuation.name, proposedBid),
        );
      }
    }

    // Normal Ceiling Check
    if (proposedBid > dynamicCeiling && !urgentSquadFill) {
      return AiBidDecision(
        action: 'pass',
        amount: null,
        strategyNote: 'Exceeds effective ceiling ₹$dynamicCeiling for ${valuation.name} ($score/100)',
        trashTalk: _getRandomTrashTalk('over_ceiling', valuation.name, proposedBid),
      );
    }

    // All strategic checks passed: Place the bid!
    _playerAiBumpsCount[valuation.name] = currentBumps + 1;
    if (isStretching) {
      _stretchedPicksCount++;
    }

    String strategyNote;
    if (urgentSquadFill) {
      strategyNote = 'Endgame squad fill: securing roster depth ($input.yourSquadCount/${input.targetSquadSize})';
    } else if (isTop7Urgency) {
      strategyNote = 'Top 7 Marquee Priority ($aiTop7Count/${brain.top7TargetCount} stars acquired): Bidding aggressively up to ₹$dynamicCeiling';
    } else if (scarcityBoostApplied) {
      strategyNote = 'Scarcity premium (+18% ceiling): last available player in $score tier';
    } else if (isStretching) {
      strategyNote = 'Stretching ceiling up to 115% for elite marquee anchor';
    } else if (score >= 70) {
      strategyNote = 'Aggressive bid on high-impact star within ceiling ₹$dynamicCeiling';
    } else {
      strategyNote = 'Tactical value bid within ceiling ₹$dynamicCeiling';
    }

    return AiBidDecision(
      action: 'bid',
      amount: proposedBid,
      strategyNote: strategyNote,
      trashTalk: _getRandomTrashTalk(score >= 70 ? 'elite_bid' : 'normal_bid', valuation.name, proposedBid),
    );
  }

  /// Principle 7: RTM Timing - Save RTM for 75+ score players lost by narrow margin
  bool shouldAiInvokeRtm({
    required String playerName,
    required int winningPrice,
    required int aiPurseRemaining,
    required int aiSquadCount,
    required int targetSquadSize,
  }) {
    final valuation = StayrarePlayerDatabase.getValuationFor(playerName);
    final remainingSlots = max(0, targetSquadSize - aiSquadCount);

    if (remainingSlots <= 0) return false;
    if (winningPrice > aiPurseRemaining) return false;

    // Principle 5: Reserve check for RTM
    if (remainingSlots > 1) {
      final purseAfter = aiPurseRemaining - winningPrice;
      if (purseAfter < (remainingSlots - 1) * brain.squadReserveFloor) return false;
    }

    // Principle 7: Save RTM for players scoring rtmMinScore+ or Top 7 stars lost within max margin
    final isTop7 = StayrarePlayerDatabase.isTop7Player(playerName);
    if ((isTop7 || valuation.score >= brain.rtmMinScore) && winningPrice <= (valuation.maxCeiling * brain.rtmMaxMarginPercent)) {
      return true;
    }

    return false;
  }

  /// Principle 7: When user invokes RTM against AI's winning bid,
  /// AI has the right to set the final raised price up to its valuation ceiling & available purse!
  int calculateAiRtmRaisePrice({
    required String playerName,
    required int currentBasePrice,
    required int aiPurseRemaining,
    required int aiSquadCount,
    required int targetSquadSize,
  }) {
    final valuation = StayrarePlayerDatabase.getValuationFor(playerName);
    final remainingSlots = max(1, targetSquadSize - aiSquadCount);
    final reserveFloor = (remainingSlots - 1) * brain.squadReserveFloor;
    final maxCanSpend = max(0, aiPurseRemaining - reserveFloor);

    if (maxCanSpend <= currentBasePrice) {
      return currentBasePrice;
    }

    // AI raises aggressively towards its valuation ceiling for quality players:
    // Top 7 / Elite (score >= 80): 98% to 105% of maxCeiling
    // High-tier (score 70-79): 90% to 98% of maxCeiling
    // Solid (score 55-69): 80% to 90% of maxCeiling
    // Base: 65% of maxCeiling
    final isTop7 = StayrarePlayerDatabase.isTop7Player(playerName);
    double targetFraction;
    if (isTop7 || valuation.score >= 85) {
      targetFraction = 1.0;
    } else if (valuation.score >= 75) {
      targetFraction = 0.95;
    } else if (valuation.score >= 65) {
      targetFraction = 0.85;
    } else {
      targetFraction = 0.65;
    }

    int targetRaise = (valuation.maxCeiling * targetFraction).round();

    // Round targetRaise to clean auction increments (nearest 50 or 100)
    if (targetRaise >= 1000) {
      targetRaise = (targetRaise ~/ 100) * 100;
    } else {
      targetRaise = (targetRaise ~/ 50) * 50;
    }

    // Must be at least higher than currentBasePrice by at least 1 increment
    final minRaise = currentBasePrice < 1000
        ? currentBasePrice + 100
        : (currentBasePrice < 2500 ? currentBasePrice + 250 : currentBasePrice + 500);

    if (targetRaise < minRaise) {
      targetRaise = minRaise;
    }

    // Cannot exceed what AI can legally afford
    final finalPrice = min(targetRaise, maxCanSpend);
    return max(currentBasePrice, finalPrice);
  }

  /// Principle 7: AI decision on whether to match raised price in RTM Stage 2
  bool shouldAiMatchRtmPrice({
    required String playerName,
    required int askedPrice,
    required int aiPurseRemaining,
    required int aiSquadCount,
    required int targetSquadSize,
  }) {
    final valuation = StayrarePlayerDatabase.getValuationFor(playerName);
    final remainingSlots = max(0, targetSquadSize - aiSquadCount);

    if (remainingSlots <= 0) return false;
    if (askedPrice > aiPurseRemaining) return false;

    if (remainingSlots > 1) {
      final purseAfter = aiPurseRemaining - askedPrice;
      if (purseAfter < (remainingSlots - 1) * brain.squadReserveFloor) return false;
    }

    // AI will match up to rtmEliteMatchMargin of ceiling for 85+ score, or 100% for 75+
    final limit = valuation.score >= 85 ? (valuation.maxCeiling * brain.rtmEliteMatchMargin) : valuation.maxCeiling.toDouble();
    return askedPrice <= limit;
  }

  String getSledge(String category, {String playerName = '', int bidAmount = 0}) {
    return _getRandomTrashTalk(category, playerName, bidAmount);
  }

  String _getRandomTrashTalk(String category, String playerName, int bidAmount) {
    final brainLines = brain.trashTalkCorpus[category];
    final lines = (brainLines != null && brainLines.isNotEmpty)
        ? brainLines
        : (_trashTalkCorpus[category] ?? [
            "Let's see how much you really want $playerName!",
            "I'm in at ₹$bidAmount. Your move!",
          ]);
    return lines[_rnd.nextInt(lines.length)].replaceAll('{player}', playerName).replaceAll('{bid}', '₹$bidAmount');
  }

  static const Map<String, List<String>> _trashTalkCorpus = {
    'elite_bid': [
      "You'll have to break the bank if you want {player} on your team!",
      "{player} is a game changer. I'm taking this all the way.",
      "Raising the stakes to {bid}. Can you match my ambition?",
      "No way I'm letting you walk away with {player} that easily.",
      "{player} belongs on my championship roster!",
    ],
    'normal_bid': [
      "Putting in a clean {bid}. Ball is in your court.",
      "Just testing your budget. {bid} on the table.",
      "I like the value here. Raising to {bid}.",
      "Let's see if you're willing to pay more than {bid}.",
    ],
    'over_ceiling': [
      "You're overpaying for {player}, my friend. He's all yours!",
      "Enjoy him at that price! You just depleted your purse.",
      "I have my limits. Take him and enjoy the budget crunch.",
      "That's way above market value. I'll pass.",
      "I'm letting you win this battle so I can win the war.",
    ],
    'cautious_pass': [
      "I pushed you to your limit on {player}. My job here is done.",
      "I've made you pay extra. Passing now!",
      "Good buy, but I'm saving my heavy ammo for the next round.",
      "You wanted him more. Take him!",
    ],
    'sub40_pass': [
      "Not getting into a bidding war over this one. Yours!",
      "Save some cash for the big names! Passing.",
      "All yours. Good squad filler for you.",
    ],
    'price_jack': [
      "Just making sure you pay top rupee for {player}! Enjoy the tax 😉",
      "Had to inflate the market for you. {player} at {bid} is getting spicy!",
      "Testing your wallet depth on {player}! Let's see you top {bid}.",
    ],
    'jump_bid_pass': [
      "Big power jump bid! That's too rich for my models. He's yours!",
      "Aggressive jump! You really want {player} — I'll step aside.",
      "That bold jump worked. Enjoy {player} at {bid}!",
    ],
    'opening_pass': [
      "I'll pass on opening {player}. I'm saving my heavy purse for the real kings.",
      "Not opening the bidding here. Let's see if he even finds a buyer!",
      "Passing on opening {player}. Real champions wait for the marquee guns.",
    ],
    'rtm_taunt': [
      "Did you really think you were taking {player} home? RTM CARD INVOKED! 🃏🔥",
      "RTM ACTIVATED! What's mine stays mine. Match the price if you dare!",
    ],
    'purse_drain_roast': [
      "Your purse is running on fumes! One more bid and you'll be bankrupt 📉",
      "Look at that purse difference! I'm shopping in luxury, you're at the clearance aisle.",
    ],
  };
}

