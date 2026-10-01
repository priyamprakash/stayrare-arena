import 'package:flutter/material.dart';
import '../models/league.dart';
import '../services/league_provider.dart';
import '../services/league_service.dart';
import 'setup_view.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<LeagueService>(context);
    final activePlayers = service.people.where((p) => p.status == PersonStatus.active && p.role == PersonRole.player).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin & Audit Log'),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: Color(0xFF0D2A20)),
              tooltip: 'Captains & League Setup',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const SetupView()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF1B4D3E),
            unselectedLabelColor: Color(0xFF555555),
            indicatorColor: Color(0xFF1B4D3E),
            tabs: [
              Tab(text: 'Exits & Refunds'),
              Tab(text: 'Trades'),
              Tab(text: 'Audit Log'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildExitsAndRefundsTab(context, service, activePlayers),
            _buildTradesTab(context, service, activePlayers),
            _buildAuditLogTab(context, service),
          ],
        ),
      ),
    );
  }

  Widget _buildExitsAndRefundsTab(BuildContext context, LeagueService service, List<Person> activePlayers) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Process Player Exit',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          const Text(
            'Before Match 1: 100% refund to team purse.\nBetween matches: 50% refund to team purse.',
            style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 16),
          if (activePlayers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No active bought players available for exit.', style: TextStyle(color: Color(0xFF666666)))),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activePlayers.length,
              itemBuilder: (context, index) {
                final person = activePlayers[index];
                final signing = service.getSigningForPerson(person.id);
                final team = signing != null
                    ? service.teams.firstWhere((t) => t.id == signing.teamId, orElse: () => TeamData(id: '', name: 'None', ownerPersonId: '', ownerName: ''))
                    : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    subtitle: Text('Team: ${team?.name} • Bought at ₹${signing?.price ?? 0}', style: const TextStyle(color: Color(0xFF555555))),
                    trailing: OutlinedButton(
                      onPressed: () => _showExitConfirmation(context, service, person),
                      child: const Text('Exit & Refund', style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context, LeagueService service, Person person) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Exit for ${person.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '100% of original price will be refunded back to team purse.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Exit',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                service.processPlayerExit(person.id, reason);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${person.name} marked as exited.')),
                );
              }
            },
            child: const Text('Confirm Exit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTradesTab(BuildContext context, LeagueService service, List<Person> activePlayers) {
    if (service.teams.isEmpty) return const SizedBox.shrink();
    
    final t1Id = service.teams[0].id;
    final t2Id = service.teams[1].id;
    final t1Name = service.teams[0].name;
    final t2Name = service.teams[1].name;

    final t1Players = activePlayers.where((p) => service.getSigningForPerson(p.id)?.teamId == t1Id).toList();
    final t2Players = activePlayers.where((p) => service.getSigningForPerson(p.id)?.teamId == t2Id).toList();

    String? selectedT1PersonId = t1Players.isNotEmpty ? t1Players.first.id : null;
    String? selectedT2PersonId = t2Players.isNotEmpty ? t2Players.first.id : null;

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1-for-1 Player Trade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Text('Swap players between $t1Name and $t2Name.', style: const TextStyle(color: Color(0xFF555555))),
              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$t1Name Player:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: selectedT1PersonId,
                                isExpanded: true,
                                decoration: const InputDecoration(border: OutlineInputBorder()),
                                items: t1Players.map((p) {
                                  return DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(color: Colors.black87)));
                                }).toList(),
                                onChanged: (val) => setState(() => selectedT1PersonId = val),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Icon(Icons.swap_horiz, size: 32, color: Color(0xFF1B4D3E)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$t2Name Player:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: selectedT2PersonId,
                                isExpanded: true,
                                decoration: const InputDecoration(border: OutlineInputBorder()),
                                items: t2Players.map((p) {
                                  return DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(color: Colors.black87)));
                                }).toList(),
                                onChanged: (val) => setState(() => selectedT2PersonId = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$t1Name Player:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: selectedT1PersonId,
                            isExpanded: true,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: t1Players.map((p) {
                              return DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(color: Colors.black87)));
                            }).toList(),
                            onChanged: (val) => setState(() => selectedT1PersonId = val),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Icon(Icons.swap_vert, size: 32, color: Color(0xFF1B4D3E)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$t2Name Player:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: selectedT2PersonId,
                            isExpanded: true,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: t2Players.map((p) {
                              return DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(color: Colors.black87)));
                            }).toList(),
                            onChanged: (val) => setState(() => selectedT2PersonId = val),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.sync_alt, color: Colors.white),
                  label: const Text('Execute Trade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: (selectedT1PersonId != null && selectedT2PersonId != null)
                      ? () {
                          service.processTrade(selectedT1PersonId!, selectedT2PersonId!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Trade executed successfully.')),
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuditLogTab(BuildContext context, LeagueService service) {
    final logs = service.auditLogs.reversed.toList();

    return logs.isEmpty
        ? const Center(child: Text('No audit logs recorded.', style: TextStyle(color: Color(0xFF666666))))
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            separatorBuilder: (ctx, idx) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];

              return ListTile(
                dense: true,
                leading: const Icon(Icons.history, color: Color(0xFF1B4D3E)),
                title: Text('${log.action} (${log.actor})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                subtitle: Text(log.details, style: const TextStyle(color: Color(0xFF555555))),
                trailing: Text(
                  '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF777777)),
                ),
              );
            },
          );
  }
}
