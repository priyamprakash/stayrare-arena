import 'package:flutter/material.dart';
import '../models/league.dart';
import '../services/league_provider.dart';
import '../services/league_service.dart';

class PlayerPoolView extends StatefulWidget {
  const PlayerPoolView({super.key});

  @override
  State<PlayerPoolView> createState() => _PlayerPoolViewState();
}

class _PlayerPoolViewState extends State<PlayerPoolView> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<LeagueService>(context);

    List<Person> filteredPeople = service.people.where((p) => p.role == PersonRole.player).toList();
    if (_selectedFilter == 'Marquee') {
      filteredPeople = filteredPeople.where((p) => p.category == PlayerCategory.marquee).toList();
    } else if (_selectedFilter == 'Normal') {
      filteredPeople = filteredPeople.where((p) => p.category == PlayerCategory.normal).toList();
    } else if (_selectedFilter == 'Unsold') {
      filteredPeople = filteredPeople.where((p) => p.status == PersonStatus.pending).toList();
    } else if (_selectedFilter == 'Sold') {
      filteredPeople = filteredPeople.where((p) => p.status == PersonStatus.active).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0D2A20)),
            tooltip: 'Add Late Joiner',
            onPressed: () => _showAddLateJoinerDialog(context, service),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Marquee', 'Normal', 'Unsold', 'Sold'].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      selected: _selectedFilter == filter,
                      selectedColor: const Color(0xFF0D2A20).withOpacity(0.18),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = filter);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Player List
          Expanded(
            child: filteredPeople.isEmpty
                ? const Center(child: Text('No players match the selected filter.', style: TextStyle(color: Color(0xFF64748B))))
                : ListView.builder(
                    itemCount: filteredPeople.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final person = filteredPeople[index];
                      final signing = service.getSigningForPerson(person.id);
                      final team = signing != null
                          ? service.teams.firstWhere((t) => t.id == signing.teamId, orElse: () => TeamData(id: '', name: 'Unassigned', ownerPersonId: '', ownerName: ''))
                          : null;
                      final isMarquee = person.category == PlayerCategory.marquee;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isMarquee ? const Color(0xFFFEF3C7) : const Color(0xFF0D2A20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isMarquee ? Icons.star_rounded : Icons.person_rounded,
                              size: 20,
                              color: isMarquee ? const Color(0xFFD97706) : Colors.white,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(person.name, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 14)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => service.togglePlayerCategory(person.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isMarquee ? const Color(0xFFFEF3C7) : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    person.category.label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: isMarquee ? const Color(0xFFB45309) : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            team != null ? 'Team: ${team.name} • ${signing?.type.name}' : 'Status: ${person.status.name.toUpperCase()} • Base ₹${person.basePrice}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                signing != null ? '₹${signing.price}' : 'Base ₹${person.basePrice}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0D2A20)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(person.status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  person.status.name.toUpperCase(),
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _getStatusColor(person.status)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D2A20),
        icon: const Icon(Icons.group_add_rounded, color: Colors.white),
        label: const Text('Late Joiner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddLateJoinerDialog(context, service),
      ),
    );
  }

  Color _getStatusColor(PersonStatus status) {
    switch (status) {
      case PersonStatus.active:
        return const Color(0xFF16A34A);
      case PersonStatus.pending:
        return const Color(0xFFD97706);
      case PersonStatus.exited:
        return const Color(0xFFDC2626);
    }
  }

  void _showAddLateJoinerDialog(BuildContext context, LeagueService service) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _LateJoinerDialog(service: service),
    );
  }
}

class _LateJoinerDialog extends StatefulWidget {
  final LeagueService service;

  const _LateJoinerDialog({super.key, required this.service});

  @override
  State<_LateJoinerDialog> createState() => _LateJoinerDialogState();
}

class _LateJoinerDialogState extends State<_LateJoinerDialog> {
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
      title: const Text('Add Late Joiner', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Late joiners are automatically assigned based on fairness criteria:\n1. Team with fewer players\n2. Lower total squad value\n3. Coin toss',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
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
                  selectedColor: const Color(0xFF0D2A20).withOpacity(0.2),
                  onSelected: (val) {
                    if (val) setState(() => selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
          ],
        ),
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
              widget.service.addLateJoiner(name, selectedCategory);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name added and assigned to squad.')),
              );
            }
          },
          child: const Text('Auto-Assign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
