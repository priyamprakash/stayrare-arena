import 'package:flutter/material.dart';
import '../models/league.dart';
import '../services/league_provider.dart';
import '../services/league_service.dart';

class MatchDayView extends StatefulWidget {
  const MatchDayView({super.key});

  @override
  State<MatchDayView> createState() => _MatchDayViewState();
}

class _MatchDayViewState extends State<MatchDayView> {
  int _selectedMatchNum = 1;

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<LeagueService>(context);
    final activePeople = service.people.where((p) => p.status == PersonStatus.active).toList();
    final currentRoster = service.matchRosters[_selectedMatchNum] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match-Day & Check-In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match & Squad Size Selector Bar
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Match:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _selectedMatchNum,
                          items: List.generate(LeagueService.matchesPlanned, (i) => i + 1).map((m) {
                            return DropdownMenuItem<int>(
                              value: m,
                              child: Text('Match #$m', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMatchNum = val);
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Side Size:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: service.targetSquadSizePerSide,
                          items: [8, 9, 10, 11, 12].map((size) {
                            return DropdownMenuItem<int>(
                              value: size,
                              child: Text('$size-a-side', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) service.setTargetSquadSizePerSide(val);
                          },
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4D3E)),
                      icon: const Icon(Icons.group, color: Colors.white),
                      label: const Text('Generate Roster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        service.generateMatchRoster(_selectedMatchNum);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Attendance Check-In Section
            Card(
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text(
                  'Match #$_selectedMatchNum Attendance Check-In (${activePeople.length} Total)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
                ),
                subtitle: Text('Target: ${service.targetSquadSizePerSide}-a-side • Select In / Out / Maybe', style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activePeople.length,
                    separatorBuilder: (ctx, idx) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final person = activePeople[index];
                      final currentAtt = service.getAttendance(_selectedMatchNum, person.id);

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: person.role == PersonRole.owner ? Colors.amber : const Color(0xFF1B4D3E),
                          child: Icon(
                            person.role == PersonRole.owner ? Icons.star : Icons.person,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        trailing: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SegmentedButton<AttendanceStatus>(
                            segments: const [
                              ButtonSegment(
                                value: AttendanceStatus.inStatus,
                                label: Text('In', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              ButtonSegment(
                                value: AttendanceStatus.maybeStatus,
                                label: Text('Maybe', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              ButtonSegment(
                                value: AttendanceStatus.outStatus,
                                label: Text('Out', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            selected: {currentAtt},
                            onSelectionChanged: (Set<AttendanceStatus> newSelection) {
                              service.updateAttendance(_selectedMatchNum, person.id, newSelection.first);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Match Roster Results
            const Text('Match Roster Output', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),

            currentRoster.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No roster generated yet. Tap "Generate Roster" above to auto-balance Playing XI, Common Players, and Sit-Outs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF666666)),
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: service.teams.map((team) {
                      final teamEntries = currentRoster.where((r) => r.teamId == team.id).toList();

                      final playing = teamEntries.where((r) => r.role == MatchRosterRole.playing).toList();
                      final common = teamEntries.where((r) => r.role == MatchRosterRole.common).toList();
                      final sitouts = teamEntries.where((r) => r.role == MatchRosterRole.sitout).toList();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${team.name} Roster (${playing.length} Playing)',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
                              ),
                              const SizedBox(height: 8),

                              // Playing XI
                              const Text('Playing XI:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                              Wrap(
                                spacing: 6,
                                children: playing.map((e) {
                                  final p = service.people.firstWhere((p) => p.id == e.personId);
                                  return Chip(
                                    avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                    label: Text(p.name, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),

                              // Common Players
                              if (common.isNotEmpty) ...[
                                const Text('Common Players (Bat & Field for Both):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                                Wrap(
                                  spacing: 6,
                                  children: common.map((e) {
                                    final p = service.people.firstWhere((p) => p.id == e.personId);
                                    return Chip(
                                      avatar: const Icon(Icons.swap_horiz, size: 14, color: Colors.orange),
                                      label: Text(p.name, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Sitouts
                              if (sitouts.isNotEmpty) ...[
                                const Text('Sitting Out (Fair Rotation):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                                Wrap(
                                  spacing: 6,
                                  children: sitouts.map((e) {
                                    final p = service.people.firstWhere((p) => p.id == e.personId);
                                    final count = service.sitOutCounts[p.id] ?? 0;
                                    return Chip(
                                      avatar: const Icon(Icons.block, size: 14, color: Colors.red),
                                      label: Text('${p.name} ($count sitouts total)', style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
