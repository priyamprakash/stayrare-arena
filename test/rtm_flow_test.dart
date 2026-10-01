import 'package:flutter_test/flutter_test.dart';
import 'package:stayrare/models/league.dart';
import 'package:stayrare/services/league_service.dart';

void main() {
  group('IPL Style RTM Auction Flow Tests', () {
    late LeagueService service;
    late Person player;

    setUp(() {
      service = LeagueService();
      player = service.people.firstWhere((p) => p.status == PersonStatus.pending);
      service.selectPlayerForAuction(player);
    });

    test('RTM Match Scenario: Team 1 bids ₹X, Team 2 triggers RTM, Team 1 raises to ₹Y, Team 2 matches ₹Y', () {
      const initialBidX = 2075;
      const raisedBidY = 2700;

      // 1. Team 1 (Saurabh) bids ₹X (2075), Team 2 (Avinash) triggers RTM
      service.initiateRtmCheck('team_1', initialBidX, matchingTeamId: 'team_2');

      expect(service.pendingRtmPerson?.id, player.id);
      expect(service.pendingRtmPrice, initialBidX);
      expect(service.pendingRtmSourceTeamId, 'team_1');
      expect(service.pendingRtmMatchingTeamId, 'team_2');
      expect(service.pendingRtmStage, RtmStage.increaseBid);

      // 2. Team 1 raises bid to ₹Y (2700)
      service.updateRtmIncreasedPrice(raisedBidY);
      expect(service.pendingRtmIncreasedPrice, raisedBidY);

      service.setRtmStage(RtmStage.confirmMatch);
      expect(service.pendingRtmStage, RtmStage.confirmMatch);

      // 3. Team 2 matches ₹Y (2700)
      service.executeRtmMatch(raisedBidY);

      // Verify Player Ownership & Signing
      final signing = service.getSigningForPerson(player.id);
      expect(signing, isNotNull);
      expect(signing!.teamId, 'team_2');
      expect(signing.price, raisedBidY);
      expect(signing.type, SigningType.rtm);

      // Verify RTM Card count deducted for Team 2
      expect(service.getRtmCardsLeft('team_2'), 0);
      expect(service.getRtmCardsLeft('team_1'), 1);

      // Verify Purse deduction
      expect(service.getTeamSpend('team_2'), raisedBidY);
      expect(service.getTeamSpend('team_1'), 0);

      // State reset
      expect(service.pendingRtmPerson, isNull);
    });

    test('RTM Decline Scenario: Team 1 bids ₹X, Team 2 triggers RTM, Team 1 raises to ₹Y, Team 2 declines ₹Y -> Team 2 still exhausts RTM card', () {
      const initialBidX = 2075;
      const raisedBidY = 2700;

      // 1. Team 1 bids ₹X (2075), Team 2 triggers RTM
      service.initiateRtmCheck('team_1', initialBidX, matchingTeamId: 'team_2');

      // 2. Team 1 raises bid to ₹Y (2700)
      service.updateRtmIncreasedPrice(raisedBidY);
      service.setRtmStage(RtmStage.confirmMatch);

      // 3. Team 2 declines ₹Y (2700)
      service.declineRtmMatch(raisedBidY);

      // Verify Player Ownership goes to Team 1 for ₹Y
      final signing = service.getSigningForPerson(player.id);
      expect(signing, isNotNull);
      expect(signing!.teamId, 'team_1');
      expect(signing.price, raisedBidY);
      expect(signing.type, SigningType.auction);

      // Verify RTM Card count for Team 2 IS deducted (0 left) because exercising RTM exhausts the 1 RTM quota
      expect(service.getRtmCardsLeft('team_2'), 0);
      expect(service.getRtmCardsLeft('team_1'), 1);

      // Verify Purse deduction goes to Team 1 for ₹Y
      expect(service.getTeamSpend('team_1'), raisedBidY);
      expect(service.getTeamSpend('team_2'), 0);

      // State reset
      expect(service.pendingRtmPerson, isNull);
    });
  });
}
