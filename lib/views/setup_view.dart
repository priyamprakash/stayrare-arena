import 'package:flutter/material.dart';
import '../services/league_provider.dart';
import '../services/league_service.dart';

class SetupView extends StatefulWidget {
  const SetupView({super.key});

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  final Set<String> _selectedCaptains = {};

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<LeagueService>(context);
    final allNames = service.defaultPoolNames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('League Setup'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 48, color: Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            const Text(
              'Select Exactly 2 Captains',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'These 2 players will be the team owners and will not go to the auction pool.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedCaptains.length == 2 ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Selected: ${_selectedCaptains.length} / 2',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _selectedCaptains.length == 2 ? const Color(0xFF16A34A) : const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: allNames.length,
                itemBuilder: (context, index) {
                  final name = allNames[index];
                  final isSelected = _selectedCaptains.contains(name);
                  return ChoiceChip(
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0D2A20),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedCaptains.length < 2) {
                            _selectedCaptains.add(name);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('You can only select 2 captains!')),
                            );
                          }
                        } else {
                          _selectedCaptains.remove(name);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2A20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _selectedCaptains.length == 2
                    ? () {
                        final caps = _selectedCaptains.toList();
                        service.initializeSetup(caps[0], caps[1]);
                      }
                    : null,
                child: const Text(
                  'START AUCTION',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
