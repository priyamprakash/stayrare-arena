import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Expressive auctioneer vocal tones calibrated with a resonant male baritone
enum AuctionTone {
  normal,     // Confident male auctioneer intonation (pitch ~0.94)
  hype,       // Peak energy, victory, massive outbid, hammer down (pitch ~1.08 - 1.14)
  tense,      // Rising stakes, final seconds, going twice, RTM (pitch ~1.00 - 1.05)
  trashTalk,  // Sarcastic, mocking, competitive banter in deep baritone (pitch ~0.90 - 0.96)
  analytical, // Deep, calculated, tactical, passing (pitch ~0.86 - 0.92)
}

class _QueuedSpeech {
  final String text;
  final AuctionTone tone;
  final double? customPitch;
  final double? customRate;

  _QueuedSpeech({
    required this.text,
    required this.tone,
    this.customPitch,
    this.customRate,
  });
}

class AuctionVoiceService extends ChangeNotifier {
  static final AuctionVoiceService _instance = AuctionVoiceService._internal();
  factory AuctionVoiceService() => _instance;

  AuctionVoiceService._internal();

  final Random _rng = Random();
  FlutterTts? _tts;
  bool _isInitialized = false;
  bool _isEnabled = true;
  bool _isSledgeAudioEnabled = true;
  bool _isSpeaking = false;
  String _lastSpoken = '';
  String? _lastError;

  // Speech Queue for sequential dual-voice playback
  final List<_QueuedSpeech> _speechQueue = [];
  Completer<void>? _currentCompleter;
  bool _isProcessingQueue = false;

  // Dual distinct voices: 1 for Auctioneer, 1 for Stayrare Owner (trash talker)
  Map<dynamic, dynamic>? _auctioneerVoice;
  Map<dynamic, dynamic>? _ownerVoice;
  String? _currentlyActiveVoiceName;

  bool get isEnabled => _isEnabled;
  bool get isSledgeAudioEnabled => _isSledgeAudioEnabled;
  bool get isSpeaking => _isSpeaking;
  String get lastSpoken => _lastSpoken;
  String? get lastError => _lastError;

  void toggleVoice() {
    _isEnabled = !_isEnabled;
    if (!_isEnabled) {
      stop();
    }
    notifyListeners();
  }

  void toggleSledgeAudio() {
    _isSledgeAudioEnabled = !_isSledgeAudioEnabled;
    notifyListeners();
  }

  void setSledgeAudioEnabled(bool enabled) {
    _isSledgeAudioEnabled = enabled;
    notifyListeners();
  }

  double get _basePlatformRate {
    if (!kIsWeb) {
      if (Platform.isIOS || Platform.isMacOS) {
        return 0.55; // iOS/macOS natural, quick human speech
      } else if (Platform.isAndroid) {
        return 1.14; // Android crisp & punchy
      }
    }
    return 1.10; // Web
  }

  Future<void> _initTts() async {
    if (_isInitialized && _tts != null) return;

    try {
      WidgetsFlutterBinding.ensureInitialized();
      _tts = FlutterTts();
      _setupHandlers();

      if (!kIsWeb) {
        if (Platform.isIOS || Platform.isMacOS) {
          try {
            await _tts?.setIosAudioCategory(
              IosTextToSpeechAudioCategory.playback,
              [
                IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
                IosTextToSpeechAudioCategoryOptions.allowBluetooth,
                IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
                IosTextToSpeechAudioCategoryOptions.mixWithOthers,
              ],
            );
          } catch (e) {
            debugPrint('iOS/macOS audio category notice: $e');
          }
        }
      }

      await _tts?.setVolume(1.0);
      await _tts?.setSpeechRate(_basePlatformRate);
      await _tts?.setPitch(1.0);

      // Select two completely distinct natural voices: Auctioneer vs Stayrare Owner
      await _selectBestNaturalVoice();

      _isInitialized = true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('TTS setup notice: $e');
    }
  }

  Future<void> _selectBestNaturalVoice() async {
    try {
      final dynamic voices = await _tts?.getVoices;
      if (voices is List && voices.isNotEmpty) {
        final List<Map<dynamic, dynamic>> maleVoices = [];
        final List<Map<dynamic, dynamic>> femaleVoices = [];
        final List<Map<dynamic, dynamic>> allVoices = [];

        for (final v in voices) {
          if (v is Map) {
            allVoices.add(v);
            final name = (v['name'] ?? '').toString().toLowerCase();
            final isFemale = name.contains('female') ||
                name.contains('samantha') ||
                name.contains('victoria') ||
                name.contains('karen') ||
                name.contains('serena') ||
                name.contains('zira');

            if (isFemale) {
              femaleVoices.add(v);
            } else {
              maleVoices.add(v);
            }
          }
        }

        // 1. Pick Auctioneer Voice (Fast, crisp announcer - prefer Indian English / British male)
        for (final v in maleVoices) {
          final name = (v['name'] ?? '').toString().toLowerCase();
          final locale = (v['locale'] ?? '').toString().toLowerCase();
          if (locale.contains('en-in') || locale.contains('hi-in') || name.contains('rishi') || name.contains('india')) {
            _auctioneerVoice = v;
            break;
          }
        }
        _auctioneerVoice ??= maleVoices.firstWhere(
          (v) => (v['locale'] ?? '').toString().toLowerCase().contains('en-gb'),
          orElse: () => maleVoices.isNotEmpty ? maleVoices.first : allVoices.first,
        );

        // 2. Pick Stayrare Owner Voice (Heavy, deep, distinct male - prefer American/Deep male)
        final auctioneerName = _auctioneerVoice?['name']?.toString().toLowerCase() ?? '';
        for (final v in maleVoices) {
          final name = (v['name'] ?? '').toString().toLowerCase();
          final locale = (v['locale'] ?? '').toString().toLowerCase();
          if (name != auctioneerName) {
            if (name.contains('alex') ||
                name.contains('fred') ||
                name.contains('ralph') ||
                name.contains('bruce') ||
                name.contains('david') ||
                name.contains('aaron') ||
                name.contains('george') ||
                name.contains('arthur') ||
                name.contains('daniel') ||
                locale.contains('en-us') ||
                locale.contains('en-au')) {
              _ownerVoice = v;
              break;
            }
          }
        }

        // Fallback for Owner: any voice distinct from auctioneer
        _ownerVoice ??= maleVoices.firstWhere(
          (v) => (v['name'] ?? '').toString().toLowerCase() != auctioneerName,
          orElse: () => allVoices.firstWhere(
            (v) => (v['name'] ?? '').toString().toLowerCase() != auctioneerName,
            orElse: () => _auctioneerVoice ?? allVoices.first,
          ),
        );

        // Initialize with Auctioneer voice by default
        if (_auctioneerVoice != null) {
          try {
            final locale = _auctioneerVoice!['locale']?.toString();
            if (locale != null && locale.isNotEmpty) {
              await _tts?.setLanguage(locale);
            }
            await _tts?.setVoice({
              "name": _auctioneerVoice!['name'].toString(),
              "locale": locale ?? '',
            });
            _currentlyActiveVoiceName = _auctioneerVoice!['name'].toString();
          } catch (_) {}
        }
      }

      // Default language fallback
      try {
        final available = await _tts?.getLanguages;
        if (available is List && available.contains('en-IN')) {
          await _tts?.setLanguage('en-IN');
        } else if (available is List && available.contains('en-GB')) {
          await _tts?.setLanguage('en-GB');
        } else {
          await _tts?.setLanguage('en');
        }
      } catch (_) {
        await _tts?.setLanguage('en-IN');
      }
    } catch (e) {
      debugPrint('Voice selection fallback: $e');
    }
  }

  void _setupHandlers() {
    _tts?.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _tts?.setCompletionHandler(() {
      _isSpeaking = false;
      if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
        _currentCompleter!.complete();
      }
      notifyListeners();
    });

    _tts?.setCancelHandler(() {
      _isSpeaking = false;
      if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
        _currentCompleter!.complete();
      }
      notifyListeners();
    });

    _tts?.setErrorHandler((msg) {
      _isSpeaking = false;
      _lastError = msg.toString();
      debugPrint('TTS runtime error: $msg');
      if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
        _currentCompleter!.complete();
      }
      notifyListeners();
    });
  }

  /// Indian Phonetic Pronunciation Engine
  static String _phoneticClean(String text) {
    String s = text;

    // Clean currency formatting for smooth natural pronunciation
    s = s.replaceAllMapped(RegExp(r'₹(\d+(?:,\d+)*)'), (m) => '${m[1]} Rupees');
    s = s.replaceAll('₹', 'Rupees ');

    // Indian Player & Patna Franchise phonetic pronunciation dictionary
    final Map<String, String> indianPronunciations = {
      r'\bPriyam\b': 'Pree-yum',
      r'\bAshutosh\b': 'Aashu-tosh',
      r'\bAvinash\b': 'Uh-vee-naash',
      r'\bSangam\b': 'Sun-gum',
      r'\bSaurabh\b': 'Saw-rabh',
      r'\bRahul\b': 'Raa-hool',
      r'\bRitesh\b': 'Ree-tesh',
      r'\bAman\b': 'Uh-maan',
      r'\bIkschit\b': 'Ik-shit',
      r'\bAlok\b': 'Aa-loke',
      r'\bAmit\b': 'Uh-meet',
      r'\bTinku\b': 'Ting-koo',
      r'\bMohan\b': 'Mo-hun',
      r'\bPiyush\b': 'Pee-yoosh',
      r'\bRohan\b': 'Ro-hun',
      r'\bSatish\b': 'Suh-teesh',
      r'\bNiranjan\b': 'Nee-run-jun',
      r'\bMohit\b': 'Mo-heet',
      r'\bShaurya\b': 'Show-rya',
      r'\bAashish\b': 'Aashish',
      r'\bDev\b': 'Dave',
      r'\bDanapur\b': 'Daana-pur',
      r'\bDabangg\b': 'Duh-bung',
      r'\bBailey\b': 'Bailey',
      r'\bMithapur\b': 'Meetha-pur',
      r'\bRajvanshi\b': 'Raaj-vun-shee',
      r'\bPatliputra\b': 'Paatlee-pootra',
      r'\bKankarbagh\b': 'Kunkur-baagh',
      r'\bPatna\b': 'Put-na',
    };

    indianPronunciations.forEach((pattern, replacement) {
      s = s.replaceAll(RegExp(pattern, caseSensitive: false), replacement);
    });

    return s;
  }

  /// Speak with dynamic male pitch, tempo modulation, and natural human prosody
  Future<void> speak(
    String text, {
    AuctionTone tone = AuctionTone.normal,
    double? customPitch,
    double? customRate,
    bool interrupt = true,
  }) async {
    if (!_isEnabled) return;

    final isOwnerSledge = (tone == AuctionTone.trashTalk || tone == AuctionTone.analytical);
    if (!_isSledgeAudioEnabled && isOwnerSledge) {
      return;
    }

    _lastSpoken = text;

    if (interrupt) {
      _speechQueue.clear();
      if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
        _currentCompleter!.complete();
      }
      try {
        await _tts?.stop();
      } catch (_) {}
    }

    _speechQueue.add(_QueuedSpeech(
      text: text,
      tone: tone,
      customPitch: customPitch,
      customRate: customRate,
    ));

    unawaited(_processQueue());
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      while (_speechQueue.isNotEmpty) {
        if (!_isEnabled) {
          _speechQueue.clear();
          break;
        }

        final item = _speechQueue.removeAt(0);

        final isOwnerSledge = (item.tone == AuctionTone.trashTalk || item.tone == AuctionTone.analytical);
        if (!_isSledgeAudioEnabled && isOwnerSledge) {
          continue;
        }

        await _playSingleUtterance(item);
        if (_speechQueue.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _playSingleUtterance(_QueuedSpeech item) async {
    try {
      if (!_isInitialized || _tts == null) {
        await _initTts();
      }

      final isOwner = (item.tone == AuctionTone.trashTalk || item.tone == AuctionTone.analytical);

      // Pitch & tempo modulation: Crisp high energetic Auctioneer vs Deep Heavy Bass Stayrare Owner
      double targetPitch;
      double rateMultiplier = 1.0;
      final jitter = (_rng.nextDouble() * 0.04) - 0.02;

      switch (item.tone) {
        case AuctionTone.hype:
          targetPitch = 1.15 + (_rng.nextDouble() * 0.05); // High energy crisp announcer
          rateMultiplier = 1.10;
          break;
        case AuctionTone.tense:
          targetPitch = 1.08 + (_rng.nextDouble() * 0.04); // Fast-paced announcer
          rateMultiplier = 1.08;
          break;
        case AuctionTone.normal:
          targetPitch = 1.02 + jitter; // Crisp masculine announcer pitch
          rateMultiplier = 1.04;
          break;
        case AuctionTone.trashTalk:
          targetPitch = 0.55 + ((_rng.nextDouble() * 0.04) - 0.02); // Heavy, deep male bass owner voice
          rateMultiplier = 0.80; // Slower, menacing, mocking owner cadence
          break;
        case AuctionTone.analytical:
          targetPitch = 0.60 + ((_rng.nextDouble() * 0.04) - 0.02); // Deep tactical owner voice
          rateMultiplier = 0.84;
          break;
      }

      final finalPitch = item.customPitch ?? (targetPitch.clamp(0.50, 1.40));
      final finalRate = item.customRate ?? (_basePlatformRate * rateMultiplier);

      try {
        await _tts?.setPitch(finalPitch);
        await _tts?.setSpeechRate(finalRate);
      } catch (_) {}

      // Apply distinct voice profile
      final targetVoice = isOwner ? _ownerVoice : _auctioneerVoice;
      if (targetVoice != null) {
        final targetVoiceName = targetVoice['name'].toString();
        if (_currentlyActiveVoiceName != targetVoiceName) {
          try {
            await _tts?.setVoice({
              "name": targetVoiceName,
              "locale": targetVoice['locale']?.toString() ?? '',
            });
            _currentlyActiveVoiceName = targetVoiceName;
          } catch (_) {}
        }
      }

      final phoneticText = _phoneticClean(item.text);
      _isSpeaking = true;
      notifyListeners();

      _currentCompleter = Completer<void>();
      await _tts?.speak(phoneticText);

      final wordCount = phoneticText.split(RegExp(r'\s+')).length;
      final estimatedDurationMs = ((wordCount / (finalRate * 2.8)) * 1000).toInt().clamp(1200, 12000);

      await Future.any([
        _currentCompleter!.future,
        Future.delayed(Duration(milliseconds: estimatedDurationMs)),
      ]);
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Voice engine speak error: $e');
    } finally {
      _isSpeaking = false;
      _currentCompleter = null;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      _speechQueue.clear();
      if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
        _currentCompleter!.complete();
      }
      await _tts?.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (_) {}
  }

  /// Interactive test button sound test (demonstrates both distinct voices)
  Future<void> testSpeech() async {
    _isEnabled = true;
    // 1. Crisp energetic Auctioneer
    await speak(
      "Opening bid on the table! ₹500 from Danapur Dabangg!",
      tone: AuctionTone.hype,
      interrupt: true,
    );
    // 2. Heavy bass Stayrare Owner
    await Future.delayed(const Duration(milliseconds: 350));
    await speak(
      "Keep bidding boss, your purse is running dry already!",
      tone: AuctionTone.trashTalk,
      interrupt: false,
    );
  }

  // =========================================================
  // CRICKET AUCTIONEER ANNOUNCER VOICE SCRIPTS (MALE TONE)
  // =========================================================

  /// Announce player stepping up to the block with natural human enthusiasm
  Future<void> announcePlayerOnBlock({
    required String playerName,
    required String role,
    required int basePrice,
    bool isAccelerated = false,
  }) async {
    if (!_isEnabled) return;

    final templates = isAccelerated
        ? [
            "Accelerated round! $playerName is on the table, base ₹$basePrice. Let's move fast!",
            "Lightning round! $playerName, $role, opens at ₹$basePrice. Who wants him?!",
          ]
        : [
            "Next up... $playerName! $role, opening at ₹$basePrice. Who takes the first bid?!",
            "Here comes $playerName! Opening at ₹$basePrice. Let's see those paddles!",
            "On the block now: $playerName! A crucial $role. Base price ₹$basePrice. Who's in?!",
          ];

    final script = templates[_rng.nextInt(templates.length)];
    await speak(script, tone: isAccelerated ? AuctionTone.hype : AuctionTone.normal);
  }

  /// Announce a new incoming bid
  Future<void> announceBid({
    required String bidderName,
    required int amount,
    required String playerName,
    bool isJumpBid = false,
  }) async {
    if (!_isEnabled) return;

    if (isJumpBid) {
      await speak("Aggressive jump bid! $bidderName leaps to ₹$amount for $playerName!", tone: AuctionTone.hype, interrupt: true);
      return;
    }

    final templates = [
      "₹$amount from $bidderName!",
      "We have ₹$amount! $bidderName in the lead!",
      "₹$amount on the board by $bidderName!",
      "Bid is in! ₹$amount from $bidderName!",
      "Raised to ₹$amount by $bidderName!",
    ];

    final script = templates[_rng.nextInt(templates.length)];
    await speak(script, tone: AuctionTone.tense, interrupt: true);
  }

  /// Announce AI counter-bid: Auctioneer announces bid first, then Stayrare Owner delivers trash talk in heavy bass voice
  Future<void> announceAiBidWithTrashTalk({
    required String bidderName,
    required int amount,
    required String playerName,
    required String trashTalk,
  }) async {
    if (!_isEnabled) return;
    // 1. Announcer calls out the bid
    await speak("₹$amount from $bidderName!", tone: AuctionTone.tense, interrupt: true);
    // 2. Stayrare owner sledges the user in deep bass voice
    await Future.delayed(const Duration(milliseconds: 250));
    await speak(trashTalk, tone: AuctionTone.trashTalk, interrupt: false);
  }

  /// Announce AI passing: Auctioneer calls out pass, then Stayrare Owner delivers banter in heavy bass voice
  Future<void> announceAiPassWithBanter({
    required String aiTeamName,
    required String playerName,
    required String banter,
  }) async {
    if (!_isEnabled) return;
    // 1. Announcer calls out the pass
    await speak("$aiTeamName passes on $playerName!", tone: AuctionTone.normal, interrupt: true);
    // 2. Stayrare owner delivers banter
    await Future.delayed(const Duration(milliseconds: 250));
    await speak(banter, tone: AuctionTone.trashTalk, interrupt: false);
  }

  /// Announce Marquee player arrival: Auctioneer introduces marquee star, then Stayrare Owner sledges
  Future<void> announceMarqueeArrivalSledge({
    required String playerName,
    required String sledge,
  }) async {
    if (!_isEnabled) return;
    // 1. Announcer calls out marquee arrival
    await speak("Marquee star $playerName is on the block!", tone: AuctionTone.hype, interrupt: true);
    // 2. Stayrare owner sledges
    await Future.delayed(const Duration(milliseconds: 300));
    await speak(sledge, tone: AuctionTone.trashTalk, interrupt: false);
  }

  /// Direct user sledge when user taps mascot avatar
  Future<void> sledgeUser(String sledge) async {
    if (!_isEnabled) return;
    await speak(sledge, tone: AuctionTone.trashTalk, interrupt: true);
  }

  /// Announce dramatic gavel stage with rising human pitch
  Future<void> announceGavelStage({
    required String stage, // 'goingOnce', 'goingTwice'
    required int amount,
    required String bidderName,
    required String playerName,
  }) async {
    if (!_isEnabled) return;

    if (stage == 'goingOnce') {
      final templates = [
        "₹$amount, going once to $bidderName!",
        "At ₹$amount, going once!",
        "Going once at ₹$amount... anyone else?!",
      ];
      final script = templates[_rng.nextInt(templates.length)];
      await speak(script, tone: AuctionTone.tense, interrupt: true);
    } else if (stage == 'goingTwice') {
      final templates = [
        "Going twice at ₹$amount! Last call to counter $bidderName!",
        "Going twice for $playerName! Don't miss out at ₹$amount!",
        "Fair warning! ₹$amount, going twice!",
      ];
      final script = templates[_rng.nextInt(templates.length)];
      await speak(script, tone: AuctionTone.hype, interrupt: true);
    }
  }

  /// Announce player sold with hammer-down excitement
  Future<void> announceSold({
    required String playerName,
    required int amount,
    required String winnerName,
  }) async {
    if (!_isEnabled) return;

    final templates = [
      "HAMMER DOWN! Sold to $winnerName for ₹$amount! What a deal!",
      "SOLD! $playerName goes to $winnerName at ₹$amount!",
      "And... SOLD! ₹$amount to $winnerName! Contract signed!",
    ];

    final script = templates[_rng.nextInt(templates.length)];
    await speak(script, tone: AuctionTone.hype, interrupt: true);
  }

  /// Announce player unsold
  Future<void> announceUnsold({required String playerName}) async {
    if (!_isEnabled) return;

    final templates = [
      "No bids? Pass! $playerName goes unsold for now.",
      "Unsold! Moving on from $playerName.",
      "Hammer down, unsold. We proceed to the next player.",
    ];

    final script = templates[_rng.nextInt(templates.length)];
    await speak(script, tone: AuctionTone.normal, interrupt: true);
  }

  // =========================================================
  // COMPLETE RTM (RIGHT TO MATCH) PHASES VOICE ANNOUNCEMENTS
  // =========================================================

  /// Phase 1: User has opportunity to trigger RTM
  Future<void> announceRtmPrompt({
    required String teamName,
    required String playerName,
  }) async {
    if (!_isEnabled) return;
    final script = "$teamName holds the Right To Match card! Do you wish to match and retain $playerName?";
    await speak(script, tone: AuctionTone.tense, interrupt: true);
  }

  /// Phase 2: RTM card is invoked by a team
  Future<void> announceRtmInvoked({
    required String rtmTeam,
    required String playerName,
    required String highestBidder,
  }) async {
    if (!_isEnabled) return;
    final script = "$rtmTeam exercises their Right To Match card for $playerName! $highestBidder, you may now raise the final price.";
    await speak(script, tone: AuctionTone.hype, interrupt: true);
  }

  /// Phase 3A: Highest bidder raises price
  Future<void> announceRtmPriceRaised({
    required String highestBidder,
    required int newPrice,
    required String rtmTeam,
    required String playerName,
  }) async {
    if (!_isEnabled) return;
    final script = "$highestBidder raised the price to ₹$newPrice! $rtmTeam, do you match this final bid or pass?";
    await speak(script, tone: AuctionTone.tense, interrupt: true);
  }

  /// Phase 3B: Highest bidder keeps price unchanged
  Future<void> announceRtmPriceKept({
    required String highestBidder,
    required int price,
    required String rtmTeam,
    required String playerName,
  }) async {
    if (!_isEnabled) return;
    final script = "$highestBidder leaves the bid at ₹$price. $rtmTeam, will you match to retain $playerName?";
    await speak(script, tone: AuctionTone.tense, interrupt: true);
  }

  /// Phase 4A: RTM team matches the price and claims player
  Future<void> announceRtmMatched({
    required String rtmTeam,
    required String playerName,
    required int price,
  }) async {
    if (!_isEnabled) return;
    final script = "Matched! $rtmTeam matches the bid of ₹$price and retains $playerName via Right to Match!";
    await speak(script, tone: AuctionTone.hype, interrupt: true);
  }

  /// Phase 4B: RTM team declines to match
  Future<void> announceRtmDeclined({
    required String rtmTeam,
    required String winnerName,
    required String playerName,
    required int price,
  }) async {
    if (!_isEnabled) return;
    final script = "$rtmTeam declines to match. $playerName is officially sold to $winnerName for ₹$price!";
    await speak(script, tone: AuctionTone.normal, interrupt: true);
  }

  /// Announce Strategic Timeout called
  Future<void> announceTimeout({required String callerName}) async {
    if (!_isEnabled) return;
    final templates = [
      "Timeout called by $callerName! Clock is frozen.",
      "Strategic pause requested by $callerName. War room discussions underway!",
    ];
    final script = templates[_rng.nextInt(templates.length)];
    await speak(script, tone: AuctionTone.tense, interrupt: true);
  }

  /// Announce Strategic Timeout resumed
  Future<void> announceTimeoutResumed() async {
    if (!_isEnabled) return;
    await speak("Strategic timeout concluded! Bidding timer resumes!", tone: AuctionTone.normal, interrupt: true);
  }

  /// Announce player nominated for next auction
  Future<void> announcePlayerNominated({required String playerName}) async {
    if (!_isEnabled) return;
    await speak("$playerName has been requested for the next auction round!", tone: AuctionTone.normal, interrupt: false);
  }
}
