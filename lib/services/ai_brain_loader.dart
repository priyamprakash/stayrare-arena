import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ai_model_valuation.dart';

class AiBrainProfile {
  final String personaName;
  final String archetype;
  final String philosophy;

  // Strategic parameters
  final int startingPurse;
  final double scarcityMultiplier;
  final double marqueeStretchMultiplier;
  final int maxStretchPicks;
  final double emergencyWkMultiplier;
  final int bluffFrequency;
  final double bluffCeilingFactor;
  final bool denialBiddingEnabled;
  final int denialPurseThreshold;
  final int denialPurseGap;
  final int squadReserveFloor;
  final bool marqueeFirstOrder;
  final bool allowDynamicStretchAboveCeiling;
  final double dynamicPurseStretchRatio;
  final int rtmMinScore;
  final double rtmMaxMarginPercent;
  final double rtmEliteMatchMargin;

  final List<PlayerValuation> playerValuations;
  final Map<String, List<String>> trashTalkCorpus;

  const AiBrainProfile({
    required this.personaName,
    required this.archetype,
    required this.philosophy,
    required this.startingPurse,
    required this.scarcityMultiplier,
    required this.marqueeStretchMultiplier,
    required this.maxStretchPicks,
    required this.emergencyWkMultiplier,
    required this.bluffFrequency,
    required this.bluffCeilingFactor,
    required this.denialBiddingEnabled,
    required this.denialPurseThreshold,
    required this.denialPurseGap,
    required this.squadReserveFloor,
    required this.marqueeFirstOrder,
    required this.allowDynamicStretchAboveCeiling,
    required this.dynamicPurseStretchRatio,
    required this.rtmMinScore,
    required this.rtmMaxMarginPercent,
    required this.rtmEliteMatchMargin,
    required this.playerValuations,
    required this.trashTalkCorpus,
  });

  factory AiBrainProfile.fromJson(Map<String, dynamic> json) {
    final persona = json['persona'] as Map<String, dynamic>? ?? {};
    final params = json['parameters'] as Map<String, dynamic>? ?? {};
    final rawPlayers = (json['player_valuations'] as List<dynamic>?) ?? [];
    final rawTrashTalk = (json['trash_talk_corpus'] as Map<String, dynamic>?) ?? {};

    final players = rawPlayers.map((p) {
      final map = p as Map<String, dynamic>;
      final roleStr = (map['role'] as String?)?.toLowerCase() ?? 'allrounder';
      CricketRole role;
      switch (roleStr) {
        case 'bat':
        case 'batsman':
          role = CricketRole.bat;
          break;
        case 'bowl':
        case 'bowler':
          role = CricketRole.bowl;
          break;
        case 'wk':
        case 'wicketkeeper':
          role = CricketRole.wk;
          break;
        default:
          role = CricketRole.allRounder;
      }

      return PlayerValuation(
        name: map['name'] ?? 'Unknown',
        score: (map['score'] as num?)?.toInt() ?? 50,
        minCeiling: (map['min_ceiling'] as num?)?.toInt() ?? 750,
        maxCeiling: (map['max_ceiling'] as num?)?.toInt() ?? 750,
        role: role,
        roleDescription: map['role_description'] ?? 'All-Rounder',
        isMarqueeDefault: map['is_marquee'] ?? false,
      );
    }).toList();

    final corpus = <String, List<String>>{};
    rawTrashTalk.forEach((k, v) {
      if (v is List) {
        corpus[k] = v.map((e) => e.toString()).toList();
      }
    });

    return AiBrainProfile(
      personaName: persona['name'] ?? 'stayrare-model',
      archetype: persona['archetype'] ?? 'Master Tactician & Value Optimizer',
      philosophy: persona['philosophy'] ?? 'Value over replacement.',
      startingPurse: (params['starting_purse'] as num?)?.toInt() ?? 12000,
      scarcityMultiplier: (params['scarcity_multiplier'] as num?)?.toDouble() ?? 1.20,
      marqueeStretchMultiplier: (params['marquee_stretch_multiplier'] as num?)?.toDouble() ?? 1.25,
      maxStretchPicks: (params['max_stretch_picks'] as num?)?.toInt() ?? 3,
      emergencyWkMultiplier: (params['emergency_wk_multiplier'] as num?)?.toDouble() ?? 1.25,
      bluffFrequency: (params['bluff_frequency'] as num?)?.toInt() ?? 5,
      bluffCeilingFactor: (params['bluff_ceiling_factor'] as num?)?.toDouble() ?? 0.80,
      denialBiddingEnabled: params['denial_bidding_enabled'] ?? true,
      denialPurseThreshold: (params['denial_purse_threshold'] as num?)?.toInt() ?? 6500,
      denialPurseGap: (params['denial_purse_gap'] as num?)?.toInt() ?? 1500,
      squadReserveFloor: (params['squad_reserve_floor'] as num?)?.toInt() ?? 100,
      marqueeFirstOrder: params['marquee_first_order'] ?? true,
      allowDynamicStretchAboveCeiling: params['allow_dynamic_stretch_above_ceiling'] ?? true,
      dynamicPurseStretchRatio: (params['dynamic_purse_stretch_ratio'] as num?)?.toDouble() ?? 0.20,
      rtmMinScore: (params['rtm_min_score'] as num?)?.toInt() ?? 75,
      rtmMaxMarginPercent: (params['rtm_max_margin_percent'] as num?)?.toDouble() ?? 1.20,
      rtmEliteMatchMargin: (params['rtm_elite_match_margin'] as num?)?.toDouble() ?? 1.15,
      playerValuations: players.isNotEmpty ? players : StayrarePlayerDatabase.officialValuations,
      trashTalkCorpus: corpus,
    );
  }

  static AiBrainProfile defaultBrain() {
    return AiBrainProfile(
      personaName: 'stayrare-model',
      archetype: 'Master Tactician & Value Optimizer',
      philosophy: 'Value over replacement, read opponent purse depth, aggressive on top marquee stars, ruthless on mid-tier bluffs.',
      startingPurse: 12000,
      scarcityMultiplier: 1.20,
      marqueeStretchMultiplier: 1.25,
      maxStretchPicks: 3,
      emergencyWkMultiplier: 1.25,
      bluffFrequency: 5,
      bluffCeilingFactor: 0.80,
      denialBiddingEnabled: true,
      denialPurseThreshold: 6500,
      denialPurseGap: 1500,
      squadReserveFloor: 100,
      marqueeFirstOrder: true,
      allowDynamicStretchAboveCeiling: true,
      dynamicPurseStretchRatio: 0.20,
      rtmMinScore: 75,
      rtmMaxMarginPercent: 1.20,
      rtmEliteMatchMargin: 1.15,
      playerValuations: StayrarePlayerDatabase.officialValuations,
      trashTalkCorpus: const {},
    );
  }
}

class AiBrainService {
  static final AiBrainService _instance = AiBrainService._internal();
  factory AiBrainService() => _instance;
  AiBrainService._internal();

  AiBrainProfile _activeBrain = AiBrainProfile.defaultBrain();
  bool _isLoaded = false;

  AiBrainProfile get activeBrain => _activeBrain;
  bool get isLoaded => _isLoaded;

  Future<AiBrainProfile> loadBrainFromFile([String assetPath = 'assets/brain/brain.json']) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      _activeBrain = AiBrainProfile.fromJson(data);
      _isLoaded = true;
    } catch (e) {
      // Fallback cleanly to defaultBrain if running outside full asset bundle
      _activeBrain = AiBrainProfile.defaultBrain();
    }
    return _activeBrain;
  }
}
