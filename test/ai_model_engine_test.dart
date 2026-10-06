import 'package:flutter_test/flutter_test.dart';
import 'package:stayrare/models/ai_model_valuation.dart';
import 'package:stayrare/services/stayrare_ai_engine.dart';
import 'package:stayrare/services/solo_ai_auction_session.dart';
import 'package:stayrare/services/ai_brain_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stayrare-model AI Valuation & Decision Engine Tests', () {
    late StayrareAiEngine engine;

    setUp(() {
      engine = StayrareAiEngine();
    });

    test('Valuations database matches exact user specifications', () {
      final priyam = StayrarePlayerDatabase.getValuationFor('Priyam');
      expect(priyam.score, 93);
      expect(priyam.minCeiling, 3000);
      expect(priyam.maxCeiling, 3800);
      expect(priyam.role, CricketRole.allRounder);

      final ashutosh = StayrarePlayerDatabase.getValuationFor('Ashutosh');
      expect(ashutosh.score, 89);
      expect(ashutosh.maxCeiling, 3500);
      expect(ashutosh.role, CricketRole.allRounder);

      final avinash = StayrarePlayerDatabase.getValuationFor('Avinash');
      expect(avinash.score, 86);
      expect(avinash.maxCeiling, 3000);
      expect(avinash.role, CricketRole.allRounder);

      // Verify Priyam is valued higher than Avinash
      expect(priyam.maxCeiling, greaterThan(avinash.maxCeiling));

      final rahul = StayrarePlayerDatabase.getValuationFor('Rahul');
      expect(rahul.score, 68);
      expect(rahul.maxCeiling, 2400);
      expect(rahul.role, CricketRole.bat);

      final dev = StayrarePlayerDatabase.getValuationFor('Dev');
      expect(dev.score, 5);
      expect(dev.minCeiling, 100);
      expect(dev.role, CricketRole.bat);

      final amit = StayrarePlayerDatabase.getValuationFor('Amit');
      expect(amit.score, 50);
      expect(amit.minCeiling, 750);
    });

    test('AI bids aggressively above 1750 on Rahul when top 7 star is needed and purse is available', () {
      final decision = engine.decide(
        const AiDecisionInput(
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
        const AiDecisionInput(
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

    test('Marquee players (Priyam, Ashutosh, Sangam, Avinash, Saurabh, Sunny, Rahul) are drawn first', () {
      final session = SoloAiAuctionSession();
      // Draw first 7 players
      for (int i = 0; i < 7; i++) {
        session.drawNextRandomPlayer();
        final current = session.currentPlayerOnBlock!;
        expect(current.isMarqueeDefault || current.score >= 68, isTrue,
            reason: 'Drawn player ${current.name} (score ${current.score}) should be a marquee player');
        session.userMarkUnsold();
      }
    });

    test('AI passes on opening bid for low-tier players when stars remain in pool', () {
      final decision = engine.decide(
        const AiDecisionInput(
          player: 'Dev', // score 5
          currentBid: 0,
          currentBidLeader: 'none',
          nextIncrement: 100,
          yourPurseRemaining: 12000,
          yourSquadCount: 0,
          userPurseRemaining: 12000,
          userSquadCount: 0,
          playersRemainingInPool: 20,
          playersRemainingList: StayrarePlayerDatabase.officialValuations,
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
      final marquee = session.playerPool.firstWhere((p) => p.name == 'Priyam');
      final regular = session.playerPool.firstWhere((p) => p.name == 'Dev');

      expect(session.getBasePriceForPlayer(marquee), 500);
      expect(session.getBasePriceForPlayer(regular), 100);

      session.startAcceleratedRound();
      expect(session.isAcceleratedRound, isTrue);
      expect(session.getBasePriceForPlayer(marquee), 300); // 40% off 500
      expect(session.getBasePriceForPlayer(regular), 50); // 50% / 40% off 100
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
      final decision = engine.decide(
        const AiDecisionInput(
          player: 'Priyam', // 93 score
          currentBid: 2400,
          currentBidLeader: 'user',
          nextIncrement: 250,
          yourPurseRemaining: 11000,
          yourSquadCount: 1,
          userPurseRemaining: 10000,
          userSquadCount: 1,
          playersRemainingInPool: 10,
          playersRemainingList: [], // 0 similar 85+ players left in pool!
          yourSquadNames: ['Ashutosh', 'Sangam', 'Saurabh'], // Already has 3 top 7 stars
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

    test('AI raises RTM price strategically near player valuation ceiling on marquee players like Avinash', () {
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

      // Verify AI raised the price aggressively towards Avinash's ceiling (~3000), NOT just 600
      expect(session.rtmRaisedPrice, greaterThanOrEqualTo(2500));
      expect(session.rtmRaisedPrice, lessThanOrEqualTo(3000));
      expect(session.rtmPhase, SoloRtmPhase.userRaisingPrice);
    });
  });
}
