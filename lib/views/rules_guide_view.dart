import 'package:flutter/material.dart';

class RulesGuideView extends StatelessWidget {
  const RulesGuideView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('League Rules & Guide'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.menu_book, color: Colors.amber, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cricket League Rulebook',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Comprehensive guide on Marquee players, RTM, Reserve Rule & Match-Day balancing.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. Marquee Players Card
            _buildRuleCard(
              context: context,
              icon: Icons.star,
              iconColor: Colors.amber.shade800,
              title: '1. Marquee Players (Base Price ₹500)',
              description:
                  '• Marquee players are top-tier / star players in the league.\n'
                  '• Their bidding starts at a minimum base price of ₹500.\n'
                  '• Initial Marquee List: Sangam, Avinash, Sunny, Priyam, Rahul.\n'
                  '• Any player\'s marquee status can be toggled from the Player Directory.',
            ),
            const SizedBox(height: 14),

            // 2. Normal Players & 40-Second Auction Clock Card
            _buildRuleCard(
              context: context,
              icon: Icons.timer,
              iconColor: const Color(0xFF1B4D3E),
              title: '2. Bidding Increments & 40-Second Clock',
              description:
                  '• All other pool players start at a base price of ₹100.\n'
                  '• Bid increments start at +₹100 up to ₹1,000, and +₹250 above ₹1,000.\n'
                  '• 40-Second Clock: Once a player is added to the arena, a 40s timer starts.\n'
                  '• 30s Warning: If no team increases the bid for >30 seconds, a warning ("Going once... Going twice!") triggers for the remaining 10 seconds.\n'
                  '• Placing a bid resets the 40s clock.',
            ),
            const SizedBox(height: 14),

            // 3. RTM (Right to Match) Card
            _buildRuleCard(
              context: context,
              icon: Icons.verified,
              iconColor: Colors.indigo,
              title: '3. RTM (Right to Match) Cards',
              description:
                  '• What is RTM? Each team gets 1 RTM card for the entire auction.\n'
                  '• Like LSG vs PBKS for Rishabh Pant: If Team A places the highest bid, Team B can trigger RTM.\n'
                  '• Team A then gets one FINAL chance to increase their bid.\n'
                  '• Team B is asked if they want to match this new final bid.\n'
                  '• If matched, Team B wins the player at that final price. If declined, Team A gets the player.\n'
                  '• Once used, a team\'s RTM card count becomes 0/1.',
            ),
            const SizedBox(height: 14),

            // 4. Reserve Rule Card
            _buildRuleCard(
              context: context,
              icon: Icons.account_balance_wallet,
              iconColor: Colors.teal.shade800,
              title: '4. Reserve Rule (Fair Purse Limit)',
              description:
                  '• Formula: maxBid = Purse Left - ₹100 × (Slots Still Needed - 1).\n'
                  '• Ensures an owner cannot overbid so high that they cannot afford the minimum base price (₹100) for their remaining required squad slots.',
            ),
            const SizedBox(height: 14),

            // 5. Unsold Players & Exits Card
            _buildRuleCard(
              context: context,
              icon: Icons.replay,
              iconColor: Colors.orange.shade800,
              title: '5. Unsold Players & Player Exits',
              description:
                  '• Unsold Players: If no team bids for a player, they return to the unassigned pool and can be auctioned again in subsequent rounds.\n'
                  '• Player Exits: If a bought player leaves or drops out before or during the league, 100% of their sold price is refunded back to their team\'s purse!',
            ),
            const SizedBox(height: 14),

            // 6. Flexible Match-Day Rosters Card
            _buildRuleCard(
              context: context,
              icon: Icons.event_available,
              iconColor: Colors.purple.shade800,
              title: '6. Match-Day Roster & Squad Size',
              description:
                  '• Match Size: Default 10-a-side, easily adjustable to 11-a-side or custom from the Match-Day tab.\n'
                  '• Owner Protection: Captains cannot sit out.\n'
                  '• Common Players: If one side has extra players, up to 2 play as common players for both teams.\n'
                  '• Fair Sit-Out Rotation: Tracks sit-out counts so no player sits out twice before everyone else has sat once.',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withAlpha(25),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF444444)),
            ),
          ],
        ),
      ),
    );
  }
}
