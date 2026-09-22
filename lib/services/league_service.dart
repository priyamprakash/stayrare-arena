import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/league.dart';

class LeagueService extends ChangeNotifier {
  // Config constants
  static const int totalPursePerTeam = 10000;
  static const int matchesPlanned = 5;

  // Match settings
  int targetSquadSizePerSide = 10; // Default 10 per side, adjustable to 11

  // RTM Cards (1 per team)
  int rohanRtmLeft = 1;
  int saurabhRtmLeft = 1;

  // Data collections
  final List<TeamData> teams = [];
  final List<Person> people = [];
  final List<Signing> signings = [];
  final List<Refund> refunds = [];
  final List<CricketMatch> matches = [];
  final Map<String, Map<int, AttendanceStatus>> attendanceMap = {}; // personId -> (matchNum -> status)
  final Map<int, List<RosterEntry>> matchRosters = {}; // matchNum -> entries
  final Map<String, int> sitOutCounts = {}; // personId -> sitOutCount
  final List<AuditLog> auditLogs = [];

  // RTM state logic
  Person? pendingRtmPerson;
  int pendingRtmPrice = 0; // Initial bid ₹X
  int pendingRtmIncreasedPrice = 0; // Raised bid ₹Y by Team A
  String pendingRtmSourceTeamId = ''; // Team A
  String? pendingRtmMatchingTeamId; // Team B
  RtmStage pendingRtmStage = RtmStage.increaseBid;

  // Currently selected player in Auction Manager
  Person? selectedAuctionPerson;

  LeagueService() {
    _initializeData();
  }

  void _initializeData() {
    // 1. Teams
    teams.clear();
    teams.add(TeamData(
      id: 'team_rohan',
      name: 'Team Rohan',
      ownerPersonId: 'rohan',
      ownerName: 'Rohan',
    ));
    teams.add(TeamData(
      id: 'team_saurabh',
      name: 'Team Saurabh',
      ownerPersonId: 'saurabh',
      ownerName: 'Saurabh',
    ));

    // 2. Matches
    matches.clear();
    final now = DateTime.now();
    for (int i = 1; i <= matchesPlanned; i++) {
      matches.add(CricketMatch(
        number: i,
        date: now.add(Duration(days: 6 * i)),
      ));
    }

    // 3. Prefill Player Pool
    resetAuction();

    _logAudit('System', 'Initialization', 'Auction initialized with Marquee and Normal player pool.');
  }

  void _prefillPlayerPool() {
    people.clear();
    signings.clear();
    refunds.clear();
    selectedAuctionPerson = null;
    pendingRtmPerson = null;
    rohanRtmLeft = 1;
    saurabhRtmLeft = 1;

    // Owners
    people.add(Person(id: 'rohan', name: 'Rohan', role: PersonRole.owner));
    people.add(Person(id: 'saurabh', name: 'Saurabh', role: PersonRole.owner));

    // Prefilled Player Pool (18 Players)
    // Marquee: Sangam, Avinash, Sunny, Priyam, Rahul (Base Price ₹500)
    final marqueeNames = {'sangam', 'avinash', 'sunny', 'priyam', 'rahul'};

    final poolNames = [
      'Sunny',
      'Priyam',
      'Rahul',
      'Sangam',
      'Avinash',
      'Aman',
      'Ritesh',
      'Mohan',
      'Niranjan',
      'Ashutosh',
      'Alok',
      'Aashish',
      'Satish',
      'Shaurya',
      'Mohit',
      'Dev',
      'Tinku',
      'Piyush',
      'Ikschit',
    ];

    for (final name in poolNames) {
      final id = name.toLowerCase();
      final isMarquee = marqueeNames.contains(id);

      final person = Person(
        id: id,
        name: name,
        role: PersonRole.player,
        category: isMarquee ? PlayerCategory.marquee : PlayerCategory.normal,
        status: PersonStatus.pending,
      );
      people.add(person);

      attendanceMap[id] = {
        for (int m = 1; m <= matchesPlanned; m++) m: AttendanceStatus.inStatus
      };
      sitOutCounts[id] = 0;
    }

    // Default attendance for owners
    attendanceMap['rohan'] = {for (int m = 1; m <= matchesPlanned; m++) m: AttendanceStatus.inStatus};
    attendanceMap['saurabh'] = {for (int m = 1; m <= matchesPlanned; m++) m: AttendanceStatus.inStatus};
    sitOutCounts['rohan'] = 0;
    sitOutCounts['saurabh'] = 0;
  }

  // --- Calculations ---

  int getTeamSpend(String teamId) {
    int total = 0;
    for (final s in signings.where((s) => s.teamId == teamId)) {
      total += s.price;
    }
    for (final r in refunds.where((r) => r.teamId == teamId)) {
      total -= r.amount;
    }
    return total;
  }

  int getTeamPurseLeft(String teamId) {
    return totalPursePerTeam - getTeamSpend(teamId);
  }

  List<Person> getTeamPlayers(String teamId) {
    final activeSignings = signings.where((s) => s.teamId == teamId).map((s) => s.personId).toSet();
    final exitedPersonIds = people.where((p) => p.status == PersonStatus.exited).map((p) => p.id).toSet();

    final playerIds = activeSignings.difference(exitedPersonIds);
    return people.where((p) => playerIds.contains(p.id)).toList();
  }

  Signing? getSigningForPerson(String personId) {
    final matches = signings.where((s) => s.personId == personId).toList();
    return matches.isNotEmpty ? matches.last : null;
  }

  int getBoughtCount(String teamId) {
    return getTeamPlayers(teamId).where((p) => p.role == PersonRole.player).length;
  }

  int getMaxBidAllowed(String teamId) {
    final purseLeft = getTeamPurseLeft(teamId);
    final currentBought = getBoughtCount(teamId);
    final slotsStillNeeded = (targetSquadSizePerSide - 1) - currentBought; // minus owner

    if (slotsStillNeeded <= 0) {
      if (currentBought >= targetSquadSizePerSide) return 0;
      return purseLeft;
    }

    // Reserve rule: maxBid = purseLeft - 100 * (slotsStillNeeded - 1)
    final reserveRequired = 100 * (slotsStillNeeded - 1);
    final allowed = purseLeft - reserveRequired;
    return allowed > 0 ? allowed : 0;
  }

  int getRtmCardsLeft(String teamId) {
    return teamId == 'team_rohan' ? rohanRtmLeft : saurabhRtmLeft;
  }

  // --- Auction Operations ---

  int getNextBidAmount(int currentBid) {
    if (currentBid < 500) return currentBid + 100;
    if (currentBid < 2000) return currentBid + 250;
    return currentBid + 500;
  }

  void selectPlayerForAuction(Person person) {
    selectedAuctionPerson = person;
    pendingRtmPerson = null;
    notifyListeners();
  }

  void togglePlayerCategory(String personId) {
    final person = people.firstWhere((p) => p.id == personId);
    person.category = person.category == PlayerCategory.marquee ? PlayerCategory.normal : PlayerCategory.marquee;
    _logAudit('Admin', 'Category Updated', '${person.name} set to ${person.category.label} (Base ₹${person.basePrice}).');
    notifyListeners();
  }

  void initiateRtmCheck(String sellingTeamId, int finalPrice, {String? matchingTeamId}) {
    if (selectedAuctionPerson == null) return;

    final targetMatchingTeamId = matchingTeamId ?? (sellingTeamId == 'team_rohan' ? 'team_saurabh' : 'team_rohan');

    // Does opposing team have RTM left and purse to match?
    if (getRtmCardsLeft(targetMatchingTeamId) <= 0 || getMaxBidAllowed(targetMatchingTeamId) < finalPrice) {
      // Cannot use RTM, just sell to the original team
      sellSelectedPlayer(sellingTeamId, finalPrice);
      return;
    }

    // Set pending RTM state
    pendingRtmPerson = selectedAuctionPerson;
    pendingRtmPrice = finalPrice;
    pendingRtmIncreasedPrice = finalPrice;
    pendingRtmSourceTeamId = sellingTeamId;
    pendingRtmMatchingTeamId = targetMatchingTeamId;
    pendingRtmStage = RtmStage.increaseBid;
    selectedAuctionPerson = null; // Remove from normal block

    notifyListeners();
  }

  void updateRtmIncreasedPrice(int newPrice) {
    if (pendingRtmPerson == null) return;
    pendingRtmIncreasedPrice = newPrice;
    notifyListeners();
  }

  void setRtmStage(RtmStage stage) {
    pendingRtmStage = stage;
    notifyListeners();
  }

  void executeRtmMatch(int newFinalPrice) {
    if (pendingRtmPerson == null || pendingRtmMatchingTeamId == null) return;
    
    final person = pendingRtmPerson!;
    final teamId = pendingRtmMatchingTeamId!;
    
    if (getMaxBidAllowed(teamId) < newFinalPrice) return;
    if (getRtmCardsLeft(teamId) <= 0) return;

    if (teamId == 'team_rohan') {
      rohanRtmLeft--;
    } else {
      saurabhRtmLeft--;
    }

    person.status = PersonStatus.active;

    signings.add(Signing(
      id: 'rtm_${person.id}_${DateTime.now().millisecondsSinceEpoch}',
      personId: person.id,
      teamId: teamId,
      price: newFinalPrice,
      type: SigningType.rtm,
      timestamp: DateTime.now(),
    ));

    final teamName = teams.firstWhere((t) => t.id == teamId).name;
    _logAudit('Auction', 'RTM Matched', '$teamName used RTM to match ₹$newFinalPrice and claimed ${person.name}.');

    pendingRtmPerson = null;
    notifyListeners();
  }

  void declineRtmMatch(int newFinalPrice) {
    if (pendingRtmPerson == null || pendingRtmSourceTeamId.isEmpty) return;

    // The opposing team declined, so the original bidding team gets the player at the final asked price
    final person = pendingRtmPerson!;
    final teamId = pendingRtmSourceTeamId;

    if (getMaxBidAllowed(teamId) < newFinalPrice) return;

    person.status = PersonStatus.active;

    signings.add(Signing(
      id: 'sign_${person.id}_${DateTime.now().millisecondsSinceEpoch}',
      personId: person.id,
      teamId: teamId,
      price: newFinalPrice,
      type: SigningType.auction,
      timestamp: DateTime.now(),
    ));

    final teamName = teams.firstWhere((t) => t.id == teamId).name;
    _logAudit('Auction', 'Player Sold', '${person.name} sold to $teamName for ₹$newFinalPrice (RTM declined).');

    pendingRtmPerson = null;
    notifyListeners();
  }

  void cancelRtmFlow() {
    // Revert back to auction block if needed
    if (pendingRtmPerson != null) {
      selectedAuctionPerson = pendingRtmPerson;
    }
    pendingRtmPerson = null;
    notifyListeners();
  }

  void sellSelectedPlayer(String teamId, int price) {
    if (selectedAuctionPerson == null) return;

    final person = selectedAuctionPerson!;
    final maxAllowed = getMaxBidAllowed(teamId);

    if (price > maxAllowed) return; // Breaks reserve rule or exceeds purse

    person.status = PersonStatus.active;

    signings.add(Signing(
      id: 'sign_${person.id}_${DateTime.now().millisecondsSinceEpoch}',
      personId: person.id,
      teamId: teamId,
      price: price,
      type: SigningType.auction,
      timestamp: DateTime.now(),
    ));

    final teamName = teams.firstWhere((t) => t.id == teamId).name;
    _logAudit('Auction', 'Player Sold', '${person.name} sold to $teamName for ₹$price.');

    selectedAuctionPerson = null;
    notifyListeners();
  }

  void markSelectedPlayerUnsold() {
    if (selectedAuctionPerson == null) return;
    selectedAuctionPerson!.status = PersonStatus.pending; // Returns to pool
    _logAudit('Auction', 'Player Unsold', '${selectedAuctionPerson!.name} marked unsold and returned to pool.');
    selectedAuctionPerson = null;
    notifyListeners();
  }

  void resetAuction() {
    _prefillPlayerPool();
    _logAudit('Admin', 'Reset Auction', 'Reset auction pool and purses.');
    notifyListeners();
  }

  void addPersonToPool(String name, PlayerCategory category) {
    final id = '${name.toLowerCase().replaceAll(' ', '_')}_${Random().nextInt(1000)}';
    final person = Person(
      id: id,
      name: name,
      role: PersonRole.player,
      category: category,
      status: PersonStatus.pending,
    );
    people.add(person);
    attendanceMap[id] = {for (int m = 1; m <= matchesPlanned; m++) m: AttendanceStatus.inStatus};
    sitOutCounts[id] = 0;

    _logAudit('Admin', 'Add Player Pool', 'Added $name (${category.label}, Base ₹${category.basePrice}) to auction pool.');
    notifyListeners();
  }

  // --- Late Joiner Rules ---

  int getLateJoinerPrice(PlayerCategory category) {
    return category.basePrice;
  }

  String determineLateJoinerTeamAssignment() {
    final rohanBought = getBoughtCount('team_rohan');
    final saurabhBought = getBoughtCount('team_saurabh');

    if (rohanBought < saurabhBought) return 'team_rohan';
    if (saurabhBought < rohanBought) return 'team_saurabh';

    final rohanValue = getTeamSpend('team_rohan');
    final saurabhValue = getTeamSpend('team_saurabh');

    if (rohanValue < saurabhValue) return 'team_rohan';
    if (saurabhValue < rohanValue) return 'team_saurabh';

    return Random().nextBool() ? 'team_rohan' : 'team_saurabh';
  }

  void addLateJoiner(String name, PlayerCategory category) {
    final assignedTeamId = determineLateJoinerTeamAssignment();
    final fixedPrice = category.basePrice;

    final id = 'late_${name.toLowerCase().replaceAll(' ', '_')}_${Random().nextInt(1000)}';
    final person = Person(
      id: id,
      name: name,
      role: PersonRole.player,
      category: category,
      status: PersonStatus.active,
    );
    people.add(person);

    attendanceMap[id] = {for (int m = 1; m <= matchesPlanned; m++) m: AttendanceStatus.inStatus};
    sitOutCounts[id] = 0;

    final purseLeft = getTeamPurseLeft(assignedTeamId);
    int actualPrice = fixedPrice;
    if (purseLeft < fixedPrice) {
      actualPrice = purseLeft > 100 ? purseLeft : 100;
    }

    signings.add(Signing(
      id: 'sign_$id',
      personId: id,
      teamId: assignedTeamId,
      price: actualPrice,
      type: SigningType.latePool,
      timestamp: DateTime.now(),
    ));

    final teamName = teams.firstWhere((t) => t.id == assignedTeamId).name;
    _logAudit('Late-Join', 'Assigned Player', '$name (${category.label}) assigned to $teamName for ₹$actualPrice.');
    notifyListeners();
  }

  // --- Exits & Refunds (100% Refund to Purse) ---

  void processPlayerExit(String personId, String reason) {
    final person = people.firstWhere((p) => p.id == personId);
    final signing = getSigningForPerson(personId);

    if (signing == null) return;

    final originalPrice = signing.price;
    person.status = PersonStatus.exited;

    final refund = Refund(
      id: 'ref_${DateTime.now().millisecondsSinceEpoch}',
      signingId: signing.id,
      personId: personId,
      teamId: signing.teamId,
      amount: originalPrice, // 100% money back to purse
      reason: reason,
      timestamp: DateTime.now(),
    );

    refunds.add(refund);

    final teamName = teams.firstWhere((t) => t.id == signing.teamId).name;
    _logAudit('Exit/Refund', 'Player Exit', '${person.name} exited ($teamName). 100% refunded ₹$originalPrice back to purse. Reason: $reason.');
    notifyListeners();
  }

  // --- Trades ---

  void processTrade(String personId1, String personId2) {
    final signing1 = getSigningForPerson(personId1);
    final signing2 = getSigningForPerson(personId2);

    if (signing1 == null || signing2 == null || signing1.teamId == signing2.teamId) return;

    final team1Id = signing1.teamId;
    final team2Id = signing2.teamId;

    signings.add(Signing(
      id: 'trade_${signing1.id}_${DateTime.now().millisecondsSinceEpoch}',
      personId: personId1,
      teamId: team2Id,
      price: signing1.price,
      type: SigningType.trade,
      timestamp: DateTime.now(),
    ));

    signings.add(Signing(
      id: 'trade_${signing2.id}_${DateTime.now().millisecondsSinceEpoch}',
      personId: personId2,
      teamId: team1Id,
      price: signing2.price,
      type: SigningType.trade,
      timestamp: DateTime.now(),
    ));

    final p1Name = people.firstWhere((p) => p.id == personId1).name;
    final p2Name = people.firstWhere((p) => p.id == personId2).name;

    _logAudit('Trade', 'Player Trade', 'Traded $p1Name and $p2Name between teams.');
    notifyListeners();
  }

  // --- Match Day & Attendance Balancing ---

  void setTargetSquadSizePerSide(int newSize) {
    targetSquadSizePerSide = newSize;
    _logAudit('Match-Day', 'Squad Size Updated', 'Target match size changed to $newSize per side.');
    notifyListeners();
  }

  void updateAttendance(int matchNumber, String personId, AttendanceStatus status) {
    if (!attendanceMap.containsKey(personId)) {
      attendanceMap[personId] = {};
    }
    attendanceMap[personId]![matchNumber] = status;
    notifyListeners();
  }

  AttendanceStatus getAttendance(int matchNumber, String personId) {
    return attendanceMap[personId]?[matchNumber] ?? AttendanceStatus.inStatus;
  }

  void generateMatchRoster(int matchNumber) {
    final rohanAvailable = _getAvailableForTeam(matchNumber, 'team_rohan');
    final saurabhAvailable = _getAvailableForTeam(matchNumber, 'team_saurabh');

    int rohanCount = rohanAvailable.length;
    int saurabhCount = saurabhAvailable.length;

    int targetPerSide = min(rohanCount, saurabhCount);
    if (targetPerSide > targetSquadSizePerSide) targetPerSide = targetSquadSizePerSide;

    final newRoster = <RosterEntry>[];

    _processTeamRoster(
      matchNumber: matchNumber,
      teamId: 'team_rohan',
      available: rohanAvailable,
      targetPlayingCount: targetPerSide,
      outEntries: newRoster,
    );

    _processTeamRoster(
      matchNumber: matchNumber,
      teamId: 'team_saurabh',
      available: saurabhAvailable,
      targetPlayingCount: targetPerSide,
      outEntries: newRoster,
    );

    matchRosters[matchNumber] = newRoster;
    _logAudit('Match-Day', 'Roster Generated', 'Match #$matchNumber roster generated. $targetPerSide-a-side match.');
    notifyListeners();
  }

  List<Person> _getAvailableForTeam(int matchNumber, String teamId) {
    final teamPeople = [
      ...people.where((p) => p.role == PersonRole.owner && (teamId == 'team_rohan' ? p.id == 'rohan' : p.id == 'saurabh')),
      ...getTeamPlayers(teamId),
    ];

    return teamPeople.where((p) {
      if (p.status != PersonStatus.active) return false;
      final att = getAttendance(matchNumber, p.id);
      return att == AttendanceStatus.inStatus;
    }).toList();
  }

  void _processTeamRoster({
    required int matchNumber,
    required String teamId,
    required List<Person> available,
    required int targetPlayingCount,
    required List<RosterEntry> outEntries,
  }) {
    final owner = available.firstWhere((p) => p.role == PersonRole.owner, orElse: () => Person(id: '', name: '', role: PersonRole.owner));
    final nonOwnerAvailable = available.where((p) => p.role != PersonRole.owner).toList();

    int playingNeeded = targetPlayingCount;
    if (owner.id.isNotEmpty) {
      outEntries.add(RosterEntry(
        matchNumber: matchNumber,
        personId: owner.id,
        teamId: teamId,
        role: MatchRosterRole.playing,
      ));
      playingNeeded--;
    }

    nonOwnerAvailable.sort((a, b) {
      final aCount = sitOutCounts[a.id] ?? 0;
      final bCount = sitOutCounts[b.id] ?? 0;
      return aCount.compareTo(bCount);
    });

    int commonPlayersCount = 0;

    for (int i = 0; i < nonOwnerAvailable.length; i++) {
      final person = nonOwnerAvailable[i];

      if (i < playingNeeded) {
        outEntries.add(RosterEntry(
          matchNumber: matchNumber,
          personId: person.id,
          teamId: teamId,
          role: MatchRosterRole.playing,
        ));
      } else if (commonPlayersCount < 2) {
        commonPlayersCount++;
        outEntries.add(RosterEntry(
          matchNumber: matchNumber,
          personId: person.id,
          teamId: teamId,
          role: MatchRosterRole.common,
        ));
      } else {
        outEntries.add(RosterEntry(
          matchNumber: matchNumber,
          personId: person.id,
          teamId: teamId,
          role: MatchRosterRole.sitout,
        ));
        sitOutCounts[person.id] = (sitOutCounts[person.id] ?? 0) + 1;
      }
    }
  }

  void _logAudit(String actor, String action, String details) {
    auditLogs.add(AuditLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      actor: actor,
      action: action,
      details: details,
      timestamp: DateTime.now(),
    ));
  }
}
