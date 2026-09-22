import 'package:flutter_test/flutter_test.dart';
import 'package:stayrare/models/league.dart';
import 'package:stayrare/services/league_service.dart';

void main() {
  group('IPL Rishabh Pant Style RTM Auction Flow Tests', () {
    late LeagueService service;
    late Person player;

    setUp(() {
      service = LeagueService();
      player = service.people.firstWhere((p) => p.status == PersonStatus.pending);
      service.selectPlayerForAuction(player);
    });

    test('RTM Match Scenario: Team A bids ₹X, Team B triggers RTM, Team A raises to ₹Y, Team B matches ₹Y', () {
      const initialBidX = 2075;
      const raisedBidY = 2700;

      // 1. Team A (Rohan/LSG) bids ₹X (2075), Team B (Saurabh/PBKS) triggers RTM
      service.initiateRtmCheck('team_rohan', initialBidX, matchingTeamId: 'team_saurabh');

      expect(service.pendingRtmPerson?.id, player.id);
      expect(service.pendingRtmPrice, initialBidX);
      expect(service.pendingRtmSourceTeamId, 'team_rohan');
      expect(service.pendingRtmMatchingTeamId, 'team_saurabh');
      expect(service.pendingRtmStage, RtmStage.increaseBid);

      // 2. Team A (LSG) raises bid to ₹Y (2700)
      service.updateRtmIncreasedPrice(raisedBidY);
      expect(service.pendingRtmIncreasedPrice, raisedBidY);

      service.setRtmStage(RtmStage.confirmMatch);
      expect(service.pendingRtmStage, RtmStage.confirmMatch);

      // 3. Team B (PBKS) matches ₹Y (2700)
      service.executeRtmMatch(raisedBidY);

      // Verify Player Ownership & Signing
      final signing = service.getSigningForPerson(player.id);
      expect(signing, isNotNull);
      expect(signing!.teamId, 'team_saurabh');
      expect(signing.price, raisedBidY);
      expect(signing.type, SigningType.rtm);

      // Verify RTM Card count deducted for Team B
      expect(service.getRtmCardsLeft('team_saurabh'), 0);
      expect(service.getRtmCardsLeft('team_rohan'), 1);

      // Verify Purse deduction
      expect(service.getTeamSpend('team_saurabh'), raisedBidY);
      expect(service.getTeamSpend('team_rohan'), 0);

      // State reset
      expect(service.pendingRtmPerson, isNull);
    });

    test('RTM Decline Scenario: Team A bids ₹X, Team B triggers RTM, Team A raises to ₹Y, Team B declines ₹Y', () {
      const initialBidX = 2075;
      const raisedBidY = 2700;

      // 1. Team A (Rohan/LSG) bids ₹X (2075), Team B (Saurabh/PBKS) triggers RTM
      service.initiateRtmCheck('team_rohan', initialBidX, matchingTeamId: 'team_saurabh');

      // 2. Team A raises bid to ₹Y (2700)
      service.updateRtmIncreasedPrice(raisedBidY);
      service.setRtmStage(RtmStage.confirmMatch);

      // 3. Team B declines ₹Y (2700)
      service.declineRtmMatch(raisedBidY);

      // Verify Player Ownership goes to Team A for ₹Y
      final signing = service.getSigningForPerson(player.id);
      expect(signing, isNotNull);
      expect(signing!.teamId, 'team_rohan');
      expect(signing.price, raisedBidY);
      expect(signing.type, SigningType.auction);

      // Verify RTM Card count for Team B is NOT deducted because match was declined
      expect(service.getRtmCardsLeft('team_saurabh'), 1);
      expect(service.getRtmCardsLeft('team_rohan'), 1);

      // Verify Purse deduction goes to Team A for ₹Y
      expect(service.getTeamSpend('team_rohan'), raisedBidY);
      expect(service.getTeamSpend('team_saurabh'), 0);

      // State reset
      expect(service.pendingRtmPerson, isNull);
    });
  });
}
