import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ai_model_valuation.dart';
import '../services/solo_ai_auction_session.dart';

class SoloAiAuctionView extends StatefulWidget {
  const SoloAiAuctionView({super.key});

  @override
  State<SoloAiAuctionView> createState() => _SoloAiAuctionViewState();
}

class _SoloAiAuctionViewState extends State<SoloAiAuctionView> with SingleTickerProviderStateMixin {
  late final SoloAiAuctionSession _session;
  late final TabController _tabController;
  String _poolFilter = 'Available';
  bool _hasPromptedTeamName = false;

  @override
  void initState() {
    super.initState();
    _session = SoloAiAuctionSession();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasPromptedTeamName && mounted) {
        _hasPromptedTeamName = true;
        _showTeamNameDialog(context, isInitial: true);
      }
    });
  }

  @override
  void dispose() {
    _session.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F2),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D2A20),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                const _StayrareOwnerAvatar(size: 34, showBorder: true),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'stayrare-model 1v1',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
                    ),
                    Text(
                      'Solo Auction vs Rival AI Owner',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade300, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Sledge Audio Toggle (Stayrare Owner Trash Talk)
              ListenableBuilder(
                listenable: _session.voiceService,
                builder: (context, _) {
                  final sledgeEnabled = _session.voiceService.isSledgeAudioEnabled;
                  final voiceEnabled = _session.voiceService.isEnabled;
                  return IconButton(
                    icon: Icon(
                      sledgeEnabled ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
                      color: (!voiceEnabled)
                          ? Colors.white24
                          : (sledgeEnabled ? const Color(0xFFEF4444) : Colors.white38),
                    ),
                    tooltip: sledgeEnabled
                        ? 'Sledge Audio: ON (Tap to Mute AI Sledges)'
                        : 'Sledge Audio: OFF (Tap to Enable AI Sledges)',
                    onPressed: () {
                      _session.voiceService.toggleSledgeAudio();
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF1E293B),
                          content: Row(
                            children: [
                              Icon(
                                _session.voiceService.isSledgeAudioEnabled
                                    ? Icons.local_fire_department_rounded
                                    : Icons.volume_off_rounded,
                                color: _session.voiceService.isSledgeAudioEnabled
                                    ? const Color(0xFFEF4444)
                                    : Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _session.voiceService.isSledgeAudioEnabled
                                    ? 'Stayrare Owner Sledge Audio Enabled 🔥'
                                    : 'Stayrare Owner Sledge Audio Muted 🤫',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // Main Auctioneer Voice Toggle
              ListenableBuilder(
                listenable: _session.voiceService,
                builder: (context, _) {
                  final voiceEnabled = _session.voiceService.isEnabled;
                  final isSpeaking = _session.voiceService.isSpeaking;
                  return IconButton(
                    icon: Icon(
                      voiceEnabled
                          ? (isSpeaking ? Icons.record_voice_over_rounded : Icons.volume_up_rounded)
                          : Icons.volume_off_rounded,
                      color: voiceEnabled
                          ? (isSpeaking ? const Color(0xFFF59E0B) : const Color(0xFF34D399))
                          : Colors.white38,
                    ),
                    tooltip: voiceEnabled ? 'Mute Auctioneer Voice' : 'Enable Auctioneer Voice',
                    onPressed: () => _session.voiceService.toggleVoice(),
                  );
                },
              ),
              // Auction Sound FX Toggle (Gavel, Heartbeat, Crowd Gasps, Paddle Clicks)
              ListenableBuilder(
                listenable: _session.sfxService,
                builder: (context, _) {
                  final sfxEnabled = _session.sfxService.isSfxEnabled;
                  return IconButton(
                    icon: Icon(
                      sfxEnabled ? Icons.surround_sound_rounded : Icons.music_off_rounded,
                      color: sfxEnabled ? const Color(0xFF60A5FA) : Colors.white38,
                    ),
                    tooltip: sfxEnabled
                        ? 'Auction Room SFX: ON (Tap to Mute Gavel & Heartbeat FX)'
                        : 'Auction Room SFX: OFF (Tap to Enable Gavel & Heartbeat FX)',
                    onPressed: () {
                      _session.sfxService.toggleSfx();
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF1E293B),
                          content: Row(
                            children: [
                              Icon(
                                _session.sfxService.isSfxEnabled
                                    ? Icons.surround_sound_rounded
                                    : Icons.music_off_rounded,
                                color: _session.sfxService.isSfxEnabled
                                    ? const Color(0xFF60A5FA)
                                    : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _session.sfxService.isSfxEnabled
                                    ? 'Auction Room SFX Enabled (Gavels & Ticks) 🔨'
                                    : 'Auction Room SFX Muted 🔇',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                tooltip: 'Reset 1v1 Session',
                onPressed: () => _showResetConfirmDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
                tooltip: 'Match Rules & Audio Settings',
                onPressed: () => _showValuationsSheet(context),
              ),
              const SizedBox(width: 6),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFF59E0B),
              indicatorWeight: 3,
              labelColor: const Color(0xFFF59E0B),
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              tabs: [
                const Tab(icon: Icon(Icons.gavel_rounded, size: 18), text: 'Arena'),
                Tab(
                  icon: const Icon(Icons.groups_rounded, size: 18),
                  text: 'Pool (${_session.unassignedPlayersCount})',
                ),
                Tab(
                  icon: const Icon(Icons.leaderboard_rounded, size: 18),
                  text: 'Squads (${_session.userSquad.length} vs ${_session.aiSquad.length})',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildArenaTab(context),
              _buildPoolTab(context),
              _buildSquadsTab(context),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: LIVE BIDDING ARENA
  // ==========================================

  Widget _buildArenaTab(BuildContext context) {
    _checkAndShowAiAutoFillPopup(context);
    _checkAndShowSoldCelebration(context);

    if (_session.isAuctionCompleted) {
      return _buildPostAuctionSummary(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. Accelerated Round Banner if active
          if (_session.isAcceleratedRound) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFB45309), Color(0xFFD97706)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    '⚡ ACCELERATED ROUND • 40% BASE PRICE DISCOUNT',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],

          // 0.2 Next in Queue / Nominated Player Banner
          if (_session.nominatedNextPlayer != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.playlist_play_rounded, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🎯 Next in Queue: ${_session.nominatedNextPlayer!.name} (${_session.nominatedNextPlayer!.role.icon} ${_session.nominatedNextPlayer!.roleDescription})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                    ),
                  ),
                  InkWell(
                    onTap: () => _session.cancelNomination(),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 0.5 Live Voice Auctioneer Anchor Status & Visualizer
          _buildAuctioneerVoiceAnchorWidget(),
          const SizedBox(height: 12),

          // 1. Top Head-to-Head HUD Banner
          _buildMatchupHudBanner(),
          const SizedBox(height: 12),

          // Strategic Timeout Active Banner
          if (_session.isStrategicTimeoutActive) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pause_circle_filled_rounded, color: Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⏸️ Strategic Timeout Called by ${_session.timeoutCaller}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E40AF)),
                        ),
                        const Text(
                          'Clock is frozen. Review squad roles & opponent math.',
                          style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _session.resumeFromTimeout(),
                    child: const Text('Resume ⚡', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],

          // 2. RTM Phase Handler / Active Spotlight / Empty State
          if (_session.rtmPhase != SoloRtmPhase.none) ...[
            _buildRtmInteractiveCard(context),
            const SizedBox(height: 16),
          ] else if (_session.currentPlayerOnBlock != null) ...[
            _buildPlayerOnBlockCard(context, _session.currentPlayerOnBlock!),
            const SizedBox(height: 14),
            _buildBiddingControlsCard(context),
            const SizedBox(height: 16),
          ] else ...[
            _buildEmptyBlockCard(context),
            const SizedBox(height: 16),
          ],

          // 3. AI Live Banter & Speech Bubble
          if (_session.lastAiDecision != null || _session.isAiThinking || _session.isOwnerSledging) ...[
            _buildAiBanterWidget(),
            const SizedBox(height: 16),
          ],

          // 4. Live Round Commentary & Bids Feed
          _buildRoundFeedCard(),
        ],
      ),
    );
  }

  Widget _buildMatchupHudBanner() {
    final userSlots = '${_session.userSquad.length}/${_session.targetSquadSize}';
    final aiSlots = '${_session.aiSquad.length}/${_session.targetSquadSize}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // User Team
              Expanded(
                child: InkWell(
                  onTap: () => _showTeamNameDialog(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF0D2A20), Color(0xFF1B4D3E)]),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _session.userTeamName,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF94A3B8)),
                                ],
                              ),
                              Row(
                                children: [
                                  Text('₹${_session.userPurse}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF047857))),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Text('Slots $userSlots', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // VS Chip & War Room Button
              InkWell(
                onTap: () => _showStrategyWarRoomSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('VS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF92400E))),
                      SizedBox(width: 4),
                      Icon(Icons.query_stats_rounded, size: 12, color: Color(0xFF92400E)),
                    ],
                  ),
                ),
              ),

              // AI Rival Team
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'stayrare-model',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                child: Text('Slots $aiSlots', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              ),
                              const SizedBox(width: 6),
                              Text('₹${_session.aiPurse}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFD97706))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StayrareOwnerAvatar(
                      size: 40,
                      onTap: () => _session.triggerInteractiveTapSledge(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // RTM Cards & Strategic Timeout Tracker Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '🃏 RTM: ${_session.userRtmCards}/1',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _session.userRtmCards > 0 ? const Color(0xFF059669) : Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  if (_session.userTimeouts > 0 && !_session.isStrategicTimeoutActive)
                    InkWell(
                      onTap: () {
                        _session.takeUserTimeout();
                        _showStrategyWarRoomSheet(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFBFDBFE))),
                        child: const Text('⏸️ Timeout (1)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF))),
                      ),
                    ),
                ],
              ),
              InkWell(
                onTap: () => _showStrategyWarRoomSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics_outlined, size: 11, color: Color(0xFF475569)),
                      SizedBox(width: 3),
                      Text(
                        'War Room',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '🃏 RTM: ${_session.aiRtmCards}/1',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _session.aiRtmCards > 0 ? const Color(0xFFD97706) : Colors.grey),
              ),
            ],
          ),
          if (_session.isAiThinking && _session.currentAiThought != null) ...[
            const SizedBox(height: 10),
            _PulsingAiThoughtBubble(
              thought: _session.currentAiThought!,
              compact: false,
            ),
          ],
        ],
      ),
    );
  }

  void _checkAndShowSoldCelebration(BuildContext context) {
    if (_session.lastSoldEvent != null) {
      final event = _session.lastSoldEvent!;
      _session.dismissSoldEvent();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => _SoloSoldCelebrationDialog(event: event),
        );
      });
    }
  }

  void _checkAndShowAiAutoFillPopup(BuildContext context) {
    if (_session.pendingAiAutoFillPopup && _session.lastAiAutoClaimedPlayers.isNotEmpty) {
      final claimed = List<PlayerValuation>.from(_session.lastAiAutoClaimedPlayers);
      _session.dismissAiAutoFillPopup();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const _StayrareOwnerAvatar(size: 42, showBorder: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hello ${_session.userTeamName} Owner! 👋',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your squad is completely full! We have players still remaining in the pool, and I choose these players at base price to fill my squad:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  ...claimed.map((p) {
                    final price = _session.getBasePriceForPlayer(p);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Text(p.role.icon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                Text('${p.roleDescription} • Score ${p.score}/100', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF047857).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₹$price',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF047857), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('View Match Results 🏆', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            );
          },
        );
      });
    }
  }

  Widget _buildEmptyBlockCard(BuildContext context) {
    final aiSquadFull = _session.aiSquad.length >= _session.targetSquadSize;
    final userSquadFull = _session.userSquad.length >= _session.targetSquadSize;

    if (aiSquadFull && !userSquadFull) {
      final available = _session.playerPool
          .where((p) => _session.playerStatusMap[p.name] == SoloPlayerStatus.pool)
          .toList();
      final needed = _session.targetSquadSize - _session.userSquad.length;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'stayrare-model Squad is Complete! 🤖',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Select $needed more player(s) from the pool at Base Price to complete your squad:',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...available.map((p) {
              final price = _session.getBasePriceForPlayer(p);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Text(p.role.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('${p.roleDescription} • Score ${p.score}/100', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _session.userDraftRemainingPlayerAtBase(p),
                      child: Text(
                        'Draft (₹$price)',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_cricket_rounded, size: 36, color: Color(0xFF0D2A20)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Auction Block is Empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            'Draw the next marquee star or player from the pool to start bidding.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2A20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFFF59E0B)),
            label: const Text('Draw Next Star Player', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            onPressed: () => _session.drawNextRandomPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerOnBlockCard(BuildContext context, PlayerValuation player) {
    final isUserLeading = _session.currentLeader == SoloBidLeader.user;
    final isAiLeading = _session.currentLeader == SoloBidLeader.ai;
    final stage = _session.gavelStage;

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
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gavel Live Stage Header Call with Strike Animation
          if (_session.currentLeader != SoloBidLeader.none)
            _AnimatedGavelPodium(
              stage: stage,
              callText: _session.gavelCallText,
            ),

          // Spotlight Top Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category & Role badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: player.isMarqueeDefault ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            player.isMarqueeDefault ? Icons.stars_rounded : Icons.person_rounded,
                            color: player.isMarqueeDefault ? Colors.black87 : Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            player.isMarqueeDefault ? 'MARQUEE STAR' : 'AUCTION POOL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: player.isMarqueeDefault ? Colors.black87 : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF34D399), width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(player.role.icon, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            player.role.label,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 40s/25s Countdown Timer Ring
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _session.timerSeconds <= 8
                        ? const Color(0xFFEF4444)
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _session.timerSeconds <= 8 ? Colors.white : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_session.timerSeconds}s',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Player Main Hero Info
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Player Role Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFF34D399), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      player.role.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name & Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        player.roleDescription,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade300, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Base: ₹${_session.getBasePriceForPlayer(player)}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFFFDE68A), fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              '🎯 Skill: ${player.score}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF6EE7B7), fontWeight: FontWeight.w800),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              '💰 Auction Score: ${player.auctionScore}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFFFCD34D), fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Current Bid Spotlight Podium
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT HIGHEST BID',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: child,
                      ),
                      child: Text(
                        '₹${_session.currentBidAmount}',
                        key: ValueKey<int>(_session.currentBidAmount),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B)),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUserLeading
                        ? const Color(0xFF059669)
                        : (isAiLeading ? const Color(0xFFDC2626) : Colors.white.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUserLeading || isAiLeading ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isUserLeading ? Icons.check_circle_rounded : (isAiLeading ? Icons.smart_toy_rounded : Icons.hourglass_top_rounded),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isUserLeading
                            ? 'YOU ARE LEADING'
                            : (isAiLeading ? 'AI IS LEADING' : 'OPENING BID'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiddingControlsCard(BuildContext context) {
    final nextBid = _session.nextUserBidPrice;
    final increment = _session.getNextIncrement(_session.currentBidAmount);
    final jump250 = nextBid + 250;
    final jump500 = nextBid + 500;
    final canBid = _session.canUserBid;
    final isUserLeading = _session.currentLeader == SoloBidLeader.user;
    final isAiLeading = _session.currentLeader == SoloBidLeader.ai;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR BIDDING CONTROLS',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5),
              ),
              Row(
                children: [
                  Text(
                    'Max: ₹${_session.userMaxBidAllowed}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF047857)),
                  ),
                  const SizedBox(width: 8),
                  if (_session.userTimeouts > 0 && !_session.isStrategicTimeoutActive)
                    InkWell(
                      onTap: () {
                        _session.takeUserTimeout();
                        _showStrategyWarRoomSheet(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.pause_circle_filled_rounded, size: 12, color: Color(0xFF2563EB)),
                            SizedBox(width: 3),
                            Text('Timeout', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons Row
          if (_session.currentLeader == SoloBidLeader.none) ...[
            // Opening Bid Options
            Row(
              children: [
                // Open Bid Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canBid ? const Color(0xFF0D2A20) : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey.shade500,
                      disabledBackgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: canBid ? 3 : 0,
                    ),
                    icon: const Icon(Icons.gavel_rounded, color: Color(0xFFF59E0B), size: 18),
                    label: Text(
                      'Open Bid ₹$nextBid',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    onPressed: canBid ? () => _session.userPlaceBid() : null,
                  ),
                ),
                const SizedBox(width: 8),

                // Pass Opening (Let AI Bid or Skip)
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.smart_toy_rounded, size: 16, color: Color(0xFFD97706)),
                    label: const Text(
                      'Pass (Let AI Bid)',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFFB45309)),
                    ),
                    onPressed: () => _session.userPass(),
                  ),
                ),
                const SizedBox(width: 8),

                // Mark Unsold Direct Button
                IconButton.outlined(
                  style: IconButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  tooltip: 'Mark Unsold & Skip',
                  icon: const Icon(Icons.skip_next_rounded, color: Color(0xFF64748B)),
                  onPressed: () => _session.userMarkUnsold(),
                ),
              ],
            ),
          ] else ...[
            // Active Bidding Options
            Row(
              children: [
                // Main Raise Bid Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canBid ? const Color(0xFF0D2A20) : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey.shade500,
                      disabledBackgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: canBid ? 3 : 0,
                    ),
                    onPressed: canBid ? () => _session.userPlaceBid() : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.gavel_rounded, color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Bid ₹$nextBid (+₹$increment)',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Pass / Fold Button
                if (isAiLeading) ...[
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _session.userPass(),
                      child: const Text('Pass (Fold)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Jump Power Bid Quick Chips Row
            if (canBid) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('⚡ Jump Bid:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const SizedBox(width: 6),
                    if (_session.userPurse >= jump250 && _session.userMaxBidAllowed >= jump250)
                      ActionChip(
                        padding: EdgeInsets.zero,
                        label: Text('₹$jump250 (+₹250)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D2A20))),
                        backgroundColor: const Color(0xFFFEF3C7),
                        onPressed: () => _session.userPlaceBid(customAmount: jump250, isJump: true),
                      ),
                    const SizedBox(width: 6),
                    if (_session.userPurse >= jump500 && _session.userMaxBidAllowed >= jump500)
                      ActionChip(
                        padding: EdgeInsets.zero,
                        label: Text('₹$jump500 (+₹500)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D2A20))),
                        backgroundColor: const Color(0xFFFDE68A),
                        onPressed: () => _session.userPlaceBid(customAmount: jump500, isJump: true),
                      ),
                  ],
                ),
              ),
            ],
          ],

          if (isUserLeading) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, size: 20, color: Color(0xFF059669)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _session.lastAiDecision?.isPass == true
                              ? 'AI conceded! Finalizing award to you...'
                              : 'You are leading the bid at ₹${_session.currentBidAmount}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                        ),
                        Text(
                          _session.lastAiDecision?.isPass == true
                              ? 'Hammer down in progress.'
                              : 'Awaiting AI model evaluation and gavel call.',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiBanterWidget() {
    final decision = _session.lastAiDecision;
    final isThinking = _session.isAiThinking;
    final isSledging = _session.isOwnerSledging && _session.ownerActiveSledge != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSledging ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSledging ? const Color(0xFFFDA4AF) : const Color(0xFFFDE68A),
          width: isSledging ? 2.0 : 1.0,
        ),
        boxShadow: isSledging
            ? [
                BoxShadow(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StayrareOwnerAvatar(
            size: 48,
            onTap: () => _session.triggerInteractiveTapSledge(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'stayrare Owner',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          '👑',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('TAP FOR SLEDGE 🎙️', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                        ),
                      ],
                    ),
                    if (isThinking)
                      Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
                          ),
                          const SizedBox(width: 6),
                          Text('Evaluating...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                        ],
                      )
                    else if (isSledging)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SLEDGE 🔥',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else if (decision != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: decision.isBid ? const Color(0xFFDC2626) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          decision.action.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: decision.isBid ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isThinking)
                  _PulsingAiThoughtBubble(
                    thought: _session.currentAiThought ?? '🤔 Checking purse reserve & squad composition...',
                    compact: false,
                  )
                else if (isSledging)
                  Text(
                    '"${_session.ownerActiveSledge!}"',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF881337), height: 1.3),
                  )
                else if (decision != null && decision.trashTalk != null)
                  Text(
                    '"${decision.trashTalk}"',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF451A03), height: 1.3),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RTM INTERACTIVE CARDS
  // ==========================================

  Widget _buildRtmInteractiveCard(BuildContext context) {
    final player = _session.currentPlayerOnBlock;
    if (player == null) return const SizedBox.shrink();

    // 1. User Can Invoke RTM
    if (_session.rtmPhase == SoloRtmPhase.userCanInvoke) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFFD97706), size: 24),
                const SizedBox(width: 8),
                Text(
                  'RTM Opportunity: ${player.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'stayrare-model won ${player.name} at ₹${_session.rtmBasePrice}. You have ${_session.userRtmCards} RTM card left.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF78350F)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _session.userInvokeRtm(),
                    child: const Text('Invoke RTM Card', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF92400E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _session.userDeclineRtmInitial(),
                    child: const Text('Let AI Have Him', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF92400E))),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. User Matching Raised Price
    if (_session.rtmPhase == SoloRtmPhase.userRaisingPrice) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFF2563EB), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Final Match Decision for ${player.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'stayrare-model raised the asked price to ₹${_session.rtmRaisedPrice}. Do you want to match this final price and claim ${player.name}?',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _session.userConfirmMatchRtm(),
                    child: Text('Match ₹${_session.rtmRaisedPrice}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E40AF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _session.userDeclineMatchRtm(),
                    child: const Text('Decline Match', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E40AF))),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 3. User Raising for AI RTM
    if (_session.rtmPhase == SoloRtmPhase.userRaisingForAiRtm) {
      return _SoloAiRtmRaisePanel(
        session: _session,
        player: player,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRoundFeedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: Color(0xFF0D2A20)),
              SizedBox(width: 8),
              Text(
                'Current Round Bidding Ladder',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_session.currentRoundBids.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('No bids placed yet in this round.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _session.currentRoundBids.length,
              separatorBuilder: (ctx, idx) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final step = _session.currentRoundBids.reversed.toList()[index];
                final isUser = step.bidder == SoloBidLeader.user;

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: isUser ? const Color(0xFF0D2A20) : const Color(0xFF7C2D12),
                    child: Icon(isUser ? Icons.person : Icons.smart_toy, size: 14, color: Colors.white),
                  ),
                  title: Text(
                    isUser ? 'You (${_session.userTeamName})' : 'stayrare-model',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.black87),
                  ),
                  subtitle: step.trashTalk != null
                      ? Text('"${step.trashTalk}"', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF475569)))
                      : Text(step.note, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '₹${step.amount}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: isUser ? const Color(0xFF166534) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: UNASSIGNED PLAYER POOL
  // ==========================================

  Widget _buildPoolTab(BuildContext context) {
    List<PlayerValuation> displayedList;
    if (_poolFilter == 'Available') {
      displayedList = _session.playerPool
          .where((p) => _session.playerStatusMap[p.name] == SoloPlayerStatus.pool)
          .toList();
    } else if (_poolFilter == 'Unsold') {
      displayedList = _session.playerPool
          .where((p) => _session.playerStatusMap[p.name] == SoloPlayerStatus.unsold)
          .toList();
    } else {
      displayedList = _session.playerPool;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Player Pool (${displayedList.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2A20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.casino_rounded, size: 16, color: Color(0xFFF59E0B)),
                label: const Text('Draw Random Star', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                onPressed: _session.unassignedPlayersCount == 0
                    ? null
                    : () {
                        _session.drawNextRandomPlayer();
                        _tabController.animateTo(0);
                      },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Available (${_session.unassignedPlayersCount})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _poolFilter == 'Available',
                  selectedColor: const Color(0xFF0D2A20),
                  labelStyle: TextStyle(color: _poolFilter == 'Available' ? Colors.white : Colors.black87),
                  onSelected: (val) {
                    if (val) setState(() => _poolFilter = 'Available');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Unsold (${_session.unsoldPlayersCount})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _poolFilter == 'Unsold',
                  selectedColor: const Color(0xFFDC2626),
                  labelStyle: TextStyle(color: _poolFilter == 'Unsold' ? Colors.white : Colors.black87),
                  onSelected: (val) {
                    if (val) setState(() => _poolFilter = 'Unsold');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('All Players (${_session.playerPool.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _poolFilter == 'All',
                  selectedColor: const Color(0xFF0D2A20),
                  labelStyle: TextStyle(color: _poolFilter == 'All' ? Colors.white : Colors.black87),
                  onSelected: (val) {
                    if (val) setState(() => _poolFilter = 'All');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Accelerated Round Trigger Banner (if unassigned pool empty or unsold exist)
          if (_session.unsoldPlayersCount > 0 && !_session.isAcceleratedRound) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF78350F), Color(0xFFB45309)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFFFDE68A), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Accelerated Round Available!',
                          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
                        ),
                        Text(
                          'Re-enter ${_session.unsoldPlayersCount} unsold players with 40% base price discount.',
                          style: const TextStyle(color: Color(0xFFFEF3C7), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: const Color(0xFF78350F),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _session.startAcceleratedRound();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚡ Accelerated Round started! Unsold players re-entered with 40% discount.'),
                          backgroundColor: Color(0xFFB45309),
                        ),
                      );
                    },
                    child: const Text('Start Round 2 ⚡', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],

          if (displayedList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  _poolFilter == 'Unsold'
                      ? 'No unsold players yet. If both pass on a player, they will appear here.'
                      : 'No players found in this filter.',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedList.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final player = displayedList[index];
                final status = _session.playerStatusMap[player.name];
                final isUnsold = status == SoloPlayerStatus.unsold;
                final isSoldUser = status == SoloPlayerStatus.soldUser;
                final isAvailable = status == SoloPlayerStatus.pool || isUnsold;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isUnsold ? Colors.red.shade100 : Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isUnsold
                              ? [Colors.grey.shade600, Colors.grey.shade800]
                              : [const Color(0xFF0D2A20), const Color(0xFF1B4D3E)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          player.role.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(player.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${player.role.icon} ${player.role.shortCode}',
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                          ),
                        ),
                        if (isUnsold || player.isMarqueeDefault) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isUnsold ? Colors.red.shade50 : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isUnsold ? 'UNSOLD' : 'MARQUEE',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: isUnsold ? Colors.red.shade800 : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${player.roleDescription} • Base Price: ₹${_session.getBasePriceForPlayer(player)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    trailing: isAvailable
                        ? (_session.nominatedNextPlayer?.name == player.name
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF93C5FD)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF2563EB)),
                                    SizedBox(width: 4),
                                    Text('Next Up 🎯', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF1E40AF))),
                                  ],
                                ),
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isUnsold ? const Color(0xFFDC2626) : const Color(0xFF0D2A20),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: Icon(_session.currentPlayerOnBlock == null ? Icons.gavel_rounded : Icons.queue_play_next_rounded, size: 14),
                                label: Text(
                                  _session.currentPlayerOnBlock == null
                                      ? (isUnsold ? 'Re-Auction ⚡' : 'Auction Now 🔨')
                                      : 'Nominate Next 🎯',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                                ),
                                onPressed: () {
                                  _session.requestPlayerForAuction(player);
                                  if (_session.currentPlayerOnBlock?.name == player.name) {
                                    _tabController.animateTo(0);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('🎯 ${player.name} will be brought up next for auction!'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: const Color(0xFF0D2A20),
                                      ),
                                    );
                                  }
                                },
                              ))
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSoldUser ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isSoldUser ? 'Won by You' : 'Won by AI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSoldUser ? const Color(0xFF166534) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: SQUADS COMPARISON
  // ==========================================

  Widget _buildSquadsTab(BuildContext context) {
    final userSpent = _session.initialPurse - _session.userPurse;
    final aiSpent = _session.initialPurse - _session.aiPurse;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        final statsBox = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(_session.userTeamName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0D2A20))),
                    const SizedBox(height: 4),
                    Text('₹${_session.userPurse}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF059669))),
                    Text('${_session.userSquad.length}/${_session.targetSquadSize} Players • Spent ₹$userSpent', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(height: 40, width: 1, color: Colors.grey.shade300),
              Expanded(
                child: Column(
                  children: [
                    Text(_session.aiTeamName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF7C2D12))),
                    const SizedBox(height: 4),
                    Text('₹${_session.aiPurse}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFFD97706))),
                    Text('${_session.aiSquad.length}/${_session.targetSquadSize} Players • Spent ₹$aiSpent', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        );

        final userSquadCard = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_session.userTeamName} (${_session.userSquad.length}/${_session.targetSquadSize})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0D2A20)),
                ),
                Text('Purse: ₹${_session.userPurse}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
              ],
            ),
            const SizedBox(height: 8),
            _buildSquadList(_session.userSquad, const Color(0xFF0D2A20)),
          ],
        );

        final aiSquadCard = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_session.aiTeamName} (${_session.aiSquad.length}/${_session.targetSquadSize})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF7C2D12)),
                ),
                Text('Purse: ₹${_session.aiPurse}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
              ],
            ),
            const SizedBox(height: 8),
            _buildSquadList(_session.aiSquad, const Color(0xFF7C2D12)),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              statsBox,
              const SizedBox(height: 20),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: userSquadCard),
                    const SizedBox(width: 20),
                    Expanded(child: aiSquadCard),
                  ],
                )
              else ...[
                userSquadCard,
                const SizedBox(height: 20),
                aiSquadCard,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSquadList(List<SoloBoughtPlayer> list, Color color) {
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(child: Text('No players bought yet.', style: TextStyle(color: Color(0xFF64748B)))),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final bought = list[index];
        final player = bought.valuation;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                player.role.icon,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            title: Row(
              children: [
                Text(player.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${player.role.icon} ${player.role.shortCode}',
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                  ),
                ),
                if (bought.viaRtm) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                    child: const Text('RTM', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
                  ),
                ],
              ],
            ),
            subtitle: Text(player.roleDescription, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            trailing: Text(
              '₹${bought.price}',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // POST-AUCTION SUMMARY & VERDICT
  // ==========================================

  Widget _buildPostAuctionSummary(BuildContext context) {
    final aiOpinion = _session.postAuctionAiOpinion;
    final aiBelievesItWon = _session.aiBelievesItWon;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. AI Rival Owner Opinion Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: aiBelievesItWon
                    ? [const Color(0xFF0F291E), const Color(0xFF1E3A2F)]
                    : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: aiBelievesItWon ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _StayrareOwnerAvatar(size: 46, showBorder: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AUCTION CONCLUDED • AI OWNER VERDICT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            aiBelievesItWon ? 'AI Owner Feels Confident 🏆' : 'AI Owner Acknowledges Strong Fight 🤝',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Opinion Quote Bubble
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote_rounded, color: Color(0xFFF59E0B), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '"$aiOpinion"',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Color(0xFFE2E8F0),
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Head to Head Roster Comparison
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 768;

              final userSquadWidget = _buildSquadSummaryCard(
                teamName: _session.userTeamName,
                squad: _session.userSquad,
                purseRemaining: _session.userPurse,
                color: const Color(0xFF0D2A20),
                accentColor: const Color(0xFF10B981),
              );

              final aiSquadWidget = _buildSquadSummaryCard(
                teamName: _session.aiTeamName,
                squad: _session.aiSquad,
                purseRemaining: _session.aiPurse,
                color: const Color(0xFF7C2D12),
                accentColor: const Color(0xFFF59E0B),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: userSquadWidget),
                    const SizedBox(width: 16),
                    Expanded(child: aiSquadWidget),
                  ],
                );
              } else {
                return Column(
                  children: [
                    userSquadWidget,
                    const SizedBox(height: 16),
                    aiSquadWidget,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // 2.5 AI Learning, Opponent Study & Ranking Adjustment Panel
          _buildLearnedInsightsPanel(context),
          const SizedBox(height: 24),

          // 3. Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFFF59E0B)),
                  label: const Text('Play Rematch with AI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  onPressed: () => _session.initSession(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0D2A20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF0D2A20), width: 1.5),
                  ),
                ),
                icon: const Icon(Icons.groups_rounded, color: Color(0xFF0D2A20)),
                label: const Text('View Full Squads', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                onPressed: () => _tabController.animateTo(2),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLearnedInsightsPanel(BuildContext context) {
    final session = _session.latestRecordedSession;
    final insights = _session.latestLearnedInsights;
    final firebaseStatus = _session.firebaseService.syncStatus;
    final opponentProfile = session?.opponentProfile;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Firebase Cloud Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI LEARNING & OPPONENT STUDY',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
                      ),
                      Text(
                        'Adaptive Market Rankings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_done_rounded, color: Color(0xFF059669), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      firebaseStatus,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Opponent Study Insight
          if (opponentProfile != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radar_rounded, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Opponent Persona: ${opponentProfile.biddingStyle}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bids Placed: ${opponentProfile.totalUserBidsPlaced} • Jump Bids: ${opponentProfile.userJumpBidsPlaced} • Spent: ₹${opponentProfile.totalUserSpent}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Parameter explanation note
          const Text(
            '⚡ Auction Score ranks money spent on each player across auctions. Combined with Skill Score to adjust market rankings dynamically!',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 14),

          // Insights Table
          if (insights.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: min(insights.length, 12),
              separatorBuilder: (context, index) => const Divider(height: 12, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, idx) {
                final ins = insights[idx];
                final player = _session.learnerService.getPlayerValuation(ins.playerName);
                return Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${ins.newRank}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ins.playerName} (${player.role.icon} ${player.roleDescription})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            ins.learnedAdjustmentNote,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${ins.finalWinningPrice}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Auction Score: ${ins.newAuctionScore}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                            ),
                            if (ins.newAuctionScore > ins.oldAuctionScore)
                              const Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 12)
                            else if (ins.newAuctionScore < ins.oldAuctionScore)
                              const Icon(Icons.arrow_downward_rounded, color: Color(0xFFEF4444), size: 12),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSquadSummaryCard({
    required String teamName,
    required List<SoloBoughtPlayer> squad,
    required int purseRemaining,
    required Color color,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                teamName,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${squad.length}/${_session.targetSquadSize} Squad',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Remaining Purse: ₹$purseRemaining',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const Divider(height: 20),
          if (squad.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('No players bought', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: squad.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final p = squad[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Text(p.valuation.role.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.valuation.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹${p.price}',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showStrategyWarRoomSheet(BuildContext context) {
    final userRoles = _session.userRoleCounts;
    final aiRoles = _session.aiRoleCounts;
    final mandates = _session.roleMandates;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                controller: scrollController,
                children: [
                  // Title & Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2A20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.analytics_rounded, color: Color(0xFFF59E0B), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Strategic War Room', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                              Text('Squad Composition & Live Analytics', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Mandatory Squad Composition Matrix
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.checklist_rounded, size: 18, color: Color(0xFF0D2A20)),
                            SizedBox(width: 8),
                            Text(
                              'Squad Composition Mandates',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Official tournament rules require minimum role quotas for match eligibility:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 12),

                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Expanded(flex: 3, child: Text('Role Required', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                              const Expanded(flex: 2, child: Text('Target', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                              Expanded(flex: 3, child: Text('You (${_session.userTeamName})', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D2A20)))),
                              const Expanded(flex: 3, child: Text('AI (stayrare)', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C2D12)))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Role Rows
                        ...CricketRole.values.map((role) {
                          final target = mandates[role] ?? 1;
                          final uCount = userRoles[role] ?? 0;
                          final aCount = aiRoles[role] ?? 0;
                          final uSatisfied = uCount >= target;
                          final aSatisfied = aCount >= target;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Text(role.icon, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 6),
                                      Text(role.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Min $target', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('$uCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: uSatisfied ? const Color(0xFF047857) : Colors.red.shade700)),
                                      const SizedBox(width: 4),
                                      Icon(uSatisfied ? Icons.check_circle_rounded : Icons.pending_rounded, size: 14, color: uSatisfied ? const Color(0xFF059669) : Colors.red.shade400),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('$aCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: aSatisfied ? const Color(0xFFD97706) : Colors.red.shade700)),
                                      const SizedBox(width: 4),
                                      Icon(aSatisfied ? Icons.check_circle_rounded : Icons.pending_rounded, size: 14, color: aSatisfied ? const Color(0xFFD97706) : Colors.red.shade400),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Purse & Safety Reserve Economics
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, size: 18, color: Color(0xFF92400E)),
                            SizedBox(width: 8),
                            Text('Purse & Safety Reserve Economics', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF92400E))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Your Max Bid:', style: TextStyle(fontSize: 11, color: Color(0xFF78350F))),
                                  Text('₹${_session.userMaxBidAllowed}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                                  Text('Purse ₹${_session.userPurse} • ${_session.targetSquadSize - _session.userSquad.length} slots left', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Container(height: 36, width: 1, color: const Color(0xFFFDE68A)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('AI Max Bid:', style: TextStyle(fontSize: 11, color: Color(0xFF78350F))),
                                  Text('₹${_session.aiMaxBidAllowed}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
                                  Text('Purse ₹${_session.aiPurse} • ${_session.targetSquadSize - _session.aiSquad.length} slots left', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Unassigned Top Targets
                  const Text('Remaining Pool Targets:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  ..._session.playerPool
                      .where((p) => _session.playerStatusMap[p.name] == SoloPlayerStatus.pool)
                      .take(5)
                      .map((p) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF0D2A20),
                              child: Text(p.role.icon, style: const TextStyle(fontSize: 11)),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            subtitle: Text('${p.role.icon} ${p.role.label} • ${p.roleDescription}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            trailing: Text('Base ₹${_session.getBasePriceForPlayer(p)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF047857))),
                          )),
                  const SizedBox(height: 20),

                  // Resume Button if Timeout Active
                  if (_session.isStrategicTimeoutActive)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2A20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFFF59E0B)),
                      label: const Text('Resume Auction Clock', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      onPressed: () {
                        _session.resumeFromTimeout();
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTeamNameDialog(BuildContext context, {bool isInitial = false}) {
    final textController = TextEditingController(
      text: _session.userTeamName != 'My Team' ? _session.userTeamName : '',
    );
    final quickNames = [
      'Danapur Dabangg',
      'Bailey Blasters',
      'Mithapur Masters',
      'Royal Rajvanshi',
      'Rising Titans',
      'Super Strikers',
      'Patliputra Panthers',
      'Kankarbagh Kings',
      'Boring Road Brawlers',
    ];

    showDialog(
      context: context,
      barrierDismissible: !isInitial,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2A20).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFF0D2A20), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isInitial ? 'Name Your Franchise' : 'Edit Team Name',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Choose your Patna franchise name for this 1v1 battle',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: textController,
                      autofocus: isInitial,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 24,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'e.g. Danapur Dabangg, Bailey Blasters',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 14),
                        prefixIcon: const Icon(Icons.groups_rounded, color: Color(0xFF0D2A20), size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0D2A20), width: 2),
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'QUICK SUGGESTIONS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickNames.map((name) {
                        final isSelected = textController.text.trim().toLowerCase() == name.toLowerCase();
                        return ChoiceChip(
                          label: Text(
                            name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0D2A20),
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF0D2A20) : Colors.transparent,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          onSelected: (selected) {
                            if (selected) {
                              textController.text = name;
                              setDialogState(() {});
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isInitial)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A20),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final enteredName = textController.text.trim();
                    final finalName = enteredName.isNotEmpty ? enteredName : 'My Team';
                    _session.setTeamName(finalName);
                    Navigator.pop(ctx);
                    if (isInitial) {
                      _session.voiceService.speak("Welcome, Owner of $finalName! Let's get the auction started!");
                    }
                  },
                  child: Text(
                    isInitial ? 'Enter Arena' : 'Save Name',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restart 1v1 AI Match?'),
        content: const Text('This will reset both purses to ₹10,000 and return all players to the pool.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2A20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _session.initSession();
            },
            child: const Text('Restart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showValuationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _SoloValuationsSheetContent(session: _session),
    );
  }

  Widget _buildAuctioneerVoiceAnchorWidget() {
    return ListenableBuilder(
      listenable: _session.voiceService,
      builder: (context, _) {
        final voice = _session.voiceService;
        final isSpeaking = voice.isSpeaking;
        final isEnabled = voice.isEnabled;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSpeaking ? const Color(0xFF0D2A20) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSpeaking ? const Color(0xFF10B981) : Colors.grey.shade300,
              width: isSpeaking ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSpeaking ? const Color(0xFF10B981).withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSpeaking
                      ? const Color(0xFF10B981).withValues(alpha: 0.25)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnabled
                      ? (isSpeaking ? Icons.record_voice_over_rounded : Icons.mic_rounded)
                      : Icons.mic_off_rounded,
                  color: isSpeaking ? const Color(0xFF34D399) : (isEnabled ? const Color(0xFF0D2A20) : Colors.grey),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '🎙️ LIVE AUCTIONEER ANCHOR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isSpeaking ? const Color(0xFF34D399) : const Color(0xFF0F172A),
                            letterSpacing: 0.6,
                          ),
                        ),
                        if (isSpeaking) ...[
                          const SizedBox(width: 8),
                          const _AudioEqualizerVisualizer(isSpeaking: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnabled
                          ? (isSpeaking
                              ? 'Calling live bids & gavel countdowns...'
                              : 'Voice active • Announcing all bids')
                          : 'Voice muted • Tap speaker icon to enable audio',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSpeaking ? Colors.white70 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => voice.testSpeech(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 14, color: Color(0xFFD97706)),
                          SizedBox(width: 2),
                          Text(
                            'TEST VOICE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => voice.toggleVoice(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? (isSpeaking ? const Color(0xFF10B981) : const Color(0xFF0D2A20))
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            size: 14,
                            color: isEnabled ? Colors.white : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isEnabled ? 'VOICE ON' : 'MUTED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isEnabled ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SoloAiRtmRaisePanel extends StatefulWidget {
  final SoloAiAuctionSession session;
  final PlayerValuation player;

  const _SoloAiRtmRaisePanel({
    required this.session,
    required this.player,
  });

  @override
  State<_SoloAiRtmRaisePanel> createState() => _SoloAiRtmRaisePanelState();
}

class _SoloAiRtmRaisePanelState extends State<_SoloAiRtmRaisePanel> {
  late int _chosenPrice;

  @override
  void initState() {
    super.initState();
    _chosenPrice = widget.session.rtmBasePrice;
  }

  @override
  void didUpdateWidget(covariant _SoloAiRtmRaisePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.session.rtmBasePrice != oldWidget.session.rtmBasePrice) {
      _chosenPrice = widget.session.rtmBasePrice;
    }
  }

  void _adjustPrice(int delta) {
    final base = widget.session.rtmBasePrice;
    final maxAllowed = widget.session.userMaxBidAllowed;

    var newPrice = _chosenPrice + delta;
    if (newPrice < base) newPrice = base;
    if (newPrice > maxAllowed) newPrice = maxAllowed;

    // Align to nearest multiple of 50
    newPrice = (newPrice ~/ 50) * 50;
    if (newPrice < base) newPrice = base;

    setState(() {
      _chosenPrice = newPrice;
    });
  }

  void _showCustomPriceDialog() {
    final base = widget.session.rtmBasePrice;
    final maxAllowed = widget.session.userMaxBidAllowed;
    final controller = TextEditingController(text: _chosenPrice.toString());
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Enter Custom RTM Asked Price', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minimum: ₹$base (No raise)\nMaximum allowed: ₹$maxAllowed\nMust be a multiple of ₹50.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    labelText: 'Asked Price',
                    errorText: errorText,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    final numVal = int.tryParse(val.trim());
                    if (numVal == null) {
                      setDialogState(() => errorText = 'Enter a valid number');
                    } else if (numVal < base) {
                      setDialogState(() => errorText = 'Cannot be less than base bid ₹$base');
                    } else if (numVal > maxAllowed) {
                      setDialogState(() => errorText = 'Exceeds max allowed purse ₹$maxAllowed');
                    } else if (numVal % 50 != 0) {
                      setDialogState(() => errorText = 'Must be a multiple of ₹50 (e.g. ₹${(numVal ~/ 50) * 50})');
                    } else {
                      setDialogState(() => errorText = null);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2A20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final numVal = int.tryParse(controller.text.trim());
                  if (numVal != null && numVal >= base && numVal <= maxAllowed && numVal % 50 == 0) {
                    setState(() => _chosenPrice = numVal);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Set Price', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.session.rtmBasePrice;
    final maxAllowed = widget.session.userMaxBidAllowed;
    final isNoRaise = _chosenPrice == base;
    final diff = _chosenPrice - base;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _StayrareOwnerAvatar(size: 38, showBorder: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Triggered RTM on ${widget.player.name}!',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF991B1B)),
                    ),
                    Text(
                      'stayrare-model wants to match your winning bid of ₹$base.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Price Selection Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FINAL ASKED PRICE (₹Y):',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isNoRaise ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isNoRaise ? 'ORIGINAL (NO RAISE)' : '+₹$diff RAISED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isNoRaise ? const Color(0xFF92400E) : const Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Stepper Row (Multiples of 50)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // -50 Step
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.all(8),
                      ),
                      icon: const Icon(Icons.remove_rounded, color: Colors.black87, size: 20),
                      onPressed: _chosenPrice > base ? () => _adjustPrice(-50) : null,
                      tooltip: '-₹50',
                    ),
                    const SizedBox(width: 10),

                    // Price display box
                    InkWell(
                      onTap: _showCustomPriceDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹$_chosenPrice',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit_rounded, size: 14, color: Color(0xFFB45309)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // +50 Step
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.all(8),
                      ),
                      icon: const Icon(Icons.add_rounded, color: Colors.black87, size: 20),
                      onPressed: _chosenPrice + 50 <= maxAllowed ? () => _adjustPrice(50) : null,
                      tooltip: '+₹50',
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Quick Multiple of 50 Preset Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // No raise preset
                      ChoiceChip(
                        label: Text('₹$base (No Raise)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: _chosenPrice == base,
                        selectedColor: const Color(0xFF0D2A20),
                        labelStyle: TextStyle(color: _chosenPrice == base ? Colors.white : Colors.black87),
                        onSelected: (_) => setState(() => _chosenPrice = base),
                      ),
                      const SizedBox(width: 6),

                      // +50 preset
                      if (base + 50 <= maxAllowed) ...[
                        ActionChip(
                          label: Text('+₹50 (₹${base + 50})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D2A20))),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onPressed: () => setState(() => _chosenPrice = base + 50),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // +100 preset
                      if (base + 100 <= maxAllowed) ...[
                        ActionChip(
                          label: Text('+₹100 (₹${base + 100})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D2A20))),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onPressed: () => setState(() => _chosenPrice = base + 100),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // +250 preset
                      if (base + 250 <= maxAllowed) ...[
                        ActionChip(
                          label: Text('+₹250 (₹${base + 250})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D2A20))),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onPressed: () => setState(() => _chosenPrice = base + 250),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // +500 preset
                      if (base + 500 <= maxAllowed) ...[
                        ActionChip(
                          label: Text('+₹500 (₹${base + 500})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D2A20))),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onPressed: () => setState(() => _chosenPrice = base + 500),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Custom input button
                      ActionChip(
                        avatar: const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF0D2A20)),
                        label: const Text('Custom ₹...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D2A20))),
                        backgroundColor: const Color(0xFFFEF3C7),
                        onPressed: _showCustomPriceDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Contextual Explanation Note
          Text(
            isNoRaise
                ? '• You are keeping your price at ₹$base. If AI matches ₹$base, AI gets ${widget.player.name}. If AI declines, you get ${widget.player.name} at ₹$base.'
                : '• Raised price: ₹$_chosenPrice. If AI matches, AI pays ₹$_chosenPrice. If AI declines, you win ${widget.player.name} at ₹$_chosenPrice.',
            style: const TextStyle(fontSize: 10, color: Color(0xFF7F1D1D), height: 1.3),
          ),
          const SizedBox(height: 12),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isNoRaise ? const Color(0xFF0D2A20) : const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              onPressed: () => widget.session.userSubmitRaisedPriceForAiRtm(_chosenPrice),
              child: Text(
                isNoRaise
                    ? 'Ask AI to Match ₹$base (No Raise) →'
                    : 'Raise to ₹$_chosenPrice & Ask AI to Match →',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedGavelPodium extends StatefulWidget {
  final SoloGavelStage stage;
  final String callText;

  const _AnimatedGavelPodium({
    required this.stage,
    required this.callText,
  });

  @override
  State<_AnimatedGavelPodium> createState() => _AnimatedGavelPodiumState();
}

class _AnimatedGavelPodiumState extends State<_AnimatedGavelPodium> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _rotationAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.45).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.45, end: 0.20).chain(CurveTween(curve: Curves.bounceOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.20, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
    ]).animate(_controller);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedGavelPodium oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stage != oldWidget.stage) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bannerColor;
    switch (widget.stage) {
      case SoloGavelStage.active:
        bannerColor = Colors.black.withValues(alpha: 0.35);
        break;
      case SoloGavelStage.goingOnce:
        bannerColor = const Color(0xFFD97706);
        break;
      case SoloGavelStage.goingTwice:
        bannerColor = const Color(0xFFDC2626);
        break;
      case SoloGavelStage.hammerDown:
        bannerColor = const Color(0xFF059669);
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: const Text('🔨', style: TextStyle(fontSize: 16)),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.callText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioEqualizerVisualizer extends StatefulWidget {
  final bool isSpeaking;
  const _AudioEqualizerVisualizer({required this.isSpeaking});

  @override
  State<_AudioEqualizerVisualizer> createState() => _AudioEqualizerVisualizerState();
}

class _AudioEqualizerVisualizerState extends State<_AudioEqualizerVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpeaking) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final v = _ctrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBar((5 + (v * 11)).toDouble(), const Color(0xFF34D399)),
            const SizedBox(width: 2),
            _buildBar((14 - (v * 8)).toDouble(), const Color(0xFFF59E0B)),
            const SizedBox(width: 2),
            _buildBar((7 + ((1 - v) * 9)).toDouble(), const Color(0xFF60A5FA)),
            const SizedBox(width: 2),
            _buildBar((5 + (v * 10)).toDouble(), const Color(0xFF34D399)),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 3,
      height: height.clamp(4.0, 16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// --- PURCHASE DONE ("SOLD!") CELEBRATION DIALOG WITH CONFETTI & GAVEL HIT FOR 1v1 SOLO AI ---
class _SoloSoldCelebrationDialog extends StatefulWidget {
  final SoloSoldEvent event;

  const _SoloSoldCelebrationDialog({required this.event});

  @override
  State<_SoloSoldCelebrationDialog> createState() => _SoloSoldCelebrationDialogState();
}

class _SoloSoldCelebrationDialogState extends State<_SoloSoldCelebrationDialog> with TickerProviderStateMixin {
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
    final isUser = widget.event.isUser;
    final teamColor = isUser ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

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
                  painter: _SoloConfettiPainter(progress: _confettiController.value),
                );
              },
            ),
          ),

          // Main Card
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
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
                            widget.event.viaRtm ? Icons.verified_rounded : Icons.gavel_rounded,
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
                      widget.event.viaRtm ? '🎉 CLAIMED VIA RTM! 🎉' : '🔨 SOLD! SOLD! SOLD! 🔨',
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
                    widget.event.player.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.event.player.role.icon} ${widget.event.player.roleDescription.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
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
                        Expanded(
                          child: Column(
                            children: [
                              const Text('BUYING FRANCHISE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(
                                widget.event.winnerName,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: teamColor, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 30, width: 1, color: Colors.white24),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('FINAL PRICE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(
                                '₹${widget.event.price}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                              ),
                            ],
                          ),
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
                        'CONTINUE AUCTION 🚀',
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

class _SoloConfettiPainter extends CustomPainter {
  final double progress;
  final List<_SoloConfettiParticle> _particles;

  _SoloConfettiPainter({required this.progress})
      : _particles = List.generate(40, (index) {
          final random = Random(index);
          return _SoloConfettiParticle(
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
  bool shouldRepaint(covariant _SoloConfettiPainter oldDelegate) => true;
}

class _SoloConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final double rotation;

  _SoloConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.rotation,
  });
}

class _PulsingAiThoughtBubble extends StatefulWidget {
  final String thought;
  final bool compact;

  const _PulsingAiThoughtBubble({
    required this.thought,
    this.compact = false,
  });

  @override
  State<_PulsingAiThoughtBubble> createState() => _PulsingAiThoughtBubbleState();
}

class _PulsingAiThoughtBubbleState extends State<_PulsingAiThoughtBubble> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: widget.compact ? 6 : 10,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: _glowAnim.value),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: _glowAnim.value * 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB45309)),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.thought,
                    style: TextStyle(
                      fontSize: widget.compact ? 11 : 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF78350F),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: widget.compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StayrareOwnerAvatar extends StatefulWidget {
  final double size;
  final bool showBorder;
  final VoidCallback? onTap;

  const _StayrareOwnerAvatar({
    this.size = 38,
    this.showBorder = true,
    this.onTap,
  });

  @override
  State<_StayrareOwnerAvatar> createState() => _StayrareOwnerAvatarState();
}

class _StayrareOwnerAvatarState extends State<_StayrareOwnerAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(widget.size / 2),
      child: AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (context, child) {
          final shimmerPos = _shimmerCtrl.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E293B),
                  border: widget.showBorder
                      ? Border.all(
                          color: Color.lerp(
                            const Color(0xFFDC2626),
                            const Color(0xFFF59E0B),
                            (sin(shimmerPos * 2 * pi) + 1) / 2,
                          )!,
                          width: 2.0,
                        )
                      : null,
                  boxShadow: widget.showBorder
                      ? [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/stayrare_owner.png',
                          width: widget.size,
                          height: widget.size,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.3),
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFF7C2D12), Color(0xFFDC2626)]),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: widget.size * 0.5),
                          ),
                        ),
                      ),
                      // Sunglasses reflection shine sweep
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.35,
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment(-2.0 + (shimmerPos * 4.0), -1.0),
                                end: Alignment(-1.0 + (shimmerPos * 4.0), 1.0),
                                colors: const [
                                  Colors.transparent,
                                  Colors.white,
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcOver,
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.onTap != null)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 9),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SoloValuationsSheetContent extends StatefulWidget {
  final SoloAiAuctionSession session;
  const _SoloValuationsSheetContent({required this.session});

  @override
  State<_SoloValuationsSheetContent> createState() => _SoloValuationsSheetContentState();
}

class _SoloValuationsSheetContentState extends State<_SoloValuationsSheetContent> {
  int _selectedTab = 0; // 0: Valuations & Ranks, 1: Regulations & Audio
  String _roleFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final rankedList = widget.session.learnerService.rankedPlayers;
    final totalLearned = widget.session.learnerService.totalAuctionsLearned;

    List<PlayerValuation> filteredPlayers = rankedList;
    if (_roleFilter == 'BAT') {
      filteredPlayers = rankedList.where((p) => p.role == CricketRole.bat).toList();
    } else if (_roleFilter == 'BOWL') {
      filteredPlayers = rankedList.where((p) => p.role == CricketRole.bowl).toList();
    } else if (_roleFilter == 'AR') {
      filteredPlayers = rankedList.where((p) => p.role == CricketRole.allRounder).toList();
    } else if (_roleFilter == 'Top 7') {
      filteredPlayers = rankedList.where((p) => p.adjustedRank <= 7).toList();
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      maxChildSize: 0.94,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: Color(0xFFD97706), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalLearned > 0
                              ? 'LEARNED FROM $totalLearned AUCTIONS'
                              : 'COLD-START BASELINE (AUCTION #1)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: totalLearned > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Text(
                          'Player Valuations & Ranks',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Selector Row
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 0
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Market Ranks (${rankedList.length})',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _selectedTab == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 1
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Rules & Audio',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _selectedTab == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab 0: Player Valuations & Dynamic Market Rankings
            if (_selectedTab == 0) ...[
              // Role Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Top 7', 'BAT', 'BOWL', 'AR'].map((role) {
                    final isSel = _roleFilter == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isSel ? Colors.white : const Color(0xFF334155))),
                        selected: isSel,
                        selectedColor: const Color(0xFF0D2A20),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (val) {
                          if (val) setState(() => _roleFilter = role);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // Players List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: filteredPlayers.length,
                  separatorBuilder: (_, _) => const Divider(height: 10, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, idx) {
                    final p = filteredPlayers[idx];
                    final isTop3 = p.adjustedRank <= 3;
                    final rankColor = p.adjustedRank == 1
                        ? const Color(0xFFD97706)
                        : (p.adjustedRank == 2 ? const Color(0xFF64748B) : (p.adjustedRank == 3 ? const Color(0xFFB45309) : const Color(0xFF0F172A)));

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          // Rank Badge
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isTop3 ? rankColor.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: isTop3 ? Border.all(color: rankColor.withValues(alpha: 0.4), width: 1.5) : null,
                            ),
                            child: Text(
                              '#${p.adjustedRank}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isTop3 ? rankColor : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Name & Role
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D2A20).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        '${p.role.icon} ${p.role.shortCode}',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF0D2A20)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Skill: ${p.score} • Auction Score: ${p.auctionScore} • Avg: ₹${p.historicalAvgPrice} • Sold: ${p.timesAuctioned}x',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),

                          // Composite Score & Tier Badge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.compositeScore >= 70 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.tierBadge,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: p.compositeScore >= 70 ? const Color(0xFFD97706) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Score: ${p.compositeScore}/100',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // Tab 1: Match Regulations & Audio
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildSoloRegulationTile(
                      icon: Icons.account_balance_wallet_rounded,
                      title: '₹12,000 Budget Purse',
                      desc: 'Both you and the AI start with ₹12,000 for a 10-player squad. Target budget is ₹1,200 per slot.',
                    ),
                    _buildSoloRegulationTile(
                      icon: Icons.groups_rounded,
                      title: 'Squad Mandates (10 Players)',
                      desc: 'Eligible squads must contain 10 players: max 5 pure batsmen, min 5 bowling options (Bowlers + All-Rounders).',
                    ),
                    _buildSoloRegulationTile(
                      icon: Icons.style_rounded,
                      title: '1 RTM (Right-To-Match) Card',
                      desc: 'When an opponent wins a player, you can exercise your RTM card. The opponent can raise the price to any multiple of ₹50, and you decide whether to match.',
                    ),
                    _buildSoloRegulationTile(
                      icon: Icons.pause_circle_filled_rounded,
                      title: '1 Strategic Timeout (30 Seconds)',
                      desc: 'Each team has 1 timeout per match to freeze the clock, review opponent purse math, and plan role targets.',
                    ),
                    _buildSoloRegulationTile(
                      icon: Icons.bolt_rounded,
                      title: 'Round 2 Accelerated Phase',
                      desc: 'Unsold players return in Round 2 with a 40% base price discount and a faster 25s countdown clock.',
                    ),
                    _buildSoloRegulationTile(
                      icon: Icons.trending_up_rounded,
                      title: 'Dynamic Bid Increments',
                      desc: '• Below ₹1,000: +₹100 per bid\n• ₹1,000 to ₹2,500: +₹250 per bid\n• Above ₹2,500: +₹500 per bid',
                    ),
                    const SizedBox(height: 12),
                    // Live Audio Settings Card
                    StatefulBuilder(
                      builder: (context, setSheetState) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.spatial_audio_off_rounded, color: Color(0xFFF59E0B), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Live Voice & Sledge Audio Settings',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                activeTrackColor: const Color(0xFF10B981),
                                title: const Text('Official Auctioneer Voice', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                subtitle: const Text('Live bid calls, timer gavels, and player introductions', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                value: widget.session.voiceService.isEnabled,
                                onChanged: (val) {
                                  widget.session.voiceService.toggleVoice();
                                  setSheetState(() {});
                                },
                              ),
                              const Divider(color: Colors.white12, height: 1),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                activeTrackColor: const Color(0xFF38BDF8),
                                title: const Text('Auction Room Sound FX', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                subtitle: const Text('Wooden gavel knocks, countdown heartbeat, crowd gasps & paddle clicks', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                value: widget.session.sfxService.isSfxEnabled,
                                onChanged: (val) {
                                  widget.session.sfxService.toggleSfx();
                                  setSheetState(() {});
                                },
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF38BDF8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    icon: const Icon(Icons.gavel_rounded, color: Color(0xFF38BDF8), size: 14),
                                    label: const Text('🔨 Test Gavel', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w800)),
                                    onPressed: () => widget.session.sfxService.playHammerDown(),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFEF4444)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    icon: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 14),
                                    label: const Text('💓 Test Heartbeat', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w800)),
                                    onPressed: () => widget.session.sfxService.playCountdownTick(secondsRemaining: 3),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFF59E0B)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFF59E0B), size: 14),
                                    label: const Text('🎙️ Test Dual Voice', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w800)),
                                    onPressed: () => widget.session.voiceService.testSpeech(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSoloRegulationTile({required IconData icon, required String title, required String desc}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2A20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

