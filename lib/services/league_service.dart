import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/league.dart';

class LeagueService extends ChangeNotifier {
  // Config constants
  static const int totalPursePerTeam = 10000;
  static const int matchesPlanned = 5;

  // 20 Official Base Players
  static const List<String> defaultPoolNames = [
    'Aditya',
    'Ritesh',
    'Avinash',
    'Priyam',
    'Saurabh',
    'Sangam',
    'Satish',
    'Pawan',
    'Niranjan',
    'Aashish',
    'Alok',
    'Amit',
    'Aman',
    'Shubham',
    'Dev',
    'Tinku',
    'Sunny',
    'Rahul',
    'Ikchit',
    'Mohan',
  ];

  // Default Marquee Players (Base Price ₹500)
  static const Set<String> defaultMarqueeNames = {
    'sangam',
    'sunny',
    'priyam',
    'rahul',
    'aditya',
  };

  // Match settings
  int targetSquadSizePerSide = 10; // Default 10 per side, adjustable

  // Captains & Team Names Configuration
  String _captain1Name = 'Saurabh';
  String _captain2Name = 'Avinash';
  String? _customTeam1Name;
  String? _customTeam2Name;

  String get captain1Name => _captain1Name;
  String get captain2Name => _captain2Name;
  String? get customTeam1Name => _customTeam1Name;
  String? get customTeam2Name => _customTeam2Name;

  // RTM Cards (1 per team)
  int team1RtmLeft = 1;
  int team2RtmLeft = 1;

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
    // 1. Matches
    matches.clear();
    final now = DateTime.now();
    for (int i = 1; i <= matchesPlanned; i++) {
      matches.add(CricketMatch(
        number: i,
        date: now.add(Duration(days: 6 * i)),
      ));
    }

    // 2. Setup Teams & Prefill Player Pool
    resetAuction();

    _logAudit('System', 'Initialization', 'Auction initialized with Captains $_captain1Name & $_captain2Name.');
  }

  void _prefillPlayerPool() {
    people.clear();
    signings.clear();
    refunds.clear();
    teams.clear();
    selectedAuctionPerson = null;
    pendingRtmPerson = null;
    team1RtmLeft = 1;
    team2RtmLeft = 1;

    final cap1Id = _captain1Name.toLowerCase().replaceAll(' ', '_');
    final cap2Id = _captain2Name.toLowerCase().replaceAll(' ', '_');

    // 1. Create Teams
    final t1Name = _customTeam1Name?.isNotEmpty == true ? _customTeam1Name! : 'Team $_captain1Name';
    final t2Name = _customTeam2Name?.isNotEmpty == true ? _customTeam2Name! : 'Team $_captain2Name';

    teams.add(TeamData(
      id: 'team_1',
      name: t1Name,
      ownerPersonId: cap1Id,
      ownerName: _captain1Name,
    ));
    teams.add(TeamData(
      id: 'team_2',
      name: t2Name,
      ownerPersonId: cap2Id,
      ownerName: _captain2Name,
    ));

    // 2. Add Owners to People
    people.add(Person(id: cap1Id, name: _captain1Name, role: PersonRole.owner, status: PersonStatus.active));
    people.add(Person(id: cap2Id, name: _captain2Name, role: PersonRole.owner, status: PersonStatus.active));

    attendanceMap[cap1Id] = {for (int m = 1; m <= matchesPlanned; m++) m: AttendanceStatus.inStatus};
    attendanceMap[cap2Id] = {for (int m = 1; m <= matchesPlanned; m++) m: AttendanceStatus.inStatus};
    sitOutCounts[cap1Id] = 0;
    sitOutCounts[cap2Id] = 0;

    // 3. Add regular players from default pool (excluding the 2 captains)
    for (final name in defaultPoolNames) {
      if (name.toLowerCase() == _captain1Name.toLowerCase() || name.toLowerCase() == _captain2Name.toLowerCase()) {
        continue; // Owners do not go into auction pool
      }

      final id = name.toLowerCase().replaceAll(' ', '_');
      final isMarquee = defaultMarqueeNames.contains(id);

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
  }

  // --- Setup & Captain Changer ---

  void initializeSetup(
    String cap1,
    String cap2, {
    String? customTeam1Name,
    String? customTeam2Name,
  }) {
    _captain1Name = cap1;
    _captain2Name = cap2;
    _customTeam1Name = customTeam1Name;
    _customTeam2Name = customTeam2Name;

    resetAuction();
    _logAudit('Admin', 'League Setup Initialized', 'Captains: $cap1 & $cap2. Teams: ${_customTeam1Name ?? "Team $cap1"} & ${_customTeam2Name ?? "Team $cap2"}.');
    notifyListeners();
  }

  void setCaptains(String cap1, String cap2, {String? team1Name, String? team2Name}) {
    _captain1Name = cap1;
    _captain2Name = cap2;
    _customTeam1Name = team1Name;
    _customTeam2Name = team2Name;

    resetAuction();
    _logAudit('Admin', 'Captains Changed', 'Team Captains updated to $cap1 and $cap2.');
    notifyListeners();
  }

  // --- Helper ID Resolvers ---

  String _resolveTeamId(String teamId) {
    if (teams.isNotEmpty && teamId == teams[0].id) return teams[0].id;
    if (teams.length > 1 && teamId == teams[1].id) return teams[1].id;
    if (teamId == 'team_1' || teamId.contains('rohan') || (teamId.contains('avinash') && !teamId.contains('saurabh'))) {
      return teams.isNotEmpty ? teams[0].id : 'team_1';
    }
    if (teamId == 'team_2' || teamId.contains('saurabh')) {
      return teams.length > 1 ? teams[1].id : 'team_2';
    }
    return teamId;
  }

  String _getTeamDisplayName(String teamId) {
    final match = teams.where((t) => t.id == teamId).toList();
    if (match.isNotEmpty) return match.first.name;
    if (teamId == 'team_1' && teams.isNotEmpty) return teams[0].name;
    if (teamId == 'team_2' && teams.length > 1) return teams[1].name;
    return teamId;
  }

  // --- Calculations ---

  int getTeamSpend(String teamId) {
    int total = 0;
    final resolved = _resolveTeamId(teamId);
    for (final s in signings.where((s) => s.teamId == teamId || _resolveTeamId(s.teamId) == resolved)) {
      total += s.price;
    }
    for (final r in refunds.where((r) => r.teamId == teamId || _resolveTeamId(r.teamId) == resolved)) {
      total -= r.amount;
    }
    return total;
  }

  int getTeamPurseLeft(String teamId) {
    return totalPursePerTeam - getTeamSpend(teamId);
  }

  List<Person> getTeamPlayers(String teamId) {
    final resolved = _resolveTeamId(teamId);
    final activeSignings = signings
        .where((s) => s.teamId == teamId || _resolveTeamId(s.teamId) == resolved)
        .map((s) => s.personId)
        .toSet();
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
    if (teams.isNotEmpty && teamId == teams[0].id) return team1RtmLeft;
    if (teams.length > 1 && teamId == teams[1].id) return team2RtmLeft;
    if (teamId == 'team_1' || teamId.contains('rohan')) return team1RtmLeft;
    if (teamId == 'team_2' || teamId.contains('saurabh')) return team2RtmLeft;
    return team1RtmLeft;
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

    final defaultMatching = (teams.length > 1 && sellingTeamId == teams[0].id) ? teams[1].id : (teams.isNotEmpty ? teams[0].id : 'team_2');
    final targetMatchingTeamId = matchingTeamId ?? defaultMatching;

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

    if (teamId == 'team_1' || (teams.isNotEmpty && teamId == teams[0].id)) {
      team1RtmLeft--;
    } else {
      team2RtmLeft--;
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

    final teamName = _getTeamDisplayName(teamId);
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

    final teamName = _getTeamDisplayName(teamId);
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

    final teamName = _getTeamDisplayName(teamId);
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
    if (teams.length < 2) return 'team_1';
    final t1Id = teams[0].id;
    final t2Id = teams[1].id;

    final t1Bought = getBoughtCount(t1Id);
    final t2Bought = getBoughtCount(t2Id);

    if (t1Bought < t2Bought) return t1Id;
    if (t2Bought < t1Bought) return t2Id;

    final t1Value = getTeamSpend(t1Id);
    final t2Value = getTeamSpend(t2Id);

    if (t1Value < t2Value) return t1Id;
    if (t2Value < t1Value) return t2Id;

    return Random().nextBool() ? t1Id : t2Id;
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

    final teamName = _getTeamDisplayName(assignedTeamId);
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

    final teamName = _getTeamDisplayName(signing.teamId);
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
    if (teams.isEmpty) return;
    final t1Id = teams[0].id;
    final t2Id = teams.length > 1 ? teams[1].id : 'team_2';

    final team1Available = _getAvailableForTeam(matchNumber, t1Id);
    final team2Available = _getAvailableForTeam(matchNumber, t2Id);

    int t1Count = team1Available.length;
    int t2Count = team2Available.length;

    int targetPerSide = min(t1Count, t2Count);
    if (targetPerSide > targetSquadSizePerSide) targetPerSide = targetSquadSizePerSide;

    final newRoster = <RosterEntry>[];

    _processTeamRoster(
      matchNumber: matchNumber,
      teamId: t1Id,
      available: team1Available,
      targetPlayingCount: targetPerSide,
      outEntries: newRoster,
    );

    _processTeamRoster(
      matchNumber: matchNumber,
      teamId: t2Id,
      available: team2Available,
      targetPlayingCount: targetPerSide,
      outEntries: newRoster,
    );

    matchRosters[matchNumber] = newRoster;
    _logAudit('Match-Day', 'Roster Generated', 'Match #$matchNumber roster generated. $targetPerSide-a-side match.');
    notifyListeners();
  }

  List<Person> _getAvailableForTeam(int matchNumber, String teamId) {
    final teamMatch = teams.where((t) => t.id == teamId).toList();
    final ownerId = teamMatch.isNotEmpty ? teamMatch.first.ownerPersonId : '';
    final teamPeople = [
      ...people.where((p) => p.role == PersonRole.owner && p.id == ownerId),
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
