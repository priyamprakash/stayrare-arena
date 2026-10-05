import 'package:flutter/material.dart';
import '../services/league_provider.dart';
import '../services/league_service.dart';

class SetupView extends StatefulWidget {
  const SetupView({super.key});

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  final List<String> _selectedCaptains = [];
  late TextEditingController _team1NameController;
  late TextEditingController _team2NameController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _team1NameController = TextEditingController();
    _team2NameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final service = Provider.of<LeagueService>(context);
      _selectedCaptains.clear();
      _selectedCaptains.add(service.captain1Name);
      _selectedCaptains.add(service.captain2Name);

      _team1NameController.text = service.customTeam1Name ?? 'Team ${service.captain1Name}';
      _team2NameController.text = service.customTeam2Name ?? 'Team ${service.captain2Name}';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _team1NameController.dispose();
    _team2NameController.dispose();
    super.dispose();
  }

  void _onCaptainToggled(String name) {
    setState(() {
      if (_selectedCaptains.contains(name)) {
        _selectedCaptains.remove(name);
      } else {
        if (_selectedCaptains.length < 2) {
          _selectedCaptains.add(name);
        } else {
          // Replace second captain
          _selectedCaptains.removeLast();
          _selectedCaptains.add(name);
        }
      }

      // Automatically sync team name inputs
      if (_selectedCaptains.isNotEmpty) {
        _team1NameController.text = 'Team ${_selectedCaptains[0]}';
      }
      if (_selectedCaptains.length > 1) {
        _team2NameController.text = 'Team ${_selectedCaptains[1]}';
      }
    });
  }

  void _resetToDefault() {
    setState(() {
      _selectedCaptains.clear();
      _selectedCaptains.add('Saurabh');
      _selectedCaptains.add('Avinash');
      _team1NameController.text = 'Team Saurabh';
      _team2NameController.text = 'Team Avinash';
    });
  }

  void _saveSetup(LeagueService service) {
    if (_selectedCaptains.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select exactly 2 captains!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final cap1 = _selectedCaptains[0];
    final cap2 = _selectedCaptains[1];

    service.initializeSetup(
      cap1,
      cap2,
      customTeam1Name: _team1NameController.text.trim().isNotEmpty ? _team1NameController.text.trim() : null,
      customTeam2Name: _team2NameController.text.trim().isNotEmpty ? _team2NameController.text.trim() : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated: $cap1 (${_team1NameController.text}) & $cap2 (${_team2NameController.text})'),
        backgroundColor: const Color(0xFF0D2A20),
      ),
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<LeagueService>(context);
    final allNames = LeagueService.defaultPoolNames;
    final poolCount = allNames.length - _selectedCaptains.length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: Color(0xFF0D2A20), size: 22),
            SizedBox(width: 8),
            Text(
              'Team Names & Captains Setup',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _resetToDefault,
            icon: const Icon(Icons.restore, size: 16, color: Color(0xFFD97706)),
            label: const Text(
              'Reset Default',
              style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D2A20), Color(0xFF1B4D3E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D2A20).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configure Teams & Captains',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Default: Saurabh & Avinash. Pick any 2 players as captains and customize team names.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step 1: Select 2 Captains
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Select 2 Team Captains',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Captains become team owners (remaining 18 players enter auction)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedCaptains.length == 2 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedCaptains.length == 2 ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCaptains.length == 2 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 14,
                        color: _selectedCaptains.length == 2 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_selectedCaptains.length} / 2 Selected',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _selectedCaptains.length == 2 ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Player Selection Grid (20 players)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allNames.map((name) {
                final isSelected = _selectedCaptains.contains(name);
                final isDefaultCaptain = name == 'Saurabh' || name == 'Avinash';

                return ChoiceChip(
                  avatar: isSelected
                      ? const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFFF59E0B))
                      : (isDefaultCaptain ? const Icon(Icons.star_outline_rounded, size: 14, color: Colors.grey) : null),
                  label: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0D2A20),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0D2A20) : (isDefaultCaptain ? const Color(0xFFFDE68A) : Colors.grey.shade300),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  onSelected: (_) => _onCaptainToggled(name),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Step 2: Edit Team Names
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. Edit Team Names',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Customize each franchise name or keep the captain team name',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _team1NameController,
                          decoration: InputDecoration(
                            labelText: _selectedCaptains.isNotEmpty ? 'Team 1 (${_selectedCaptains[0]})' : 'Team 1',
                            prefixIcon: const Icon(Icons.shield_outlined, size: 18, color: Color(0xFFF59E0B)),
                            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _team2NameController,
                          decoration: InputDecoration(
                            labelText: _selectedCaptains.length > 1 ? 'Team 2 (${_selectedCaptains[1]})' : 'Team 2',
                            prefixIcon: const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF10B981)),
                            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF475569)),
                      SizedBox(width: 6),
                      Text(
                        'LEAGUE OVERVIEW',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _team1NameController.text.isNotEmpty
                                    ? _team1NameController.text
                                    : (_selectedCaptains.isNotEmpty ? 'Team ${_selectedCaptains[0]}' : 'Team 1'),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0D2A20)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Captain: ${_selectedCaptains.isNotEmpty ? _selectedCaptains[0] : "Not Selected"}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const Text(
                                'Purse: ₹10,000 • 1 RTM',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _team2NameController.text.isNotEmpty
                                    ? _team2NameController.text
                                    : (_selectedCaptains.length > 1 ? 'Team ${_selectedCaptains[1]}' : 'Team 2'),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0D2A20)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Captain: ${_selectedCaptains.length > 1 ? _selectedCaptains[1] : "Not Selected"}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const Text(
                                'Purse: ₹10,000 • 1 RTM',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      '🎯 Auction Pool: $poolCount Players in unassigned pool (2 Captains leading)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0D2A20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2A20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: _selectedCaptains.length == 2 ? () => _saveSetup(service) : null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Text(
                      'SAVE & UPDATE LEAGUE',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
