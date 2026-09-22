import 'package:flutter/material.dart';
import '../models/league.dart';
import '../services/league_provider.dart';
import '../services/league_service.dart';
import 'rules_guide_view.dart';

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
                    color: const Color(0xFF0D2A20).withOpacity(0.3),
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
            const SizedBox(height: 20),

            // Teams Row / Layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCoolTeamCard(context, service, 'team_rohan', const Color(0xFF0D2A20), const Color(0xFF1B4D3E))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCoolTeamCard(context, service, 'team_saurabh', const Color(0xFF064E3B), const Color(0xFF047857))),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildCoolTeamCard(context, service, 'team_rohan', const Color(0xFF0D2A20), const Color(0xFF1B4D3E)),
                    const SizedBox(height: 20),
                    _buildCoolTeamCard(context, service, 'team_saurabh', const Color(0xFF064E3B), const Color(0xFF047857)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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
            color: Colors.black.withOpacity(0.05),
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
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          team.name[5], // 'R' or 'S'
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
                            color: Colors.black.withOpacity(0.15),
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
                    color: startGradient.withOpacity(0.08),
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
