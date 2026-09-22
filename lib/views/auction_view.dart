import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/league.dart';
import '../services/league_provider.dart';
import '../services/league_service.dart';

class AuctionView extends StatefulWidget {
  const AuctionView({super.key});

  @override
  State<AuctionView> createState() => _AuctionViewState();
}

class _AuctionViewState extends State<AuctionView> with TickerProviderStateMixin {
  int _currentPrice = 100;
  String? _leadingTeamId; // 'team_rohan', 'team_saurabh', or null
  String? _lastSelectedPersonId;

  // Animation controller for bid action (hammer strike / hand raise)
  late AnimationController _bidAnimController;
  String? _animatingTeamId; // team that just placed bid
  int _animatingIncrement = 100;

  // 40-second Bidding Timer state (30s inactive warning)
  Timer? _biddingTimer;
  int _secondsRemaining = 40;
  bool _isTimerPaused = false;

  @override
  void initState() {
    super.initState();
    _bidAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _biddingTimer?.cancel();
    _bidAnimController.dispose();
    super.dispose();
  }

  void _startBiddingTimer() {
    _biddingTimer?.cancel();
    setState(() {
      _secondsRemaining = 40;
      _isTimerPaused = false;
    });

    _biddingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isTimerPaused) return;

      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _handleTimerExpired();
      }
    });
  }

  void _resetBiddingTimer() {
    _startBiddingTimer();
  }

  void _pauseBiddingTimer() {
    setState(() {
      _isTimerPaused = true;
    });
  }

  void _resumeBiddingTimer() {
    setState(() {
      _isTimerPaused = false;
    });
  }

  void _cancelBiddingTimer() {
    _biddingTimer?.cancel();
    _biddingTimer = null;
  }

  void _handleTimerExpired() {
    final service = Provider.of<LeagueService>(context);
    final selectedPerson = service.selectedAuctionPerson;
    if (selectedPerson == null) return;

    if (_leadingTeamId != null) {
      _handleSell(context, service, selectedPerson, _leadingTeamId!, _currentPrice);
    } else {
      service.markSelectedPlayerUnsold();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏱️ 40s Timer Expired! ${selectedPerson.name} marked unsold.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _lastSelectedPersonId = null;
          _leadingTeamId = null;
        });
      }
    }
  }

  void _checkAndSyncPlayerState(Person? selectedPerson) {
    if (selectedPerson == null) {
      if (_lastSelectedPersonId != null) {
        _lastSelectedPersonId = null;
        _leadingTeamId = null;
        _cancelBiddingTimer();
      }
      return;
    }

    if (_lastSelectedPersonId != selectedPerson.id) {
      _lastSelectedPersonId = selectedPerson.id;
      _currentPrice = selectedPerson.basePrice;
      _leadingTeamId = null;
      _startBiddingTimer(); // Start 40-second timer when player is added to auction arena
    }
  }

  int getNextBidIncrement(int price) {
    if (price < 500) {
      return 100;
    } else if (price < 2000) {
      return 250;
    } else {
      return 500;
    }
  }

  int getNextBidPrice(int currentPrice, String? leadingTeamId) {
    if (leadingTeamId == null) {
      return currentPrice;
    }
    return currentPrice + getNextBidIncrement(currentPrice);
  }

  void _placeBid(String teamId, int nextPrice, bool isOpening) {
    setState(() {
      _currentPrice = nextPrice;
      _leadingTeamId = teamId;
      _animatingTeamId = teamId;
      _animatingIncrement = isOpening ? nextPrice : getNextBidIncrement(nextPrice - getNextBidIncrement(nextPrice));
    });

    _resetBiddingTimer(); // Reset 40-second timer on every bid raise
    _bidAnimController.forward(from: 0.0);
  }

  void _handleSell(BuildContext context, LeagueService service, Person person, String teamId, int price) {
    _cancelBiddingTimer();
    final team = service.teams.firstWhere((t) => t.id == teamId);

    _showSoldCelebrationDialog(context, person, team, price, isRtm: false).then((_) {
      service.sellSelectedPlayer(teamId, price);
      setState(() {
        _lastSelectedPersonId = null;
        _leadingTeamId = null;
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    final service = Provider.of<LeagueService>(context);
    final pendingPlayers = service.people.where((p) => p.status == PersonStatus.pending).toList();
    final selectedPerson = service.selectedAuctionPerson;

    _checkAndSyncPlayerState(selectedPerson);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Arena'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bidding Arena Spotlight Box
            if (service.pendingRtmPerson != null) ...[
              _RtmSpotlightCard(service: service),
              const SizedBox(height: 20),
            ] else if (selectedPerson != null) ...[
              _buildSpotlightSaleCard(context, service, selectedPerson),
              const SizedBox(height: 20),
            ],

            // Player Pool Selection Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.gavel_rounded, color: Color(0xFF0D2A20), size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Unassigned Auction Pool",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${pendingPlayers.length} Left',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap any player below to place them on the auction block.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    pendingPlayers.isEmpty
                        ? Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('🎉 All players in the pool have been sold!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D2A20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                                label: const Text('Add New Player to Pool', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () => _showAddNewPlayerDialog(context, service),
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...pendingPlayers.map((person) {
                                final isSelected = selectedPerson?.id == person.id;
                                final isMarquee = person.category == PlayerCategory.marquee;

                                return ChoiceChip(
                                  avatar: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? Colors.white
                                        : (isMarquee ? const Color(0xFFD97706) : const Color(0xFF0D2A20)),
                                    child: Icon(
                                      isMarquee ? Icons.star_rounded : Icons.person_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  label: Text(
                                    '${person.name} (₹${person.basePrice})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF0D2A20),
                                  onSelected: (val) {
                                    if (val) {
                                      service.selectPlayerForAuction(person);
                                      setState(() {
                                        _lastSelectedPersonId = person.id;
                                        _currentPrice = person.basePrice;
                                        _leadingTeamId = null;
                                      });
                                    }
                                  },
                                );
                              }),
                              ActionChip(
                                avatar: const CircleAvatar(
                                  backgroundColor: Color(0xFF0D2A20),
                                  child: Icon(Icons.add_rounded, size: 14, color: Colors.white),
                                ),
                                label: const Text('+ Add Player', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0D2A20))),
                                onPressed: () => _showAddNewPlayerDialog(context, service),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Sold History Feed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5)),
            const SizedBox(height: 8),

            // Recent Signings Feed
            service.signings.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text('No players sold yet.', style: TextStyle(color: Color(0xFF64748B)))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: service.signings.length,
                    itemBuilder: (context, index) {
                      final signing = service.signings.reversed.toList()[index];
                      final person = service.people.firstWhere((p) => p.id == signing.personId);
                      final team = service.teams.firstWhere((t) => t.id == signing.teamId);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: signing.type == SigningType.rtm ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              signing.type == SigningType.rtm ? Icons.verified_rounded : Icons.check_circle_rounded,
                              size: 18,
                              color: signing.type == SigningType.rtm ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                            ),
                          ),
                          title: Text(
                            '${person.name} → ${team.name} ${signing.type == SigningType.rtm ? "(RTM)" : ""}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 13),
                          ),
                          subtitle: Text('${person.category.label} • ${signing.type.name.toUpperCase()}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2A20).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₹${signing.price}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0D2A20)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotlightSaleCard(BuildContext context, LeagueService service, Person person) {
    final rohanMax = service.getMaxBidAllowed('team_rohan');
    final saurabhMax = service.getMaxBidAllowed('team_saurabh');

    final rohanRtm = service.getRtmCardsLeft('team_rohan');
    final saurabhRtm = service.getRtmCardsLeft('team_saurabh');

    final isMarquee = person.category == PlayerCategory.marquee;

    final rohanNextPrice = getNextBidPrice(_currentPrice, _leadingTeamId);
    final saurabhNextPrice = getNextBidPrice(_currentPrice, _leadingTeamId);

    final isRohanLeading = _leadingTeamId == 'team_rohan';
    final isSaurabhLeading = _leadingTeamId == 'team_saurabh';

    final rohanCanBid = !isRohanLeading && (rohanMax >= rohanNextPrice);
    final saurabhCanBid = !isSaurabhLeading && (saurabhMax >= saurabhNextPrice);

    final currentIncrement = getNextBidIncrement(_currentPrice);

    final leadingTeamName = isRohanLeading ? 'Team Rohan' : (isSaurabhLeading ? 'Team Saurabh' : '');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2A20), Color(0xFF164E3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D2A20).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Animated Timer Bar (40s Total)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: LinearProgressIndicator(
              value: (_secondsRemaining / 40.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _secondsRemaining <= 10 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Top Badge & Close Button & Timer Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMarquee ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isMarquee ? Icons.stars_rounded : Icons.person_rounded,
                            size: 14,
                            color: isMarquee ? Colors.black87 : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${person.category.label.toUpperCase()} • BASE ₹${person.basePrice}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isMarquee ? Colors.black87 : Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 40-SECOND CLOCK BADGE & PLAY/PAUSE/RESET CONTROLS
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _secondsRemaining <= 10
                            ? const Color(0xFFEF4444)
                            : Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _secondsRemaining <= 10 ? Colors.white : Colors.white30,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _secondsRemaining <= 10 ? Icons.alarm_on_rounded : Icons.timer_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _secondsRemaining <= 10
                                ? '⏰ 30s+ NO BID! 00:${_secondsRemaining.toString().padLeft(2, '0')}'
                                : '⏱️ 40s Timer: 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              if (_isTimerPaused) {
                                _resumeBiddingTimer();
                              } else {
                                _pauseBiddingTimer();
                              }
                            },
                            child: Icon(
                              _isTimerPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 2),
                          GestureDetector(
                            onTap: _resetBiddingTimer,
                            child: const Icon(Icons.replay_rounded, size: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                      onPressed: () {
                        _cancelBiddingTimer();
                        service.selectedAuctionPerson = null;
                        setState(() {
                          _lastSelectedPersonId = null;
                          _leadingTeamId = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Person Avatar Display
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: isMarquee ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // Player Name
                Text(
                  person.name,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                ),
                const Text(
                  'LIVE ON AUCTION BLOCK',
                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 16),

                // 30-SECOND INACTIVITY ALERT BANNER (Triggers when >30s elapsed with no bid raise)
                if (_secondsRemaining <= 10) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _leadingTeamId != null
                                ? '⚠️ GOING ONCE... GOING TWICE! No bid raise for 30s! Auto-selling to $leadingTeamName in ${_secondsRemaining}s...'
                                : '⚠️ NO BIDS FOR 30s! Closing in ${_secondsRemaining}s (Player will go UNSOLD)...',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Center Spotlight Display: CURRENT HIGHEST BID & LEADING TEAM
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('CURRENT BID PRICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Text(
                          '₹$_currentPrice',
                          key: ValueKey(_currentPrice),
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF0D2A20), letterSpacing: -1),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Leading Team Pill & Rule Tag
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRohanLeading
                                  ? const Color(0xFFFEF3C7)
                                  : (isSaurabhLeading ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isRohanLeading
                                    ? const Color(0xFFF59E0B)
                                    : (isSaurabhLeading ? const Color(0xFF10B981) : Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _leadingTeamId != null ? Icons.workspace_premium_rounded : Icons.pending_rounded,
                                  size: 14,
                                  color: isRohanLeading
                                      ? const Color(0xFFD97706)
                                      : (isSaurabhLeading ? const Color(0xFF16A34A) : Colors.grey.shade600),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isRohanLeading
                                      ? '👑 TEAM ROHAN LEADING'
                                      : (isSaurabhLeading ? '👑 TEAM SAURABH LEADING' : '⚡ AWAITING FIRST BID'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: isRohanLeading
                                        ? const Color(0xFFB45309)
                                        : (isSaurabhLeading ? const Color(0xFF15803D) : const Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2A20).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Next Rule: +₹$currentIncrement',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0D2A20)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // DUAL SIDE BIDDING ARENA (Rohan Left | Saurabh Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TEAM ROHAN SIDE (LEFT)
                    Expanded(
                      child: _buildTeamBiddingSide(
                        context: context,
                        service: service,
                        teamId: 'team_rohan',
                        teamName: 'Team Rohan',
                        accentColor: const Color(0xFFF59E0B),
                        maxAllowed: rohanMax,
                        currentPrice: _currentPrice,
                        nextBidPrice: rohanNextPrice,
                        isLeading: isRohanLeading,
                        canBid: rohanCanBid,
                        rtmLeft: rohanRtm,
                        onBidPressed: () {
                          final isOpening = _leadingTeamId == null;
                          _placeBid('team_rohan', rohanNextPrice, isOpening);
                        },
                        onSellPressed: () {
                          _handleSell(context, service, person, 'team_rohan', _currentPrice);
                        },
                        onRtmPressed: () {
                          _cancelBiddingTimer();
                          service.initiateRtmCheck('team_saurabh', _currentPrice, matchingTeamId: 'team_rohan');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // TEAM SAURABH SIDE (RIGHT)
                    Expanded(
                      child: _buildTeamBiddingSide(
                        context: context,
                        service: service,
                        teamId: 'team_saurabh',
                        teamName: 'Team Saurabh',
                        accentColor: const Color(0xFF10B981),
                        maxAllowed: saurabhMax,
                        currentPrice: _currentPrice,
                        nextBidPrice: saurabhNextPrice,
                        isLeading: isSaurabhLeading,
                        canBid: saurabhCanBid,
                        rtmLeft: saurabhRtm,
                        onBidPressed: () {
                          final isOpening = _leadingTeamId == null;
                          _placeBid('team_saurabh', saurabhNextPrice, isOpening);
                        },
                        onSellPressed: () {
                          _handleSell(context, service, person, 'team_saurabh', _currentPrice);
                        },
                        onRtmPressed: () {
                          _cancelBiddingTimer();
                          service.initiateRtmCheck('team_rohan', _currentPrice, matchingTeamId: 'team_saurabh');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextButton.icon(
                  icon: const Icon(Icons.replay_rounded, color: Colors.redAccent, size: 18),
                  label: const Text('Mark Unsold (Back to Pool)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    _cancelBiddingTimer();
                    service.markSelectedPlayerUnsold();
                    setState(() {
                      _lastSelectedPersonId = null;
                      _leadingTeamId = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBiddingSide({
    required BuildContext context,
    required LeagueService service,
    required String teamId,
    required String teamName,
    required Color accentColor,
    required int maxAllowed,
    required int currentPrice,
    required int nextBidPrice,
    required bool isLeading,
    required bool canBid,
    required int rtmLeft,
    required VoidCallback onBidPressed,
    required VoidCallback onSellPressed,
    required VoidCallback onRtmPressed,
  }) {
    final canAffordSell = maxAllowed >= currentPrice && (_leadingTeamId == teamId || _leadingTeamId == null);
    final canUseRtm = rtmLeft > 0 && maxAllowed >= currentPrice;
    final isAnimatingThisTeam = _animatingTeamId == teamId && _bidAnimController.isAnimating;

    final incrementAmount = _animatingIncrement;

    return Column(
      children: [
        // Reserve Meter Chip
        _buildSpotlightReserveChip(teamName, maxAllowed, currentPrice),
        const SizedBox(height: 8),

        // Animated Bid Gavel / Hand Raised Widget (Stack over Bid Button)
        Stack(
          clipBehavior: Clip.none,
          children: [
            // DEDICATED SIDE BID BUTTON
            SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLeading ? accentColor.withValues(alpha: 0.2) : accentColor,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: isLeading ? accentColor : Colors.black87,
                  elevation: isLeading ? 0 : 4,
                  shadowColor: accentColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isLeading ? accentColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                onPressed: canBid ? onBidPressed : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLeading) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: accentColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'LEADING BID',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: accentColor, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      Text(
                        '₹$currentPrice',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: accentColor),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.back_hand_rounded, size: 16),
                          const SizedBox(width: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _leadingTeamId == null ? 'OPEN BID' : 'BID NEXT',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₹$nextBidPrice',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Animated Hand/Gavel Pop-up
            if (isAnimatingThisTeam)
              Positioned(
                top: -36,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _bidAnimController,
                  builder: (context, child) {
                    final progress = _bidAnimController.value;
                    final scale = sin(progress * pi) * 1.4;
                    final translateY = -30 * progress;
                    final opacity = (1.0 - progress).clamp(0.0, 1.0);

                    return Transform.translate(
                      offset: Offset(0, translateY),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.back_hand_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+₹$incrementAmount',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // SELL BUTTON FOR THIS TEAM
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canAffordSell ? accentColor : Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: canAffordSell ? onSellPressed : null,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'SELL FOR ₹$currentPrice',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // RTM BUTTON FOR THIS TEAM
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: canUseRtm ? accentColor : Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(Icons.verified_rounded, size: 14, color: canUseRtm ? accentColor : Colors.grey),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'RTM ($rtmLeft left)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: canUseRtm ? Colors.white : Colors.grey),
              ),
            ),
            onPressed: canUseRtm ? onRtmPressed : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSpotlightReserveChip(String label, int maxAllowed, int currentPrice, {bool isDark = false}) {
    final canAfford = maxAllowed >= currentPrice;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: canAfford ? const Color(0xFF10B981) : Colors.redAccent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            canAfford ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 12,
            color: canAfford ? const Color(0xFF10B981) : Colors.redAccent,
          ),
          const SizedBox(width: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$label: ₹$maxAllowed',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.black87 : Colors.white),
            ),
          ),
        ],
      ),
    );
  }


  void _showAddNewPlayerDialog(BuildContext context, LeagueService service) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddNewPlayerDialog(service: service),
    );
  }

  Future<void> _showSoldCelebrationDialog(
    BuildContext context,
    Person person,
    TeamData team,
    int price, {
    required bool isRtm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SoldCelebrationDialog(
        person: person,
        team: team,
        price: price,
        isRtm: isRtm,
      ),
    );
  }
}

// --- PURCHASE DONE ("SOLD!") CELEBRATION DIALOG WITH CONFETTI & GAVEL HIT ---
class _SoldCelebrationDialog extends StatefulWidget {
  final Person person;
  final TeamData team;
  final int price;
  final bool isRtm;

  const _SoldCelebrationDialog({
    required this.person,
    required this.team,
    required this.price,
    required this.isRtm,
  });

  @override
  State<_SoldCelebrationDialog> createState() => _SoldCelebrationDialogState();
}

class _SoldCelebrationDialogState extends State<_SoldCelebrationDialog> with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _gavelController;
  late Animation<double> _scaleAnim;
  late Animation<double> _gavelRotateAnim;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    _gavelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = CurvedAnimation(parent: _gavelController, curve: Curves.elasticOut);
    _gavelRotateAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.6, end: 0.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.0), weight: 50),
    ]).animate(_gavelController);

    _gavelController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _gavelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRohan = widget.team.id == 'team_rohan';
    final teamColor = isRohan ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti Particle Layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConfettiPainter(progress: _confettiController.value),
                );
              },
            ),
          ),

          // Main Card
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D2A20), Color(0xFF1E3A2F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: teamColor.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(color: teamColor, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Hammer Gavel
                  AnimatedBuilder(
                    animation: _gavelRotateAnim,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _gavelRotateAnim.value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: teamColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: teamColor, width: 2),
                          ),
                          child: Icon(
                            widget.isRtm ? Icons.verified_rounded : Icons.gavel_rounded,
                            size: 48,
                            color: teamColor,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // SOLD BANNER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: teamColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.isRtm ? '🎉 CLAIMED VIA RTM! 🎉' : '🔨 SOLD! SOLD! SOLD! 🔨',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PLAYER NAME
                  Text(
                    widget.person.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${widget.person.category.label.toUpperCase()} CATEGORY',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // WINNING TEAM & FINAL PRICE CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('BUYING TEAM', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              widget.team.name,
                              style: TextStyle(color: teamColor, fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                          ],
                        ),
                        Container(height: 30, width: 1, color: Colors.white24),
                        Column(
                          children: [
                            const Text('FINAL PRICE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              '₹${widget.price}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // DISMISS BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teamColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'CONTINUE TO NEXT PLAYER 🚀',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CONFETTI PAINTER FOR CELEBRATION ---
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> _particles;

  _ConfettiPainter({required this.progress})
      : _particles = List.generate(40, (index) {
          final random = Random(index);
          return _ConfettiParticle(
            x: random.nextDouble(),
            y: random.nextDouble(),
            size: random.nextDouble() * 8 + 4,
            color: [
              const Color(0xFFF59E0B),
              const Color(0xFF10B981),
              const Color(0xFFEC4899),
              const Color(0xFF3B82F6),
              const Color(0xFF8B5CF6),
            ][random.nextInt(5)],
            speed: random.nextDouble() * 0.8 + 0.4,
            rotation: random.nextDouble() * 2 * pi,
          );
        });

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in _particles) {
      final currentY = (p.y + progress * p.speed) % 1.0 * size.height;
      final currentX = p.x * size.width + sin(progress * 4 + p.rotation) * 20;

      final paint = Paint()
        ..color = p.color.withValues(alpha: (1.0 - (currentY / size.height)).clamp(0.2, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.rotation + progress * 3);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final double rotation;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.rotation,
  });
}

class _AddNewPlayerDialog extends StatefulWidget {
  final LeagueService service;

  const _AddNewPlayerDialog({required this.service});

  @override
  State<_AddNewPlayerDialog> createState() => _AddNewPlayerDialogState();
}

class _AddNewPlayerDialogState extends State<_AddNewPlayerDialog> {
  final nameController = TextEditingController();
  PlayerCategory selectedCategory = PlayerCategory.normal;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add New Player to Pool', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Player Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Player Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: PlayerCategory.values.map((cat) {
              return ChoiceChip(
                label: Text('${cat.label} (Base ₹${cat.basePrice})', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                selected: selectedCategory == cat,
                selectedColor: const Color(0xFF0D2A20).withValues(alpha: 0.2),
                onSelected: (val) {
                  if (val) setState(() => selectedCategory = cat);
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D2A20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              widget.service.addPersonToPool(name, selectedCategory);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name added to pool.')),
              );
            }
          },
          child: const Text('Add to Pool', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// --- RISHABH PANT-STYLE 2-STAGE RTM SPOTLIGHT CARD ---
class _RtmSpotlightCard extends StatefulWidget {
  final LeagueService service;

  const _RtmSpotlightCard({required this.service});

  @override
  State<_RtmSpotlightCard> createState() => _RtmSpotlightCardState();
}

class _RtmSpotlightCardState extends State<_RtmSpotlightCard> {
  late int _increasedPrice;

  @override
  void initState() {
    super.initState();
    _increasedPrice = widget.service.pendingRtmPrice;
  }

  @override
  void didUpdateWidget(covariant _RtmSpotlightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.service.pendingRtmPrice != oldWidget.service.pendingRtmPrice) {
      _increasedPrice = widget.service.pendingRtmPrice;
    }
  }

  Future<void> _showCelebration(Person person, TeamData team, int price, bool isRtm) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SoldCelebrationDialog(
        person: person,
        team: team,
        price: price,
        isRtm: isRtm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final person = service.pendingRtmPerson;
    if (person == null) return const SizedBox.shrink();

    final sellingTeamId = service.pendingRtmSourceTeamId;
    final sellingTeam = service.teams.firstWhere((t) => t.id == sellingTeamId);

    final matchingTeamId = service.pendingRtmMatchingTeamId!;
    final matchingTeam = service.teams.firstWhere((t) => t.id == matchingTeamId);

    final sellingTeamMax = service.getMaxBidAllowed(sellingTeamId);
    final matchingTeamMax = service.getMaxBidAllowed(matchingTeamId);
    final basePrice = service.pendingRtmPrice;
    final stage = service.pendingRtmStage;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        stage == RtmStage.increaseBid ? 'RTM STEP 1: RAISE BID' : 'RTM STEP 2: MATCH OR DECLINE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.black87, size: 16),
                  ),
                  onPressed: () {
                    service.cancelRtmFlow();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${matchingTeam.name} exercised RTM on ${person.name}!',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Highest Auction Bid: ₹$basePrice by ${sellingTeam.name}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            if (stage == RtmStage.increaseBid) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${sellingTeam.name}\'s Final Bid Opportunity (₹Y)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFB45309), letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Team A can keep bid at base price or raise it up to Purse limit.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFFFEF3C7)),
                          icon: const Icon(Icons.remove_rounded, color: Colors.black87),
                          onPressed: _increasedPrice > basePrice
                              ? () {
                                  setState(() {
                                    _increasedPrice -= 100;
                                    if (_increasedPrice < basePrice) _increasedPrice = basePrice;
                                  });
                                }
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Text(
                            '₹$_increasedPrice',
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFFFEF3C7)),
                          icon: const Icon(Icons.add_rounded, color: Colors.black87),
                          onPressed: _increasedPrice + 100 <= sellingTeamMax
                              ? () {
                                  setState(() {
                                    _increasedPrice += 100;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  _increasedPrice > basePrice
                      ? 'RAISE BID TO ₹$_increasedPrice & ASK ${matchingTeam.name.toUpperCase()}'
                      : 'KEEP BID AT ₹$basePrice & ASK ${matchingTeam.name.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
                onPressed: () {
                  service.updateRtmIncreasedPrice(_increasedPrice);
                  service.setRtmStage(RtmStage.confirmMatch);
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${sellingTeam.name}\'s Final Bid: ₹${service.pendingRtmIncreasedPrice}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Will ${matchingTeam.name} match ₹${service.pendingRtmIncreasedPrice} to buy ${person.name}?',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RTM Cards Left for ${matchingTeam.name}: ${service.getRtmCardsLeft(matchingTeamId)} | Max Budget: ₹$matchingTeamMax',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final finalPrice = service.pendingRtmIncreasedPrice;
                        await _showCelebration(person, sellingTeam, finalPrice, false);
                        service.declineRtmMatch(finalPrice);
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'DECLINE\n(SELL TO ${sellingTeam.name.toUpperCase()} FOR ₹${service.pendingRtmIncreasedPrice})',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: matchingTeamMax >= service.pendingRtmIncreasedPrice && service.getRtmCardsLeft(matchingTeamId) > 0
                          ? () async {
                              final finalPrice = service.pendingRtmIncreasedPrice;
                              await _showCelebration(person, matchingTeam, finalPrice, true);
                              service.executeRtmMatch(finalPrice);
                            }
                          : null,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'MATCH RTM\n(BUY FOR ${matchingTeam.name.toUpperCase()} AT ₹${service.pendingRtmIncreasedPrice})',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    service.setRtmStage(RtmStage.increaseBid);
                  },
                  child: const Text('← Back to Change Raised Bid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

