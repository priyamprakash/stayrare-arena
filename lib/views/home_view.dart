import 'package:flutter/material.dart';
import '../models/ai_model_valuation.dart';
import '../models/league.dart';
import '../services/league_provider.dart';
import '../services/league_service.dart';
import '../services/stayrare_ai_learner.dart';
import 'rules_guide_view.dart';
import 'setup_view.dart';
import 'solo_ai_auction_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<LeagueService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2A20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports_cricket, color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cricket League',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.tune_rounded, color: Color(0xFF0D2A20), size: 18),
            ),
            tooltip: 'Setup Captains & Pool',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const SetupView()),
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.help_outline_rounded, color: Color(0xFF0D2A20), size: 18),
            ),
            tooltip: 'Rules & Guide',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const RulesGuideView()),
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.refresh_rounded, color: Color(0xFF0D2A20), size: 18),
            ),
            tooltip: 'Reset Auction',
            onPressed: () => _showResetDialog(context, service),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // SEPARATE SECTION: PLAY WITH STAYRARE-MODEL
            // ==========================================
            _buildStayrareModelHeroCard(context),
            const SizedBox(height: 20),

            // Section Header: Official League
            const Row(
              children: [
                Icon(Icons.workspace_premium_rounded, size: 18, color: Color(0xFF0D2A20)),
                SizedBox(width: 8),
                Text(
                  'Official League Tournament',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Hero Stadium Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D2A20), Color(0xFF1B4D3E)],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.stars, color: Colors.black87, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'OFFICIAL SQUAD ROSTER',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 28),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'League Auction Summary',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹10,000 Purse • ${service.targetSquadSizePerSide}-a-side Target • 1 RTM Card per team',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade300, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Captains & Pool Info Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${service.teams.isNotEmpty ? service.teams[0].name : "Team 1"} vs ${service.teams.length > 1 ? service.teams[1].name : "Team 2"}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Captains: ${service.captain1Name} & ${service.captain2Name} • ${service.people.where((p) => p.role == PersonRole.player).length} players in auction',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      side: const BorderSide(color: Color(0xFF0D2A20)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const SetupView()),
                      );
                    },
                    icon: const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF0D2A20)),
                    label: const Text(
                      'Change',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0D2A20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Teams Row / Layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (service.teams.isEmpty) return const SizedBox.shrink();

                final team1Id = service.teams[0].id;
                final team2Id = service.teams[1].id;

                if (constraints.maxWidth > 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCoolTeamCard(context, service, team1Id, const Color(0xFF0D2A20), const Color(0xFF1B4D3E))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCoolTeamCard(context, service, team2Id, const Color(0xFF064E3B), const Color(0xFF047857))),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildCoolTeamCard(context, service, team1Id, const Color(0xFF0D2A20), const Color(0xFF1B4D3E)),
                    const SizedBox(height: 20),
                    _buildCoolTeamCard(context, service, team2Id, const Color(0xFF064E3B), const Color(0xFF047857)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PLAY WITH STAYRARE-MODEL SECTION CARD
  // ==========================================

  Widget _buildStayrareModelHeroCard(BuildContext context) {
    return Container(
      height: 145,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF091611),
            Color(0xFF0F2D22),
            Color(0xFF163E30),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D2A20).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background ambient glow behind character
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 130,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFDC2626).withValues(alpha: 0.25),
                      const Color(0xFFF59E0B).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Background subtle sports icon watermark
            Positioned(
              right: 95,
              bottom: -15,
              child: Icon(
                Icons.sports_cricket_rounded,
                size: 80,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),

            // Main Content Row
            Row(
              children: [
                // Left Column: Details & Actions
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Badges
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded, color: Colors.black87, size: 11),
                                  SizedBox(width: 2),
                                  Text(
                                    '1v1 ARENA',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.record_voice_over_rounded, size: 10, color: Color(0xFF34D399)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Live Sledge',
                                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Title & Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Play vs stayrare-model',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹12k Purse • Soft Ceilings • 1 RTM • Live Trash Talk',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade300,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 2,
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (ctx) => const SoloAiAuctionView()),
                                  );
                                },
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Start Auction Battle →',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Material(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _showValuationsModal(context),
                                child: const Padding(
                                  padding: EdgeInsets.all(7.0),
                                  child: Icon(Icons.table_chart_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Column: Hero Mascot Artwork
                SizedBox(
                  width: 115,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned(
                        top: 6,
                        bottom: 12,
                        child: Image.asset(
                          'assets/images/stayrare_owner.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.smart_toy_rounded,
                            color: Color(0xFFF59E0B),
                            size: 48,
                          ),
                        ),
                      ),
                      // Soft bottom vignette for seamless blend
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF163E30).withValues(alpha: 0.95),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Hero Character Tag
                      Positioned(
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.whatshot_rounded, color: Colors.white, size: 9),
                              SizedBox(width: 2),
                              Text(
                                'AI RIVAL',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showValuationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const _HomeValuationsModalContent(),
    );
  }

  void _showResetDialog(BuildContext context, LeagueService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Auction?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: const Text(
          'This will clear all player purchases and return all players to the unassigned auction pool.',
          style: TextStyle(color: Color(0xFF444444)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              service.resetAuction();
            },
            child: const Text('Reset All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCoolTeamCard(
    BuildContext context,
    LeagueService service,
    String teamId,
    Color startGradient,
    Color endGradient,
  ) {
    final team = service.teams.firstWhere((t) => t.id == teamId);
    final purseLeft = service.getTeamPurseLeft(teamId);
    final totalSpend = service.getTeamSpend(teamId);
    final players = service.getTeamPlayers(teamId);
    final boughtCount = service.getBoughtCount(teamId);
    final rtmLeft = service.getRtmCardsLeft(teamId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team Banner Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [startGradient, endGradient],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          team.name.isNotEmpty ? team.name[0] : 'T',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Owner: ${team.ownerName}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade300),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '₹$purseLeft LEFT',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics Grid Box
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(child: _buildMetricItem('SPENT', '₹$totalSpend', startGradient)),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                Expanded(child: _buildMetricItem('BOUGHT', '$boughtCount players', startGradient)),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                Expanded(child: _buildMetricItem('RTM LEFT', '$rtmLeft/1', rtmLeft > 0 ? const Color(0xFFF59E0B) : Colors.grey)),
              ],
            ),
          ),

          // Squad Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ROSTER MEMBERS',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                Text(
                  '${players.length + 1}/${service.targetSquadSizePerSide} Squad',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Player Roster List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: players.length + 1, // +1 for Owner
            separatorBuilder: (ctx, idx) => Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
            itemBuilder: (ctx, index) {
              if (index == 0) {
                // Owner Captain Tile
                return Container(
                  color: const Color(0xFFFFFBEB),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, size: 18, color: Colors.white),
                    ),
                    title: Text(
                      '${team.ownerName} (Owner Captain)',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 13),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Text(
                        'CAPTAIN',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                      ),
                    ),
                  ),
                );
              }

              final person = players[index - 1];
              final signing = service.getSigningForPerson(person.id);
              final isMarquee = person.category == PlayerCategory.marquee;

              return ListTile(
                dense: true,
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isMarquee ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMarquee ? Icons.star_rounded : Icons.person_rounded,
                    size: 16,
                    color: isMarquee ? const Color(0xFFD97706) : const Color(0xFF64748B),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13),
                    ),
                    if (isMarquee) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MARQUEE',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: startGradient.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    signing != null ? '₹${signing.price}' : 'Free',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: startGradient,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color accentColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: accentColor),
          ),
        ),
      ],
    );
  }
}

class _HomeValuationsModalContent extends StatefulWidget {
  const _HomeValuationsModalContent();

  @override
  State<_HomeValuationsModalContent> createState() => _HomeValuationsModalContentState();
}

class _HomeValuationsModalContentState extends State<_HomeValuationsModalContent> {
  int _selectedTab = 0; // 0: Valuations & Ranks, 1: Match Rules
  String _roleFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final learner = StayrareAiLearner();
    final rankedList = learner.rankedPlayers;
    final totalLearned = learner.totalAuctionsLearned;

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
                          'Match Regulations',
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
              // Tab 1: Match Regulations
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildHomeRuleTile(
                      icon: Icons.account_balance_wallet_rounded,
                      title: '₹12,000 Starting Purse',
                      desc: 'Both teams start with ₹12,000 for a 10-player squad. Target average spend is ₹1,200 per player.',
                    ),
                    _buildHomeRuleTile(
                      icon: Icons.groups_rounded,
                      title: 'Squad Mandates (10 Players)',
                      desc: 'Teams must draft 10 players: max 5 pure batsmen, min 5 bowling options (Bowlers + All-Rounders).',
                    ),
                    _buildHomeRuleTile(
                      icon: Icons.style_rounded,
                      title: '1 RTM (Right-To-Match) Card',
                      desc: 'Match your opponent’s winning bid. Opponents can raise to any multiple of ₹50 before final match.',
                    ),
                    _buildHomeRuleTile(
                      icon: Icons.pause_circle_filled_rounded,
                      title: '1 Strategic Timeout (30 Seconds)',
                      desc: 'Freeze the bidding clock once per match to review squad roles, analyze purse math, and adjust tactics.',
                    ),
                    _buildHomeRuleTile(
                      icon: Icons.bolt_rounded,
                      title: 'Round 2 Accelerated Phase',
                      desc: 'Unsold players return in an accelerated round with a 40% discount on base prices.',
                    ),
                    _buildHomeRuleTile(
                      icon: Icons.trending_up_rounded,
                      title: 'Graduated IPL Bid Increments',
                      desc: '• Below ₹1,000: +₹100\n• ₹1,000 – ₹2,500: +₹250\n• Above ₹2,500: +₹500',
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

  Widget _buildHomeRuleTile({required IconData icon, required String title, required String desc}) {
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
