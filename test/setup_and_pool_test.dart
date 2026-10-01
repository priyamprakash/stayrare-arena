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

    test('Changing captains and team names updates owners, team names, and returns former captains to pool', () {
      // Switch captains to Priyam and Sangam with custom team names
      service.setCaptains('Priyam', 'Sangam', team1Name: 'Super Strikers', team2Name: 'Mighty Warriors');

      expect(service.captain1Name, 'Priyam');
      expect(service.captain2Name, 'Sangam');
      expect(service.teams[0].name, 'Super Strikers');
      expect(service.teams[1].name, 'Mighty Warriors');

      final owners = service.people.where((p) => p.role == PersonRole.owner).toList();
      expect(owners.map((o) => o.name).toSet(), {'Priyam', 'Sangam'});

      // Saurabh and Avinash are now in the auction pool as players
      final poolPlayers = service.people.where((p) => p.role == PersonRole.player).toList();
      expect(poolPlayers.length, 18);
      expect(poolPlayers.any((p) => p.name == 'Saurabh'), isTrue);
      expect(poolPlayers.any((p) => p.name == 'Avinash'), isTrue);
      expect(poolPlayers.any((p) => p.name == 'Priyam'), isFalse);
      expect(poolPlayers.any((p) => p.name == 'Sangam'), isFalse);
    });
  });
}
