import 'package:flutter_test/flutter_test.dart';
import 'package:stayrare/models/league.dart';
import 'package:stayrare/services/league_service.dart';

void main() {
  group('League Captains & Team Setup Tests', () {
    late LeagueService service;

    setUp(() {
      service = LeagueService();
    });

    test('Default setup initializes with 20 base players, Saurabh & Avinash as Captains/Owners', () {
      expect(LeagueService.defaultPoolNames.length, 20);
      expect(service.captain1Name, 'Saurabh');
      expect(service.captain2Name, 'Avinash');

      // 2 Teams created with proper owners
      expect(service.teams.length, 2);
      expect(service.teams[0].name, 'Team Saurabh');
      expect(service.teams[0].ownerName, 'Saurabh');
      expect(service.teams[1].name, 'Team Avinash');
      expect(service.teams[1].ownerName, 'Avinash');

      // Owners are marked as PersonRole.owner
      final owners = service.people.where((p) => p.role == PersonRole.owner).toList();
      expect(owners.length, 2);
      expect(owners.map((o) => o.name).toSet(), {'Saurabh', 'Avinash'});

      // Remaining 18 players in auction pool as PersonRole.player
      final poolPlayers = service.people.where((p) => p.role == PersonRole.player).toList();
      expect(poolPlayers.length, 18);
      expect(poolPlayers.any((p) => p.name == 'Saurabh'), isFalse);
      expect(poolPlayers.any((p) => p.name == 'Avinash'), isFalse);
      expect(poolPlayers.any((p) => p.name == 'Priyam'), isTrue);
      expect(poolPlayers.any((p) => p.name == 'Sangam'), isTrue);
      expect(poolPlayers.any((p) => p.name == 'Aditya'), isTrue);
    });

    test('Changing captains before auction: Avinash replaced by Priyam -> Avinash goes to pool, Priyam becomes owner/captain', () {
      // Replace Avinash with Priyam
      service.setCaptains('Saurabh', 'Priyam');

      expect(service.captain1Name, 'Saurabh');
      expect(service.captain2Name, 'Priyam');
      expect(service.teams[0].name, 'Team Saurabh');
      expect(service.teams[1].name, 'Team Priyam');

      final owners = service.people.where((p) => p.role == PersonRole.owner).toList();
      expect(owners.map((o) => o.name).toSet(), {'Saurabh', 'Priyam'});

      // Avinash goes into the auction pool as a regular player
      final poolPlayers = service.people.where((p) => p.role == PersonRole.player).toList();
      expect(poolPlayers.length, 18);
      expect(poolPlayers.any((p) => p.name == 'Avinash'), isTrue);
      expect(poolPlayers.any((p) => p.name == 'Priyam'), isFalse);
    });

    test('Changing captains after auction with resetPool=false preserves existing signings', () {
      // 1. Sell a player in auction
      final ricky = service.people.firstWhere((p) => p.name == 'Ritesh');
      service.selectPlayerForAuction(ricky);
      service.sellSelectedPlayer('team_1', 1200);

      expect(service.signings.length, 1);
      expect(service.getTeamSpend('team_1'), 1200);

      // 2. Replace captain Avinash with Priyam after auction without resetting auction state
      service.setCaptains('Saurabh', 'Priyam', resetPool: false);

      expect(service.captain1Name, 'Saurabh');
      expect(service.captain2Name, 'Priyam');
      expect(service.teams[1].name, 'Team Priyam');
      expect(service.teams[1].ownerName, 'Priyam');

      // Existing signing is preserved
      expect(service.signings.length, 1);
      expect(service.getTeamSpend('team_1'), 1200);
    });
  });
}
