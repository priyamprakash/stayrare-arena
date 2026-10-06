import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/ai_model_valuation.dart';
import 'stayrare_ai_engine.dart';
import 'auction_voice_service.dart';
import 'auction_sfx_service.dart';
import 'stayrare_firebase_service.dart';
import 'stayrare_ai_learner.dart';

enum SoloBidLeader { none, user, ai }

enum SoloPlayerStatus { pool, onBlock, soldUser, soldAi, unsold }

enum SoloGavelStage {
  active,
  goingOnce,
  goingTwice,
  hammerDown,
}

enum SoloRtmPhase {
  none,
  userCanInvoke, // AI won, user can invoke RTM
  userRaisingPrice, // AI won, user invoked RTM, AI must raise price or user raises price
  aiEvaluatingMatch, // AI decides whether to match
  aiCanInvoke, // User won, AI evaluates invoking RTM
  userRaisingForAiRtm, // AI invoked RTM, user sets raised price ₹Y
  aiDecidingMatch, // AI decides to match user's raised price
}

class SoloBoughtPlayer {
  final PlayerValuation valuation;
  final int price;
  final bool viaRtm;
  final DateTime timestamp;

  SoloBoughtPlayer({
    required this.valuation,
    required this.price,
    this.viaRtm = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SoloBidStep {
  final SoloBidLeader bidder;
  final int amount;
  final String note;
  final String? trashTalk;
  final bool isJumpBid;
  final DateTime time;

  SoloBidStep({
    required this.bidder,
    required this.amount,
    required this.note,
    this.trashTalk,
    this.isJumpBid = false,
  }) : time = DateTime.now();
}

class SoloSoldEvent {
  final PlayerValuation player;
  final String winnerName;
  final int price;
  final bool viaRtm;
  final bool isUser;

  const SoloSoldEvent({
    required this.player,
    required this.winnerName,
    required this.price,
    required this.viaRtm,
    required this.isUser,
  });
}

class SoloAiAuctionSession extends ChangeNotifier {
  final StayrareAiEngine _aiEngine = StayrareAiEngine();

  // Sold Celebration Event for Hammer Animation Popup
  SoloSoldEvent? lastSoldEvent;

  void dismissSoldEvent() {
    lastSoldEvent = null;
    notifyListeners();
  }

  // Configuration
  String userTeamName = 'My Team';
  String aiTeamName = 'stayrare-model';
  int targetSquadSize = 10;
  int initialPurse = 12000;

  // Session State
  int userPurse = 12000;
  int aiPurse = 12000;
  int userRtmCards = 1;
  int aiRtmCards = 1;

  // Strategic Timeouts (1 per team per match)
  int userTimeouts = 1;
  int aiTimeouts = 1;
  bool isStrategicTimeoutActive = false;
  String? timeoutCaller;

  // Accelerated Round (Round 2 with discounted base prices)
  bool isAcceleratedRound = false;

  // End-game squad auto-fill popup state
  List<PlayerValuation> lastAiAutoClaimedPlayers = [];
  bool pendingAiAutoFillPopup = false;

  final List<PlayerValuation> playerPool = [];
  final Map<String, SoloPlayerStatus> playerStatusMap = {};
  final List<SoloBoughtPlayer> userSquad = [];
  final List<SoloBoughtPlayer> aiSquad = [];
  final List<SoloBidStep> currentRoundBids = [];
  final Map<String, List<SoloBidStep>> playerBidHistory = {};
  final List<Map<String, dynamic>> fullBiddingLog = [];

  // Firebase & Learning State
  final StayrareFirebaseService firebaseService = StayrareFirebaseService();
  final StayrareAiLearner learnerService = StayrareAiLearner();
  RecordedAuctionSession? latestRecordedSession;
  List<LearnedAuctionInsight> latestLearnedInsights = [];

  PlayerValuation? currentPlayerOnBlock;
  PlayerValuation? nominatedNextPlayer;
  int currentBidAmount = 0;
  SoloBidLeader currentLeader = SoloBidLeader.none;
  bool lastBidWasJump = false;

  // AI Thinking State
  bool isAiThinking = false;
  String? currentAiThought;
  AiBidDecision? lastAiDecision;

  // Mascot / Owner Sledging State
  String? ownerActiveSledge;
  bool isOwnerSledging = false;
  Timer? _sledgeDismissTimer;

  // Timer State
  Timer? _countdownTimer;
  int timerSeconds = 40;
  bool isTimerPaused = false;

  // RTM State
  SoloRtmPhase rtmPhase = SoloRtmPhase.none;
  int rtmBasePrice = 0;
  int rtmRaisedPrice = 0;

  // Completed flag
  bool isAuctionCompleted = false;

  SoloAiAuctionSession() {
    initSession();
  }

  void setTeamName(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      userTeamName = trimmed;
      notifyListeners();
    }
  }

  void initSession({
    String? userName,
    int? squadTarget,
    int? purseAmount,
  }) {
    _countdownTimer?.cancel();
    _aiEngine.resetSession();

    userTeamName = userName ?? userTeamName;
    aiTeamName = 'stayrare-model';
    targetSquadSize = squadTarget ?? 10;
    initialPurse = purseAmount ?? _aiEngine.brain.startingPurse;

    userPurse = initialPurse;
    aiPurse = initialPurse;
    userRtmCards = 1;
    aiRtmCards = 1;
    userTimeouts = 1;
    aiTimeouts = 1;
    isStrategicTimeoutActive = false;
    timeoutCaller = null;
    isAcceleratedRound = false;
    lastAiAutoClaimedPlayers.clear();
    pendingAiAutoFillPopup = false;

    userSquad.clear();
    aiSquad.clear();
    currentRoundBids.clear();
    playerBidHistory.clear();
    fullBiddingLog.clear();
    latestRecordedSession = null;
    latestLearnedInsights.clear();
    playerStatusMap.clear();

    currentPlayerOnBlock = null;
    currentBidAmount = 0;
    currentLeader = SoloBidLeader.none;
    lastBidWasJump = false;
    isAiThinking = false;
    currentAiThought = null;
    lastAiDecision = null;
    ownerActiveSledge = null;
    isOwnerSledging = false;
    _sledgeDismissTimer?.cancel();
    rtmPhase = SoloRtmPhase.none;
    isAuctionCompleted = false;

    // Load pool from official valuations
    playerPool.clear();
    playerPool.addAll(StayrarePlayerDatabase.officialValuations);
    for (final p in playerPool) {
      playerStatusMap[p.name] = SoloPlayerStatus.pool;
    }
    sessionId = 'auction_${DateTime.now().millisecondsSinceEpoch}_${userTeamName.replaceAll(' ', '_')}';
    _syncLiveStateToFirestore();

    notifyListeners();
  }

  String sessionId = 'auction_${DateTime.now().millisecondsSinceEpoch}_my_team';

  void _syncLiveStateToFirestore() {
    firebaseService.recordLiveAuctionProgress(
      sessionId: sessionId,
      userTeamName: userTeamName,
      aiTeamName: aiTeamName,
      userPurse: userPurse,
      aiPurse: aiPurse,
      userSquadCount: userSquad.length,
      aiSquadCount: aiSquad.length,
      currentPlayerName: currentPlayerOnBlock?.name,
      currentBid: currentBidAmount,
      currentLeader: currentLeader == SoloBidLeader.user ? 'user' : (currentLeader == SoloBidLeader.ai ? 'ai' : 'none'),
      recentBids: fullBiddingLog,
    );
  }

  int get unassignedPlayersCount =>
      playerStatusMap.values.where((s) => s == SoloPlayerStatus.pool).length;

  int get unsoldPlayersCount =>
      playerStatusMap.values.where((s) => s == SoloPlayerStatus.unsold).length;

  // --- Official IPL Graduated Bid Increment Ladder ---
  int getNextIncrement(int price) {
    if (price < 1000) return 100;
    if (price < 2500) return 250;
    return 500;
  }

  // --- Gavel Stages for Live Calls ---
  SoloGavelStage get gavelStage {
    if (currentLeader == SoloBidLeader.none || currentPlayerOnBlock == null) {
      return SoloGavelStage.active;
    }
    if (timerSeconds > 15) return SoloGavelStage.active;
    if (timerSeconds > 7) return SoloGavelStage.goingOnce;
    if (timerSeconds > 0) return SoloGavelStage.goingTwice;
    return SoloGavelStage.hammerDown;
  }

  String get gavelCallText {
    if (currentPlayerOnBlock == null || currentLeader == SoloBidLeader.none) {
      return 'Waiting for Opening Bid...';
    }
    final leaderName = currentLeader == SoloBidLeader.user ? userTeamName : aiTeamName;
    switch (gavelStage) {
      case SoloGavelStage.active:
        return 'Active Bidding at ₹$currentBidAmount ($leaderName)';
      case SoloGavelStage.goingOnce:
        return '🔨 Going ONCE at ₹$currentBidAmount to $leaderName...';
      case SoloGavelStage.goingTwice:
        return '🔨🔨 Going TWICE at ₹$currentBidAmount to $leaderName...';
      case SoloGavelStage.hammerDown:
        return '💥 SOLD to $leaderName for ₹$currentBidAmount!';
    }
  }

  // --- Squad Roles & Mandate Trackers ---
  Map<CricketRole, int> getRoleCounts(List<SoloBoughtPlayer> squad) {
    final map = <CricketRole, int>{
      CricketRole.bat: 0,
      CricketRole.bowl: 0,
      CricketRole.allRounder: 0,
    };
    for (final p in squad) {
      map[p.valuation.role] = (map[p.valuation.role] ?? 0) + 1;
    }
    return map;
  }

  Map<CricketRole, int> get userRoleCounts => getRoleCounts(userSquad);
  Map<CricketRole, int> get aiRoleCounts => getRoleCounts(aiSquad);

  // Mandates: Min 3 BAT, Min 2 BOWL, Min 2 AR (Min 5 Bowling Options Total)
  Map<CricketRole, int> get roleMandates => const {
        CricketRole.bat: 3,
        CricketRole.bowl: 2,
        CricketRole.allRounder: 2,
      };

  int getBowlingOptions(List<SoloBoughtPlayer> squad) =>
      squad.where((p) => p.valuation.role == CricketRole.bowl || p.valuation.role == CricketRole.allRounder).length;

  int getPureBatters(List<SoloBoughtPlayer> squad) =>
      squad.where((p) => p.valuation.role == CricketRole.bat).length;

  int getBasePriceForPlayer(PlayerValuation player) {
    if (isAcceleratedRound) {
      // 40% discount in accelerated round
      return player.isMarquee ? 300 : 50;
    }
    return player.isMarquee ? 500 : 100;
  }

  int get nextUserBidPrice {
    if (currentPlayerOnBlock == null) return 0;
    if (currentLeader == SoloBidLeader.none) {
      return getBasePriceForPlayer(currentPlayerOnBlock!);
    }
    return currentBidAmount + getNextIncrement(currentBidAmount);
  }

  int get userMaxBidAllowed {
    final slotsNeeded = max(0, targetSquadSize - userSquad.length);
    if (slotsNeeded <= 0) {
      return userPurse;
    }
    final reserve = 100 * (slotsNeeded - 1);
    final allowed = userPurse - reserve;
    return allowed > 0 ? allowed : 0;
  }

  int get aiMaxBidAllowed {
    final slotsNeeded = max(0, targetSquadSize - aiSquad.length);
    if (slotsNeeded <= 0) {
      return aiPurse;
    }
    final reserve = 100 * (slotsNeeded - 1);
    final allowed = aiPurse - reserve;
    return allowed > 0 ? allowed : 0;
  }

  bool get canUserBid {
    if (currentPlayerOnBlock == null || isAiThinking || rtmPhase != SoloRtmPhase.none || isStrategicTimeoutActive) {
      return false;
    }
    if (currentLeader == SoloBidLeader.user) return false;
    final nextBid = nextUserBidPrice;
    return userMaxBidAllowed >= nextBid && userPurse >= nextBid;
  }

  // --- Strategic Timeout Controls ---
  void takeUserTimeout() {
    if (userTimeouts <= 0 || isStrategicTimeoutActive || currentPlayerOnBlock == null) return;
    userTimeouts--;
    isStrategicTimeoutActive = true;
    timeoutCaller = userTeamName;
    isTimerPaused = true;
    _sfx.playTimeoutGong();
    _voice.announceTimeout(callerName: userTeamName);
    notifyListeners();
  }

  void resumeFromTimeout() {
    if (!isStrategicTimeoutActive) return;
    isStrategicTimeoutActive = false;
    timeoutCaller = null;
    isTimerPaused = false;
    _voice.announceTimeoutResumed();
    notifyListeners();
  }

  // --- Accelerated Round Controls ---
  void startAcceleratedRound() {
    isAcceleratedRound = true;
    // Put all unsold players back into pool for rapid discounted bidding!
    for (final entry in playerStatusMap.entries) {
      if (entry.value == SoloPlayerStatus.unsold) {
        playerStatusMap[entry.key] = SoloPlayerStatus.pool;
      }
    }
    notifyListeners();
  }

  // --- Auction Flow Controls ---

  final AuctionVoiceService _voice = AuctionVoiceService();
  AuctionVoiceService get voiceService => _voice;

  final AuctionSfxService _sfx = AuctionSfxService();
  AuctionSfxService get sfxService => _sfx;

  void triggerOwnerSledge(String category, {String playerName = '', int bidAmount = 0}) {
    final sledge = _aiEngine.getSledge(category, playerName: playerName, bidAmount: bidAmount);
    ownerActiveSledge = sledge;
    isOwnerSledging = true;
    _sledgeDismissTimer?.cancel();
    notifyListeners();

    _voice.sledgeUser(sledge);

    _sledgeDismissTimer = Timer(const Duration(milliseconds: 5500), () {
      isOwnerSledging = false;
      notifyListeners();
    });
  }

  void triggerInteractiveTapSledge() {
    final currentP = currentPlayerOnBlock?.name ?? '';
    final currentB = currentBidAmount;
    triggerOwnerSledge('interactive_sledge', playerName: currentP, bidAmount: currentB);
  }

  void placePlayerOnBlock(PlayerValuation player) {
    _countdownTimer?.cancel();
    currentPlayerOnBlock = player;
    playerStatusMap[player.name] = SoloPlayerStatus.onBlock;
    currentBidAmount = getBasePriceForPlayer(player);
    currentLeader = SoloBidLeader.none;
    lastBidWasJump = false;
    currentRoundBids.clear();
    lastAiDecision = null;
    rtmPhase = SoloRtmPhase.none;
    isStrategicTimeoutActive = false;
    timeoutCaller = null;

    _startTimer();
    _syncLiveStateToFirestore();
    notifyListeners();

    // If Marquee star steps onto the block, trigger crowd gasp & Stayrare Owner opening sledge!
    if (player.score >= 80 || player.isMarqueeDefault) {
      _sfx.playCrowdGasp();
      triggerOwnerSledge('marquee_arrival', playerName: player.name);
    } else {
      // Standard Auctioneer Voice Announcement
      _voice.announcePlayerOnBlock(
        playerName: player.name,
        role: player.roleDescription,
        basePrice: getBasePriceForPlayer(player),
        isAccelerated: isAcceleratedRound,
      );
    }

    // If user cannot bid (insufficient funds or full squad), trigger AI opening immediately!
    if (!canUserBid) {
      _triggerAiTurn();
    }
  }

  void requestPlayerForAuction(PlayerValuation player) {
    if (playerStatusMap[player.name] != SoloPlayerStatus.pool) return;

    if (currentPlayerOnBlock == null) {
      placePlayerOnBlock(player);
    } else {
      nominatedNextPlayer = player;
      _voice.announcePlayerNominated(playerName: player.name);
      notifyListeners();
    }
  }

  void cancelNomination() {
    nominatedNextPlayer = null;
    notifyListeners();
  }

  void drawNextRandomPlayer() {
    // 0. Check if user requested/nominated a specific player for this turn
    if (nominatedNextPlayer != null &&
        playerStatusMap[nominatedNextPlayer!.name] == SoloPlayerStatus.pool) {
      final selected = nominatedNextPlayer!;
      nominatedNextPlayer = null;
      placePlayerOnBlock(selected);
      return;
    }
    nominatedNextPlayer = null;

    final available = playerPool
        .where((p) => playerStatusMap[p.name] == SoloPlayerStatus.pool)
        .toList();

    if (available.isEmpty) {
      checkAuctionCompletion();
      return;
    }

    // If AI has learned data from past auctions, throw players according to their past records (better ranked comes first!)
    if (learnerService.hasLearnedData) {
      final rankedAvailable = available.map((p) => learnerService.getPlayerValuation(p.name)).toList();
      rankedAvailable.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));

      // Tier 1: Top 7 Ranked Players (Proven Marquee Stars)
      final topRanked = rankedAvailable.where((p) => p.adjustedRank <= 7).toList();
      if (topRanked.isNotEmpty) {
        final selected = topRanked[Random().nextInt(topRanked.length)];
        placePlayerOnBlock(selected);
        return;
      }

      // Tier 2: Mid Ranked Players (Ranks 8 to 15)
      final midRanked = rankedAvailable.where((p) => p.adjustedRank > 7 && p.adjustedRank <= 15).toList();
      if (midRanked.isNotEmpty) {
        final selected = midRanked[Random().nextInt(midRanked.length)];
        placePlayerOnBlock(selected);
        return;
      }

      // Tier 3: Value / Depth Tier (Ranks 16+)
      final selected = rankedAvailable[Random().nextInt(rankedAvailable.length)];
      placePlayerOnBlock(selected);
      return;
    }

    // In Auction #1 (Cold Start): Everyone is No. 1 and equal, so throw players randomly!
    final selected = available[Random().nextInt(available.length)];
    placePlayerOnBlock(selected);
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    timerSeconds = isAcceleratedRound ? 25 : 40;
    isTimerPaused = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isTimerPaused || isStrategicTimeoutActive) return;

      if (timerSeconds > 0) {
        timerSeconds--;

        // Voice & SFX Gavel Warnings
        if (currentPlayerOnBlock != null && currentLeader != SoloBidLeader.none) {
          final leaderName = currentLeader == SoloBidLeader.user ? userTeamName : aiTeamName;
          if (timerSeconds == 15) {
            _sfx.playGavelTap();
            _voice.announceGavelStage(
              stage: 'goingOnce',
              amount: currentBidAmount,
              bidderName: leaderName,
              playerName: currentPlayerOnBlock!.name,
            );
          } else if (timerSeconds == 7) {
            _sfx.playGavelTap();
            _voice.announceGavelStage(
              stage: 'goingTwice',
              amount: currentBidAmount,
              bidderName: leaderName,
              playerName: currentPlayerOnBlock!.name,
            );
          } else if (timerSeconds <= 5 && timerSeconds > 0) {
            _sfx.playCountdownTick(secondsRemaining: timerSeconds);
          }
        }

        notifyListeners();
      } else {
        timer.cancel();
        _handleTimerExpiration();
      }
    });
  }

  void _resetTimer() {
    timerSeconds = isAcceleratedRound ? 25 : 40;
    notifyListeners();
  }

  void _handleTimerExpiration() {
    if (currentPlayerOnBlock == null) return;

    if (currentLeader == SoloBidLeader.user) {
      _finalizeWinner(SoloBidLeader.user);
    } else if (currentLeader == SoloBidLeader.ai) {
      _finalizeWinner(SoloBidLeader.ai);
    } else {
      // Unsold
      final p = currentPlayerOnBlock!;
      playerStatusMap[p.name] = SoloPlayerStatus.unsold;
      _voice.announceUnsold(playerName: p.name);
      currentPlayerOnBlock = null;
      currentLeader = SoloBidLeader.none;
      checkAuctionCompletion();
      notifyListeners();
    }
  }

  // --- Bid Telemetry Helper ---
  void _recordBid({
    required SoloBidLeader bidder,
    required int amount,
    required String note,
    String? trashTalk,
    bool isJump = false,
  }) {
    final step = SoloBidStep(
      bidder: bidder,
      amount: amount,
      note: note,
      trashTalk: trashTalk,
      isJumpBid: isJump,
    );
    currentRoundBids.add(step);

    if (currentPlayerOnBlock != null) {
      final pName = currentPlayerOnBlock!.name;
      playerBidHistory.putIfAbsent(pName, () => []).add(step);

      fullBiddingLog.add({
        'order_index': fullBiddingLog.length + 1,
        'player_name': pName,
        'bidder': bidder == SoloBidLeader.user ? 'user' : (bidder == SoloBidLeader.ai ? 'ai' : 'none'),
        'amount': amount,
        'is_jump_bid': isJump,
        'note': note,
        'trash_talk': trashTalk,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _syncLiveStateToFirestore();
    }
  }

  // --- User Bidding ---

  void userPlaceBid({int? customAmount, bool isJump = false}) {
    if (!canUserBid || currentPlayerOnBlock == null) return;

    final bid = customAmount ?? nextUserBidPrice;
    if (bid > userPurse || bid > userMaxBidAllowed) return;

    currentBidAmount = bid;
    currentLeader = SoloBidLeader.user;
    lastBidWasJump = isJump;

    _recordBid(
      bidder: SoloBidLeader.user,
      amount: bid,
      note: isJump ? '⚡ User placed a POWER JUMP BID to ₹$bid' : 'User raised bid to ₹$bid',
      isJump: isJump,
    );

    _sfx.playPaddleClick();
    if (isJump || bid >= 2000) {
      _sfx.playCrowdGasp();
    }

    _voice.announceBid(
      bidderName: userTeamName,
      amount: bid,
      playerName: currentPlayerOnBlock!.name,
    );

    _resetTimer();
    notifyListeners();

    // Trigger AI response after short realistic thinking duration
    _triggerAiTurn();
  }

  void userPass() {
    if (currentPlayerOnBlock == null) return;
    if (currentLeader == SoloBidLeader.ai) {
      _finalizeWinner(SoloBidLeader.ai);
    } else if (currentLeader == SoloBidLeader.none) {
      // User passes on opening! Let AI evaluate opening bid or marking unsold
      _recordBid(
        bidder: SoloBidLeader.user,
        amount: 0,
        note: 'You passed on opening bid. Waiting for AI...',
      );
      notifyListeners();
      _triggerAiTurn();
    }
  }

  void userMarkUnsold() {
    if (currentPlayerOnBlock == null) return;
    final player = currentPlayerOnBlock!;
    _countdownTimer?.cancel();
    playerStatusMap[player.name] = SoloPlayerStatus.unsold;
    _voice.announceUnsold(playerName: player.name);
    _recordBid(
      bidder: SoloBidLeader.user,
      amount: 0,
      note: '${player.name} marked unsold',
    );
    currentPlayerOnBlock = null;
    currentLeader = SoloBidLeader.none;
    checkAuctionCompletion();
    notifyListeners();
  }

  // --- AI Decision & Bidding ---

  String _generateAiThought(PlayerValuation player, int currentBid, int step) {
    final roleCounts = aiRoleCounts;
    final isRoleNeeded = (roleCounts[player.role] ?? 0) < (roleMandates[player.role] ?? 1);
    final remainingSlots = targetSquadSize - aiSquad.length;
    final minReserve = (remainingSlots - 1).clamp(0, 20) * 100;
    final maxCanSpend = aiPurse - minReserve;

    if (step == 0) {
      if (lastBidWasJump && currentLeader == SoloBidLeader.user) {
        return '⚡ Analyzing aggressive jump bid on ${player.name}...';
      }
      if (currentBid >= maxCanSpend * 0.75) {
        return '✋ Price approaching ceiling (₹$currentBid)...';
      }
      if (isRoleNeeded) {
        if (player.role == CricketRole.bowl) {
          return '🎯 Targeting frontline wicket-taking bowler...';
        } else if (player.role == CricketRole.allRounder) {
          return '⚡ Assessing all-round balance & power-hitting...';
        } else {
          return '🏏 Prioritizing anchor batting depth...';
        }
      }
      return '🤔 Checking purse reserve & squad composition...';
    } else {
      if (currentBid >= maxCanSpend * 0.85) {
        return '✋ Value ceiling reached. Evaluating risk...';
      }
      if (isRoleNeeded) {
        return '🎯 Locking in target counter-bid valuation...';
      }
      return '📈 Simulating end-game purse constraints...';
    }
  }

  void _triggerAiTurn() {
    if (currentPlayerOnBlock == null || isAiThinking) return;

    isAiThinking = true;
    currentAiThought = _generateAiThought(currentPlayerOnBlock!, currentBidAmount, 0);
    notifyListeners();

    // Realistic human-like pacing: 3.0s - 4.0s thinking delay
    // Allows live announcer voice to cleanly finish speaking before AI counter-bids
    final delayMs = 3000 + Random().nextInt(1000); // 3.0s - 4.0s

    // Cycle thought halfway through for pulsing live thinking feel
    Timer(Duration(milliseconds: delayMs ~/ 2), () {
      if (isAiThinking && currentPlayerOnBlock != null) {
        currentAiThought = _generateAiThought(currentPlayerOnBlock!, currentBidAmount, 1);
        notifyListeners();
      }
    });

    Timer(Duration(milliseconds: delayMs), () {
      if (currentPlayerOnBlock == null) {
        isAiThinking = false;
        currentAiThought = null;
        notifyListeners();
        return;
      }

      final input = AiDecisionInput(
        player: currentPlayerOnBlock!.name,
        currentBid: currentBidAmount,
        currentBidLeader: currentLeader == SoloBidLeader.user
            ? 'user'
            : (currentLeader == SoloBidLeader.ai ? 'you' : 'none'),
        nextIncrement: getNextIncrement(currentBidAmount),
        yourPurseRemaining: aiPurse,
        yourSquadCount: aiSquad.length,
        userPurseRemaining: userPurse,
        userSquadCount: userSquad.length,
        playersRemainingInPool: unassignedPlayersCount,
        playersRemainingList: playerPool
            .where((p) => playerStatusMap[p.name] == SoloPlayerStatus.pool)
            .toList(),
        targetSquadSize: targetSquadSize,
        isAcceleratedRound: isAcceleratedRound,
        isJumpBidByOpponent: lastBidWasJump && currentLeader == SoloBidLeader.user,
        yourRoleCounts: aiRoleCounts,
        yourSquadNames: aiSquad.map((p) => p.valuation.name).toList(),
        userSquadNames: userSquad.map((p) => p.valuation.name).toList(),
      );

      final decision = _aiEngine.decide(input);
      lastAiDecision = decision;
      isAiThinking = false;
      currentAiThought = null;

      if (decision.isBid && decision.amount != null) {
        final newBid = decision.amount!;
        currentBidAmount = newBid;
        currentLeader = SoloBidLeader.ai;

        _recordBid(
          bidder: SoloBidLeader.ai,
          amount: newBid,
          note: decision.confidenceNote,
          trashTalk: decision.trashTalk,
        );

        _sfx.playPaddleClick();
        if (newBid >= 2000 || (newBid - currentBidAmount) >= 500) {
          _sfx.playCrowdGasp();
        }

        if (decision.trashTalk != null && decision.trashTalk!.isNotEmpty) {
          _voice.announceAiBidWithTrashTalk(
            bidderName: aiTeamName,
            amount: newBid,
            playerName: currentPlayerOnBlock!.name,
            trashTalk: decision.trashTalk!,
          );
        } else {
          _voice.announceBid(
            bidderName: aiTeamName,
            amount: newBid,
            playerName: currentPlayerOnBlock!.name,
          );
        }

        _resetTimer();
        notifyListeners();

        // If user cannot bid (e.g. user squad full or purse insufficient), award immediately to AI!
        if (!canUserBid) {
          _countdownTimer?.cancel();
          Future.delayed(const Duration(milliseconds: 700), () {
            if (currentPlayerOnBlock != null && currentLeader == SoloBidLeader.ai) {
              _finalizeWinner(SoloBidLeader.ai);
            }
          });
        }
      } else {
        // AI Passes / Lets player go!
        _countdownTimer?.cancel(); // Cancel timer immediately

        _recordBid(
          bidder: SoloBidLeader.ai,
          amount: currentBidAmount,
          note: decision.confidenceNote,
          trashTalk: decision.trashTalk,
        );

        if (decision.trashTalk != null && decision.trashTalk!.isNotEmpty) {
          _voice.announceAiPassWithBanter(
            aiTeamName: aiTeamName,
            playerName: currentPlayerOnBlock!.name,
            banter: decision.trashTalk!,
          );
        }

        notifyListeners();

        // If user is leading, give player to user quickly without waiting for timer!
        if (currentLeader == SoloBidLeader.user && currentPlayerOnBlock != null) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (currentPlayerOnBlock != null && currentLeader == SoloBidLeader.user) {
              _finalizeWinner(SoloBidLeader.user);
            }
          });
        } else if (currentLeader == SoloBidLeader.none && currentPlayerOnBlock != null) {
          // Both User and AI passed on opening -> mark player UNSOLD!
          Future.delayed(const Duration(milliseconds: 700), () {
            if (currentPlayerOnBlock != null && currentLeader == SoloBidLeader.none) {
              final p = currentPlayerOnBlock!;
              playerStatusMap[p.name] = SoloPlayerStatus.unsold;
              _voice.announceUnsold(playerName: p.name);
              currentPlayerOnBlock = null;
              currentLeader = SoloBidLeader.none;
              checkAuctionCompletion();
              notifyListeners();
            }
          });
        }
      }

      notifyListeners();
    });
  }

  // --- Finalizing Winner & RTM Logic ---

  void _finalizeWinner(SoloBidLeader leader) {
    _countdownTimer?.cancel();
    final player = currentPlayerOnBlock!;

    if (leader == SoloBidLeader.user) {
      // User won the bidding round.
      // Check if AI has RTM and wants to invoke it!
      if (aiRtmCards > 0 &&
          _aiEngine.shouldAiInvokeRtm(
            playerName: player.name,
            winningPrice: currentBidAmount,
            aiPurseRemaining: aiPurse,
            aiSquadCount: aiSquad.length,
            targetSquadSize: targetSquadSize,
          )) {
        // AI triggers RTM!
        _sfx.playRtmAlert();
        rtmPhase = SoloRtmPhase.userRaisingForAiRtm;
        rtmBasePrice = currentBidAmount;
        rtmRaisedPrice = currentBidAmount + getNextIncrement(currentBidAmount);
        _voice.announceRtmInvoked(
          rtmTeam: aiTeamName,
          playerName: player.name,
          highestBidder: userTeamName,
        );
        notifyListeners();
        return;
      }

      // Sell to user directly
      _completeSaleToUser(player, currentBidAmount, viaRtm: false);
    } else if (leader == SoloBidLeader.ai) {
      // AI won the bidding round.
      // Check if User has RTM card and can match
      if (userRtmCards > 0 && userMaxBidAllowed >= currentBidAmount) {
        _sfx.playRtmAlert();
        rtmPhase = SoloRtmPhase.userCanInvoke;
        rtmBasePrice = currentBidAmount;
        rtmRaisedPrice = currentBidAmount;
        _voice.announceRtmPrompt(teamName: userTeamName, playerName: player.name);
        notifyListeners();
        return;
      }

      // Sell to AI directly
      _completeSaleToAi(player, currentBidAmount, viaRtm: false);
    }
  }

  // --- User RTM Handler ---

  void userInvokeRtm() {
    if (rtmPhase != SoloRtmPhase.userCanInvoke || currentPlayerOnBlock == null) return;
    _sfx.playRtmAlert();
    userRtmCards--; // RTM card exhausted upon invocation!
    final valuation = currentPlayerOnBlock!;

    // AI gets one chance to strategically raise the price up to its valuation ceiling!
    final strategicRaise = _aiEngine.calculateAiRtmRaisePrice(
      playerName: valuation.name,
      currentBasePrice: rtmBasePrice,
      aiPurseRemaining: aiPurse,
      aiSquadCount: aiSquad.length,
      targetSquadSize: targetSquadSize,
    );

    if (strategicRaise > rtmBasePrice && aiMaxBidAllowed >= strategicRaise) {
      rtmRaisedPrice = strategicRaise;
      _voice.announceRtmPriceRaised(
        highestBidder: aiTeamName,
        newPrice: strategicRaise,
        rtmTeam: userTeamName,
        playerName: valuation.name,
      );
    } else {
      rtmRaisedPrice = rtmBasePrice;
      _voice.announceRtmPriceKept(
        highestBidder: aiTeamName,
        price: rtmBasePrice,
        rtmTeam: userTeamName,
        playerName: valuation.name,
      );
    }

    rtmPhase = SoloRtmPhase.userRaisingPrice;
    notifyListeners();
  }

  void userDeclineRtmInitial() {
    if (rtmPhase != SoloRtmPhase.userCanInvoke || currentPlayerOnBlock == null) return;
    _voice.announceRtmDeclined(
      rtmTeam: userTeamName,
      winnerName: aiTeamName,
      playerName: currentPlayerOnBlock!.name,
      price: rtmBasePrice,
    );
    _completeSaleToAi(currentPlayerOnBlock!, rtmBasePrice, viaRtm: false);
  }

  void userConfirmMatchRtm() {
    if (currentPlayerOnBlock == null) return;
    if (userPurse < rtmRaisedPrice || userMaxBidAllowed < rtmRaisedPrice) return;
    _voice.announceRtmMatched(
      rtmTeam: userTeamName,
      playerName: currentPlayerOnBlock!.name,
      price: rtmRaisedPrice,
    );
    _completeSaleToUser(currentPlayerOnBlock!, rtmRaisedPrice, viaRtm: true);
  }

  void userDeclineMatchRtm() {
    if (currentPlayerOnBlock == null) return;
    _voice.announceRtmDeclined(
      rtmTeam: userTeamName,
      winnerName: aiTeamName,
      playerName: currentPlayerOnBlock!.name,
      price: rtmRaisedPrice,
    );
    _completeSaleToAi(currentPlayerOnBlock!, rtmRaisedPrice, viaRtm: false);
  }

  // --- AI RTM Handler ---

  void userSubmitRaisedPriceForAiRtm(int newPrice) {
    if (rtmPhase != SoloRtmPhase.userRaisingForAiRtm || currentPlayerOnBlock == null) return;
    rtmRaisedPrice = newPrice;
    aiRtmCards--; // AI RTM card exhausted

    _voice.announceRtmPriceRaised(
      highestBidder: userTeamName,
      newPrice: newPrice,
      rtmTeam: aiTeamName,
      playerName: currentPlayerOnBlock!.name,
    );

    isAiThinking = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1400), () {
      isAiThinking = false;
      final player = currentPlayerOnBlock!;
      final doesAiMatch = _aiEngine.shouldAiMatchRtmPrice(
        playerName: player.name,
        askedPrice: rtmRaisedPrice,
        aiPurseRemaining: aiPurse,
        aiSquadCount: aiSquad.length,
        targetSquadSize: targetSquadSize,
      );

      if (doesAiMatch) {
        lastAiDecision = AiBidDecision(
          action: 'bid',
          amount: rtmRaisedPrice,
          strategyNote: 'RTM Exercised & Matched at ₹$rtmRaisedPrice',
          trashTalk: "RTM activated! ${player.name} is coming with me.",
        );
        _voice.announceRtmMatched(
          rtmTeam: aiTeamName,
          playerName: player.name,
          price: rtmRaisedPrice,
        );
        _completeSaleToAi(player, rtmRaisedPrice, viaRtm: true);
      } else {
        lastAiDecision = AiBidDecision(
          action: 'pass',
          amount: null,
          strategyNote: 'Declined RTM match at raised price ₹$rtmRaisedPrice',
          trashTalk: "That raised price is too steep. You can have him!",
        );
        _voice.announceRtmDeclined(
          rtmTeam: aiTeamName,
          winnerName: userTeamName,
          playerName: player.name,
          price: rtmRaisedPrice,
        );
        _completeSaleToUser(player, rtmRaisedPrice, viaRtm: false);
      }
    });
  }

  void _completeSaleToUser(PlayerValuation player, int price, {required bool viaRtm}) {
    userPurse -= price;
    userSquad.add(SoloBoughtPlayer(valuation: player, price: price, viaRtm: viaRtm));
    playerStatusMap[player.name] = SoloPlayerStatus.soldUser;
    _sfx.playHammerDown();
    Future.delayed(const Duration(milliseconds: 350), () => _sfx.playSoldCheer());
    _voice.announceSold(playerName: player.name, amount: price, winnerName: userTeamName);
    currentPlayerOnBlock = null;
    currentLeader = SoloBidLeader.none;
    rtmPhase = SoloRtmPhase.none;

    lastSoldEvent = SoloSoldEvent(
      player: player,
      winnerName: userTeamName,
      price: price,
      viaRtm: viaRtm,
      isUser: true,
    );

    checkAuctionCompletion();
    _syncLiveStateToFirestore();
    notifyListeners();
  }

  void _completeSaleToAi(PlayerValuation player, int price, {required bool viaRtm}) {
    aiPurse -= price;
    aiSquad.add(SoloBoughtPlayer(valuation: player, price: price, viaRtm: viaRtm));
    playerStatusMap[player.name] = SoloPlayerStatus.soldAi;
    _sfx.playHammerDown();
    Future.delayed(const Duration(milliseconds: 350), () => _sfx.playSoldCheer());
    _voice.announceSold(playerName: player.name, amount: price, winnerName: aiTeamName);
    currentPlayerOnBlock = null;
    currentLeader = SoloBidLeader.none;
    rtmPhase = SoloRtmPhase.none;

    lastSoldEvent = SoloSoldEvent(
      player: player,
      winnerName: aiTeamName,
      price: price,
      viaRtm: viaRtm,
      isUser: false,
    );

    checkAuctionCompletion();
    _syncLiveStateToFirestore();
    notifyListeners();
  }

  void checkAuctionCompletion() {
    final userFull = userSquad.length >= targetSquadSize;
    final aiFull = aiSquad.length >= targetSquadSize;
    final poolEmpty = unassignedPlayersCount == 0;

    if (userFull && !aiFull && !poolEmpty) {
      // User squad full! AI automatically selects remaining best players from pool at base price
      _handleAiAutoFillRemaining();
      return;
    }

    if ((userFull && aiFull) || poolEmpty) {
      // Mark any remaining pool players as unsold so exactly 2 players remain unsold
      for (final p in playerPool) {
        if (playerStatusMap[p.name] == SoloPlayerStatus.pool) {
          playerStatusMap[p.name] = SoloPlayerStatus.unsold;
        }
      }
      if (!isAuctionCompleted) {
        isAuctionCompleted = true;
        _triggerFirebaseAndLearning();
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (isAuctionCompleted) {
            _voice.speak(postAuctionAiOpinion, tone: aiBelievesItWon ? AuctionTone.hype : AuctionTone.trashTalk);
          }
        });
      }
    }
  }

  void _triggerFirebaseAndLearning() async {
    try {
      final session = await firebaseService.recordAuctionProcess(
        userTeamName: userTeamName,
        aiTeamName: aiTeamName,
        targetSquadSize: targetSquadSize,
        initialPurse: initialPurse,
        userPurseRemaining: userPurse,
        aiPurseRemaining: aiPurse,
        userSquad: userSquad,
        aiSquad: aiSquad,
        fullBiddingLog: fullBiddingLog,
        playerBidHistory: playerBidHistory,
      );
      latestRecordedSession = session;
      latestLearnedInsights = learnerService.learnFromCompletedAuction(session);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Firebase/Learner processing: $e');
      }
    }
  }

  void _handleAiAutoFillRemaining() {
    final aiSlotsNeeded = targetSquadSize - aiSquad.length;
    if (aiSlotsNeeded <= 0) {
      if (!isAuctionCompleted) {
        isAuctionCompleted = true;
        _triggerFirebaseAndLearning();
      }
      notifyListeners();
      return;
    }

    final available = playerPool
        .where((p) => playerStatusMap[p.name] == SoloPlayerStatus.pool)
        .toList();

    // Pick highest rated players remaining
    available.sort((a, b) => b.score.compareTo(a.score));
    final picks = available.take(aiSlotsNeeded).toList();
    lastAiAutoClaimedPlayers = List.from(picks);

    for (final p in picks) {
      final price = getBasePriceForPlayer(p);
      aiPurse -= price;
      aiSquad.add(SoloBoughtPlayer(valuation: p, price: price, viaRtm: false));
      playerStatusMap[p.name] = SoloPlayerStatus.soldAi;
    }

    // Mark remaining unsold players as unsold
    for (final p in playerPool) {
      if (playerStatusMap[p.name] == SoloPlayerStatus.pool) {
        playerStatusMap[p.name] = SoloPlayerStatus.unsold;
      }
    }

    pendingAiAutoFillPopup = true;
    final names = picks.map((p) => p.name).join(', ');
    _voice.speak("Hello $userTeamName Owner! We have remaining players in the pool, and I choose $names at base price to fill my squad!");

    if (!isAuctionCompleted) {
      isAuctionCompleted = true;
      _triggerFirebaseAndLearning();
    }
    notifyListeners();
  }

  void dismissAiAutoFillPopup() {
    pendingAiAutoFillPopup = false;
    notifyListeners();
  }

  void userDraftRemainingPlayerAtBase(PlayerValuation player) {
    if (userSquad.length >= targetSquadSize) return;
    if (playerStatusMap[player.name] != SoloPlayerStatus.pool) return;

    final price = getBasePriceForPlayer(player);
    if (userPurse < price) return;

    userPurse -= price;
    userSquad.add(SoloBoughtPlayer(valuation: player, price: price, viaRtm: false));
    playerStatusMap[player.name] = SoloPlayerStatus.soldUser;
    _voice.announceSold(playerName: player.name, amount: price, winnerName: userTeamName);

    if (userSquad.length >= targetSquadSize || unassignedPlayersCount == 0) {
      for (final p in playerPool) {
        if (playerStatusMap[p.name] == SoloPlayerStatus.pool) {
          playerStatusMap[p.name] = SoloPlayerStatus.unsold;
        }
      }
      isAuctionCompleted = true;
    }

    notifyListeners();
  }

  // --- Metrics & Comparison ---

  int get userTotalSquadScore {
    int total = 0;
    for (final p in userSquad) {
      total += p.valuation.score;
    }
    return total;
  }

  int get aiTotalSquadScore {
    int total = 0;
    for (final p in aiSquad) {
      total += p.valuation.score;
    }
    return total;
  }

  double get userAveragePlayerPrice =>
      userSquad.isEmpty ? 0 : (initialPurse - userPurse) / userSquad.length;

  double get aiAveragePlayerPrice =>
      aiSquad.isEmpty ? 0 : (initialPurse - aiPurse) / aiSquad.length;

  bool get aiBelievesItWon => aiTotalSquadScore >= userTotalSquadScore;

  /// Subjective post-auction perspective from stayrare-model
  /// Never reveals raw points or score totals to the user!
  String get postAuctionAiOpinion {
    if (aiBelievesItWon) {
      return "I feel pretty confident that I've won this auction battle! My squad has the exact balance, tactical depth, and bowling power I planned for. Good luck facing this eleven on the field!";
    } else {
      return "You played this auction really well! Your team looks exceptionally strong on paper and you made some great picks. But matches are decided on the 22 yards — we will win on the ground!";
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
