import 'package:flutter_test/flutter_test.dart';
import 'package:stayrare/models/ai_model_valuation.dart';
import 'package:stayrare/services/stayrare_ai_engine.dart';
import 'package:stayrare/services/solo_ai_auction_session.dart';
import 'package:stayrare/services/ai_brain_loader.dart';
import 'package:stayrare/services/stayrare_firebase_service.dart';
import 'package:stayrare/services/stayrare_ai_learner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stayrare-model AI Valuation & Decision Engine Tests', () {
    late StayrareAiEngine engine;

    setUp(() {
      StayrareAiLearner().resetToDefaults();
      engine = StayrareAiEngine();
    });

    test('Valuations database initializes with 22 player profiles at equal mid baseline', () {
      final priyam = StayrarePlayerDatabase.getValuationFor('Priyam');
      expect(priyam.score, 50);
      expect(priyam.auctionScore, 50);
      expect(priyam.historicalAvgPrice, 1200);
      expect(priyam.role, CricketRole.allRounder);

      final ashutosh = StayrarePlayerDatabase.getValuationFor('Ashutosh');
      expect(ashutosh.score, 50);
      expect(ashutosh.role, CricketRole.allRounder);

      final avinash = StayrarePlayerDatabase.getValuationFor('Avinash');
      expect(avinash.score, 50);
      expect(avinash.role, CricketRole.allRounder);

      final dev = StayrarePlayerDatabase.getValuationFor('Dev');
      expect(dev.score, 50);
      expect(dev.role, CricketRole.bat);
    });

    test('AI bids aggressively above 1750 on Rahul when top 7 star is needed and purse is available', () {
      final decision = engine.decide(
        AiDecisionInput(
          player: 'Rahul',
          currentBid: 1800,
          currentBidLeader: 'user',
          nextIncrement: 250,
          yourPurseRemaining: 10000,
          yourSquadCount: 1,
          userPurseRemaining: 9000,
          userSquadCount: 1,
          playersRemainingInPool: 15,
          playersRemainingList: StayrarePlayerDatabase.officialValuations,
          yourSquadNames: [], // 0 top 7 stars yet -> target is 3!
        ),
      );

      expect(decision.action, 'bid');
      expect(decision.amount, 2050);
      expect(decision.strategyNote, contains('Top 7'));
    });

    test('AI enforces Shaurya and Dev mutual exclusion (never buys both)', () {
      // AI already has Shaurya -> passes on Dev
      final decisionDev = engine.decide(
        const AiDecisionInput(
          player: 'Dev',
          currentBid: 100,
          currentBidLeader: 'user',
          nextIncrement: 100,
          yourPurseRemaining: 8000,
          yourSquadCount: 3,
          userPurseRemaining: 8000,
          userSquadCount: 3,
          playersRemainingInPool: 10,
          yourSquadNames: ['Shaurya', 'Priyam', 'Rohan'],
        ),
      );
      expect(decisionDev.action, 'pass');
      expect(decisionDev.strategyNote, contains('Shaurya'));

      // AI already has Dev -> passes on Shaurya
      final decisionShaurya = engine.decide(
        const AiDecisionInput(
          player: 'Shaurya',
          currentBid: 100,
          currentBidLeader: 'user',
          nextIncrement: 100,
          yourPurseRemaining: 8000,
          yourSquadCount: 3,
          userPurseRemaining: 8000,
          userSquadCount: 3,
          playersRemainingInPool: 10,
          yourSquadNames: ['Dev', 'Priyam', 'Rohan'],
        ),
      );
      expect(decisionShaurya.action, 'pass');
      expect(decisionShaurya.strategyNote, contains('Dev'));
    });

    test('AI enforces max 5 pure batsmen cap and 5 bowling options mandate', () {
      // AI already has 5 pure batsmen -> passes on another pure batsman (e.g. Amit)
      final decisionMaxBat = engine.decide(
        const AiDecisionInput(
          player: 'Amit', // role: bat
          currentBid: 300,
          currentBidLeader: 'user',
          nextIncrement: 100,
          yourPurseRemaining: 5000,
          yourSquadCount: 5,
          userPurseRemaining: 5000,
          userSquadCount: 5,
          playersRemainingInPool: 8,
          yourRoleCounts: {
            CricketRole.bat: 5,
            CricketRole.bowl: 0,
            CricketRole.allRounder: 0,
          },
        ),
      );
      expect(decisionMaxBat.action, 'pass');
      expect(decisionMaxBat.strategyNote, contains('Pure batsmen cap reached'));
    });

    test('AI passes when bid exceeds ceiling for normal players', () {
      // Ritesh score 61, ceiling 1250
      final decision = engine.decide(
        AiDecisionInput(
          player: 'Ritesh',
          currentBid: 1600,
          currentBidLeader: 'user',
          nextIncrement: 250,
          yourPurseRemaining: 9000,
          yourSquadCount: 1,
          userPurseRemaining: 8000,
          userSquadCount: 1,
          playersRemainingInPool: 15,
          playersRemainingList: StayrarePlayerDatabase.officialValuations,
        ),
      );

      expect(decision.action, 'pass');
      expect(decision.amount, isNull);
    });

    test('AI enforces ₹200 reserve safety rule to avoid squad insolvency', () {
      // 5 slots remaining to fill, ₹500 purse left
      // (500 - 300) / (5 - 1) = 200 / 4 = 50 < 200 min
      final decision = engine.decide(
        const AiDecisionInput(
          player: 'Priyam',
          currentBid: 200,
          currentBidLeader: 'user',
          nextIncrement: 100,
          yourPurseRemaining: 500,
          yourSquadCount: 4, // 10 - 1 - 4 = 5 slots left
          userPurseRemaining: 4000,
          userSquadCount: 4,
          playersRemainingInPool: 10,
        ),
      );

      expect(decision.action, 'pass');
      expect(decision.confidenceNote, contains('reserve'));
    });

    test('SoloAiAuctionSession initializes with ₹12,000 purse and 22 players', () {
      final session = SoloAiAuctionSession();
      expect(session.userPurse, 12000);
      expect(session.aiPurse, 12000);
      expect(session.userRtmCards, 1);
      expect(session.aiRtmCards, 1);
      expect(session.playerPool.length, greaterThanOrEqualTo(20));

      session.placePlayerOnBlock(session.playerPool.first);
      expect(session.currentPlayerOnBlock, isNotNull);
      expect(session.canUserBid, isTrue);
    });

    test('Auction #1 draws randomly; subsequent auctions draw learned top-ranked stars first', () {
      final session = SoloAiAuctionSession();
      expect(session.learnerService.hasLearnedData, isFalse);

      // In cold start (Auction #1), players are drawn randomly from pool
      session.drawNextRandomPlayer();
      expect(session.currentPlayerOnBlock, isNotNull);

      // Now simulate learner acquiring auction data
      final mockSession = RecordedAuctionSession(
        id: 'auction_mock',
        timestamp: DateTime.now(),
        userTeamName: 'Danapur Dabangg',
        aiTeamName: 'stayrare-model',
        targetSquadSize: 10,
        initialPurse: 12000,
        userPurseRemaining: 100,
        aiPurseRemaining: 200,
        biddingProcess: [],
        opponentProfile: OpponentAuctionProfile(
          userTeamName: 'Danapur Dabangg',
          totalUserBidsPlaced: 10,
          totalUserSpent: 11900,
          userJumpBidsPlaced: 1,
          top7StarsAcquired: 4,
          biddingStyle: 'Star Hunter',
          playerStudies: {},
        ),
        playerAuctionPrices: {
          'Priyam': 3600,
          'Ashutosh': 3200,
          'Sangam': 3000,
          'Avinash': 2900,
          'Saurabh': 2800,
          'Sunny': 2500,
          'Rahul': 2200,
        },
      );
      session.learnerService.learnFromCompletedAuction(mockSession);
      expect(session.learnerService.hasLearnedData, isTrue);

      // Start new auction session after learning
      final session2 = SoloAiAuctionSession();
      // Draw first 7 players -> should be top ranked players
      for (int i = 0; i < 7; i++) {
        session2.drawNextRandomPlayer();
        final current = session2.currentPlayerOnBlock!;
        expect(current.compositeScore >= 60 || current.adjustedRank <= 7, isTrue,
            reason: 'Drawn player ${current.name} (rank ${current.adjustedRank}) should be a top star after learning');
        session2.userMarkUnsold();
      }
    });

    test('AI passes on opening bid for low-tier players when stars remain in pool', () {
      final lowTierValuation = PlayerValuation(
        name: 'Dev',
        role: CricketRole.bat,
        score: 30, // Low tier
        auctionScore: 30,
        adjustedRank: 20,
        minCeiling: 200,
        maxCeiling: 400,
      );

      final decision = engine.decide(
        AiDecisionInput(
          player: 'Dev',
          currentBid: 0,
          currentBidLeader: 'none',
          nextIncrement: 100,
          yourPurseRemaining: 12000,
          yourSquadCount: 0,
          userPurseRemaining: 12000,
          userSquadCount: 0,
          playersRemainingInPool: 20,
          playersRemainingList: [lowTierValuation, ...StayrarePlayerDatabase.officialValuations],
        ),
      );

      expect(decision.action, 'pass');
      expect(decision.strategyNote, contains('Passing opening bid'));
    });

    test('User placing bid sets user as leader and triggers AI evaluation turn', () {
      final session = SoloAiAuctionSession();
      final player = session.playerPool.firstWhere((p) => p.name == 'Dev');
      session.placePlayerOnBlock(player);

      session.userPlaceBid();
      expect(session.currentLeader, SoloBidLeader.user);
      expect(session.currentBidAmount, 100);
      expect(session.isAiThinking, isTrue);
    });

    test('User can mark player unsold directly and re-auction later', () {
      final session = SoloAiAuctionSession();
      final player = session.playerPool.firstWhere((p) => p.name == 'Dev');
      session.placePlayerOnBlock(player);

      session.userMarkUnsold();
      expect(session.currentPlayerOnBlock, isNull);
      expect(session.playerStatusMap['Dev'], SoloPlayerStatus.unsold);
      expect(session.unsoldPlayersCount, 1);

      // Re-auction
      session.placePlayerOnBlock(player);
      expect(session.currentPlayerOnBlock?.name, 'Dev');
      expect(session.playerStatusMap['Dev'], SoloPlayerStatus.onBlock);
    });

    test('IPL Graduated Bid Ladder scales with current price', () {
      final session = SoloAiAuctionSession();
      expect(session.getNextIncrement(300), 100);
      expect(session.getNextIncrement(900), 100);
      expect(session.getNextIncrement(1000), 250);
      expect(session.getNextIncrement(2400), 250);
      expect(session.getNextIncrement(2500), 500);
      expect(session.getNextIncrement(4500), 500);
    });

    test('Gavel stages transition from Active to Going Once, Going Twice, and Hammer Down', () {
      final session = SoloAiAuctionSession();
      final player = session.playerPool.firstWhere((p) => p.name == 'Priyam');
      session.placePlayerOnBlock(player);
      session.userPlaceBid();

      session.timerSeconds = 30;
      expect(session.gavelStage, SoloGavelStage.active);

      session.timerSeconds = 12;
      expect(session.gavelStage, SoloGavelStage.goingOnce);
      expect(session.gavelCallText, contains('Going ONCE'));

      session.timerSeconds = 5;
      expect(session.gavelStage, SoloGavelStage.goingTwice);
      expect(session.gavelCallText, contains('Going TWICE'));
    });

    test('Strategic Timeout freezes timer and resumes cleanly', () {
      final session = SoloAiAuctionSession();
      final player = session.playerPool.firstWhere((p) => p.name == 'Priyam');
      session.placePlayerOnBlock(player);

      expect(session.userTimeouts, 1);
      expect(session.isStrategicTimeoutActive, isFalse);

      session.takeUserTimeout();
      expect(session.userTimeouts, 0);
      expect(session.isStrategicTimeoutActive, isTrue);
      expect(session.isTimerPaused, isTrue);

      session.resumeFromTimeout();
      expect(session.isStrategicTimeoutActive, isFalse);
      expect(session.isTimerPaused, isFalse);
    });

    test('Accelerated Round slashes base prices by 40%', () {
      final session = SoloAiAuctionSession();
      final coldPlayer = session.playerPool.firstWhere((p) => p.name == 'Dev');

      // Cold start: default base price is 100
      expect(session.getBasePriceForPlayer(coldPlayer), 100);

      session.startAcceleratedRound();
      expect(session.isAcceleratedRound, isTrue);
      expect(session.getBasePriceForPlayer(coldPlayer), 50); // 50% discount on 100

      // For marquee/learned stars, 500 becomes 300
      final marqueePlayer = PlayerValuation(
        name: 'Priyam',
        score: 90,
        auctionScore: 90,
        minCeiling: 2800,
        maxCeiling: 3400,
        isMarqueeDefault: true,
      );
      expect(session.getBasePriceForPlayer(marqueePlayer), 300);
    });

    test('Squad Role Mandates track 3 roles (BAT, BOWL, AR) without WK', () {
      final session = SoloAiAuctionSession();
      expect(session.roleMandates[CricketRole.bat], 3);
      expect(session.roleMandates[CricketRole.bowl], 2);
      expect(session.roleMandates[CricketRole.allRounder], 2);

      final avinash = session.playerPool.firstWhere((p) => p.name == 'Avinash');
      expect(avinash.role, CricketRole.allRounder);
    });

    test('Principle 1 & JSON: Scarcity boost and strict JSON serialization', () {
      final starPlayer = PlayerValuation(
        name: 'Priyam',
        score: 93,
        auctionScore: 95,
        minCeiling: 2800,
        maxCeiling: 3400,
      );

      final decision = engine.decide(
        AiDecisionInput(
          player: 'Priyam',
          currentBid: 2400,
          currentBidLeader: 'user',
          nextIncrement: 250,
          yourPurseRemaining: 11000,
          yourSquadCount: 1,
          userPurseRemaining: 10000,
          userSquadCount: 1,
          playersRemainingInPool: 10,
          playersRemainingList: [starPlayer], // 0 similar 85+ players left in pool!
          yourSquadNames: const ['Ashutosh', 'Sangam', 'Saurabh'],
        ),
      );

      final json = decision.toJson();
      expect(json.containsKey('action'), isTrue);
      expect(json.containsKey('amount'), isTrue);
      expect(json.containsKey('strategy_note'), isTrue);
      expect(json.containsKey('trash_talk'), isTrue);
      expect(decision.strategyNote, contains('Scarcity'));
    });

    test('AiBrainProfile initializes and parses brain parameters accurately', () {
      final brain = AiBrainProfile.defaultBrain();
      expect(brain.personaName, 'stayrare-model');
      expect(brain.startingPurse, 12000);
      expect(brain.scarcityMultiplier, 1.20);
      expect(brain.squadReserveFloor, 100);
      expect(brain.rtmMinScore, 75);
      expect(brain.top7TargetCount, 3);
      expect(brain.maxPureBatters, 5);
      expect(brain.minBowlingOptions, 5);

      final customBrain = AiBrainProfile.fromJson({
        'persona': {'name': 'Custom Moneyball', 'archetype': 'Analyst'},
        'parameters': {
          'starting_purse': 15000,
          'scarcity_multiplier': 1.25,
          'squad_reserve_floor': 180,
          'rtm_min_score': 80,
          'top7_target_count': 3,
        },
        'player_valuations': [
          {'name': 'Priyam', 'score': 95, 'min_ceiling': 2800, 'max_ceiling': 2800, 'role': 'bat'}
        ]
      });

      expect(customBrain.personaName, 'Custom Moneyball');
      expect(customBrain.startingPurse, 15000);
      expect(customBrain.scarcityMultiplier, 1.25);
      expect(customBrain.squadReserveFloor, 180);
      expect(customBrain.rtmMinScore, 80);
      expect(customBrain.playerValuations.first.score, 95);
    });

    test('SoloAiAuctionSession allows dynamic custom team name and does not use All-Stars', () {
      final session = SoloAiAuctionSession();
      expect(session.userTeamName, 'My Team');
      expect(session.userTeamName.contains('All-Stars'), isFalse);

      session.setTeamName('Mumbai Mavericks');
      expect(session.userTeamName, 'Mumbai Mavericks');

      // Re-init preserves custom team name
      session.initSession();
      expect(session.userTeamName, 'Mumbai Mavericks');
    });

    test('SoloAiAuctionSession provides subjective post-match opinion without point leaks', () {
      final session = SoloAiAuctionSession();
      final opinion = session.postAuctionAiOpinion;
      expect(opinion, isNotEmpty);
      expect(opinion.contains('pts'), isFalse);
      expect(opinion.contains('Power Score'), isFalse);
      expect(opinion.contains('569'), isFalse);
      expect(opinion.contains('520'), isFalse);
    });

    test('AI raises RTM price strategically up to valuation ceiling (cold ₹1400, learned up to ₹3000)', () {
      final session = SoloAiAuctionSession();
      final avinash = StayrarePlayerDatabase.getValuationFor('Avinash');
      session.currentPlayerOnBlock = avinash;

      // AI opened at 500, User passed on bidding
      session.currentBidAmount = 500;
      session.currentLeader = SoloBidLeader.ai;

      // User invokes RTM
      session.rtmPhase = SoloRtmPhase.userCanInvoke;
      session.rtmBasePrice = 500;
      session.userInvokeRtm();

      // In cold start baseline, AI raises towards Avinash's maxCeiling (1400)
      expect(session.rtmRaisedPrice, greaterThanOrEqualTo(1000));
      expect(session.rtmRaisedPrice, lessThanOrEqualTo(1400));
      expect(session.rtmPhase, SoloRtmPhase.userRaisingPrice);
    });

    test('SoloAiAuctionSession initializes with 10-person squad target', () {
      final session = SoloAiAuctionSession();
      expect(session.targetSquadSize, 10);
      expect(session.playerPool.length, 22);
    });

    test('PlayerValuation computes compositeScore combining skill (60%) and auctionScore (40%)', () {
      final priyam = StayrarePlayerDatabase.getValuationFor('Priyam');
      expect(priyam.score, 50);
      expect(priyam.auctionScore, 50);
      expect(priyam.compositeScore, 50);
    });

    test('StayrareAiLearner dynamically recalculates player auctionScore and rankings', () {
      final learner = StayrareAiLearner();
      final ranked = learner.rankedPlayers;
      expect(ranked.isNotEmpty, isTrue);
      expect(ranked.first.name, 'Priyam');
      expect(ranked.first.adjustedRank, 1);

      // Simulate completed auction recording
      final session = RecordedAuctionSession(
        id: 'test_auction_1',
        timestamp: DateTime.now(),
        userTeamName: 'Danapur Dabangg',
        aiTeamName: 'stayrare-model',
        targetSquadSize: 11,
        initialPurse: 12000,
        userPurseRemaining: 100,
        aiPurseRemaining: 2700,
        biddingProcess: [
          {'order_index': 1, 'player_name': 'Priyam', 'bidder': 'user', 'amount': 3600}
        ],
        opponentProfile: OpponentAuctionProfile(
          userTeamName: 'Danapur Dabangg',
          totalUserBidsPlaced: 15,
          totalUserSpent: 11900,
          userJumpBidsPlaced: 2,
          top7StarsAcquired: 4,
          biddingStyle: 'Aggressive Star Hunter (Top-7 Specialist)',
          playerStudies: {
            'Priyam': OpponentPlayerStudy(
              playerName: 'Priyam',
              userBidCount: 5,
              userMaxBidPlaced: 3600,
              userWon: true,
              finalPrice: 3600,
              wasJumpBidUsed: true,
            ),
          },
        ),
        playerAuctionPrices: {'Priyam': 3600, 'Dev': 100},
      );

      final insights = learner.learnFromCompletedAuction(session);
      expect(insights.isNotEmpty, isTrue);
      final priyamInsight = insights.firstWhere((i) => i.playerName == 'Priyam');
      expect(priyamInsight.finalWinningPrice, 3600);
      expect(priyamInsight.newAuctionScore, greaterThanOrEqualTo(90));

      final updatedRanks = learner.rankedPlayers;
      expect(updatedRanks.first.name, 'Priyam');
      expect(updatedRanks.first.adjustedRank, 1);
      expect(updatedRanks.last.name, 'Dev');
      expect(updatedRanks.last.adjustedRank, 22);
    });

    test('Rank fluctuation dynamically adapts after subsequent auctions', () {
      final learner = StayrareAiLearner();
      learner.resetToDefaults();

      // Auction 1: Dev is sold for 3500 (high), Priyam sold for 200 (low)
      final session1 = RecordedAuctionSession(
        id: 'auction_1',
        timestamp: DateTime.now(),
        userTeamName: 'Danapur Dabangg',
        aiTeamName: 'stayrare-model',
        targetSquadSize: 10,
        initialPurse: 12000,
        userPurseRemaining: 100,
        aiPurseRemaining: 100,
        biddingProcess: [],
        opponentProfile: OpponentAuctionProfile(
          userTeamName: 'Danapur Dabangg',
          totalUserBidsPlaced: 10,
          totalUserSpent: 11900,
          userJumpBidsPlaced: 1,
          top7StarsAcquired: 1,
          biddingStyle: 'Aggressive',
          playerStudies: {},
        ),
        playerAuctionPrices: {'Dev': 3500, 'Priyam': 200, 'Ashutosh': 2400},
      );

      learner.learnFromCompletedAuction(session1);
      var ranks = learner.rankedPlayers;
      expect(ranks.first.name, 'Dev'); // Dev rises to #1
      expect(ranks.first.adjustedRank, 1);
      expect(ranks.first.compositeScore, greaterThan(65));

      // Auction 2: Priyam is sold for 3800, Dev sold for 150
      final session2 = RecordedAuctionSession(
        id: 'auction_2',
        timestamp: DateTime.now(),
        userTeamName: 'Danapur Dabangg',
        aiTeamName: 'stayrare-model',
        targetSquadSize: 10,
        initialPurse: 12000,
        userPurseRemaining: 100,
        aiPurseRemaining: 100,
        biddingProcess: [],
        opponentProfile: OpponentAuctionProfile(
          userTeamName: 'Danapur Dabangg',
          totalUserBidsPlaced: 10,
          totalUserSpent: 11900,
          userJumpBidsPlaced: 1,
          top7StarsAcquired: 1,
          biddingStyle: 'Aggressive',
          playerStudies: {},
        ),
        playerAuctionPrices: {'Dev': 150, 'Priyam': 3800, 'Ashutosh': 2600},
      );

      learner.learnFromCompletedAuction(session2);
      ranks = learner.rankedPlayers;
      expect(ranks.first.name, 'Ashutosh'); // Ashutosh is consistent high earner (#1)
      expect(ranks.first.adjustedRank, 1);
      final priyamVal = ranks.firstWhere((p) => p.name == 'Priyam');
      expect(priyamVal.adjustedRank, lessThanOrEqualTo(3)); // Priyam jumped massively from bottom to top 3
      expect(learner.totalAuctionsLearned, 2);
    });

    test('When AI has ₹10,000 purse for 5 remaining slots, it scales ceiling up to ₹2,000 for average players', () {
      final engine = StayrareAiEngine();
      final alok = StayrarePlayerDatabase.getValuationFor('Alok'); // Mid / baseline player (score: 50)

      // User has 2500, AI has 10000. Both at 5 players (5 slots needed).
      // AI purse per slot = 10000 / 5 = 2000!
      final decisionAt1250 = engine.decide(
        AiDecisionInput(
          player: alok.name,
          currentBid: 1250,
          currentBidLeader: 'user',
          nextIncrement: 250,
          yourPurseRemaining: 10000,
          yourSquadCount: 5,
          userPurseRemaining: 2500,
          userSquadCount: 5,
          playersRemainingInPool: 12,
          playersRemainingList: StayrarePlayerDatabase.officialValuations,
          targetSquadSize: 10,
        ),
      );

      // AI should continue bidding at 1500 (instead of stopping at 1000)
      expect(decisionAt1250.action, 'bid');
      expect(decisionAt1250.amount, 1500);

      final decisionAt1750 = engine.decide(
        AiDecisionInput(
          player: alok.name,
          currentBid: 1750,
          currentBidLeader: 'user',
          nextIncrement: 250,
          yourPurseRemaining: 10000,
          yourSquadCount: 5,
          userPurseRemaining: 2500,
          userSquadCount: 5,
          playersRemainingInPool: 12,
          playersRemainingList: StayrarePlayerDatabase.officialValuations,
          targetSquadSize: 10,
        ),
      );

      // AI continues bidding up to 2000 because its purse per slot is 2000!
      expect(decisionAt1750.action, 'bid');
      expect(decisionAt1750.amount, 2000);
    });

    test('AI goes all-out for lower-ranked player (#19 ranked) when user bought top stars and pool is scarce', () {
      final engine = StayrareAiEngine();
      // Suppose only Mohan, Dev, Shaurya remain in pool, and AI needs 1 player to complete squad
      final mohan = StayrarePlayerDatabase.getValuationFor('Mohan');

      final decision = engine.decide(
        AiDecisionInput(
          player: mohan.name,
          currentBid: 1200,
          currentBidLeader: 'user',
          nextIncrement: 250,
          yourPurseRemaining: 4000,
          yourSquadCount: 9, // Needs 1 player to reach 10!
          userPurseRemaining: 1500,
          userSquadCount: 9,
          playersRemainingInPool: 2, // Pool is almost empty!
          playersRemainingList: [mohan, StayrarePlayerDatabase.getValuationFor('Dev')],
          targetSquadSize: 10,
        ),
      );

      // AI must win this player to complete squad, so it bids 1450 even on a lower-ranked player!
      expect(decision.action, 'bid');
      expect(decision.amount, 1450);
    });

    test('Session automatically recycles unsold players into Accelerated Round when fresh pool is exhausted and squads incomplete', () {
      final session = SoloAiAuctionSession();
      session.initSession(squadTarget: 10);

      // Buy 8 players for user and 8 players for AI
      for (int i = 0; i < 8; i++) {
        final p = session.playerPool[i];
        session.playerStatusMap[p.name] = SoloPlayerStatus.soldUser;
        session.userSquad.add(SoloBoughtPlayer(valuation: p, price: 1000));
      }
      for (int i = 8; i < 16; i++) {
        final p = session.playerPool[i];
        session.playerStatusMap[p.name] = SoloPlayerStatus.soldAi;
        session.aiSquad.add(SoloBoughtPlayer(valuation: p, price: 1000));
      }

      // Mark the remaining 6 players as unsold
      for (int i = 16; i < 22; i++) {
        final p = session.playerPool[i];
        session.playerStatusMap[p.name] = SoloPlayerStatus.unsold;
      }

      expect(session.unassignedPlayersCount, 0);
      expect(session.unsoldPlayersCount, 6);
      expect(session.isAuctionCompleted, false);

      // Drawing next random player should automatically trigger Accelerated Round and recycle all 6 unsold players!
      session.drawNextRandomPlayer();

      expect(session.isAcceleratedRound, true);
      expect(session.currentPlayerOnBlock, isNotNull);
      expect(session.isAuctionCompleted, false);
      // The remaining 5 unsold should now be in the active pool
      expect(session.unassignedPlayersCount, 5);
    });

    test('User can directly nominate/re-auction an unsold player from the pool tab', () {
      final session = SoloAiAuctionSession();
      session.initSession(squadTarget: 10);

      final unsoldPlayer = session.playerPool.first;
      session.playerStatusMap[unsoldPlayer.name] = SoloPlayerStatus.unsold;

      // User requests this unsold player for auction
      session.requestPlayerForAuction(unsoldPlayer);

      expect(session.currentPlayerOnBlock?.name, unsoldPlayer.name);
      expect(session.playerStatusMap[unsoldPlayer.name], SoloPlayerStatus.onBlock);
    });

    test('userDraftRemainingPlayerAtBase allows drafting unsold players to complete squad', () {
      final session = SoloAiAuctionSession();
      session.initSession(squadTarget: 10);

      // Fill user squad to 9
      for (int i = 0; i < 9; i++) {
        final p = session.playerPool[i];
        session.playerStatusMap[p.name] = SoloPlayerStatus.soldUser;
        session.userSquad.add(SoloBoughtPlayer(valuation: p, price: 1000));
      }

      final unsoldPlayer = session.playerPool[15];
      session.playerStatusMap[unsoldPlayer.name] = SoloPlayerStatus.unsold;

      session.userDraftRemainingPlayerAtBase(unsoldPlayer);

      expect(session.userSquad.length, 10);
      expect(session.userSquad.last.valuation.name, unsoldPlayer.name);
      expect(session.playerStatusMap[unsoldPlayer.name], SoloPlayerStatus.soldUser);
    });
  });
}
