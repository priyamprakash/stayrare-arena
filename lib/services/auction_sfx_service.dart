import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Authentic Cricket Auction Sound FX Engine
/// Generates and plays procedural high-fidelity 44.1kHz audio in memory with 0ms latency.
class AuctionSfxService extends ChangeNotifier {
  static final AuctionSfxService _instance = AuctionSfxService._internal();
  factory AuctionSfxService() => _instance;

  AuctionSfxService._internal() {
    _initAudioCache();
  }

  AudioPlayer? _sfxPlayer;
  AudioPlayer? _clockPlayer;
  AudioPlayer? _ambientPlayer;

  bool _isSfxEnabled = true;
  double _volume = 0.85;

  bool get isSfxEnabled => _isSfxEnabled;
  double get volume => _volume;

  // Cached in-memory WAV byte arrays for instant zero-latency playback
  Uint8List? _paddleClickBytes;
  Uint8List? _gavelSingleBytes;
  Uint8List? _gavelHammerDownBytes;
  Uint8List? _heartbeatTickBytes;
  Uint8List? _crowdGaspBytes;
  Uint8List? _soldCheerBytes;
  Uint8List? _timeoutGongBytes;
  Uint8List? _rtmAlertBytes;

  void _initAudioCache() {
    try {
      // Pre-render sound effects into memory (pure Dart, zero dependencies)
      _paddleClickBytes = _generatePaddleClickWav();
      _gavelSingleBytes = _generateGavelKnockWav(doubleStrike: false);
      _gavelHammerDownBytes = _generateGavelKnockWav(doubleStrike: true);
      _heartbeatTickBytes = _generateHeartbeatWav();
      _crowdGaspBytes = _generateCrowdGaspWav();
      _soldCheerBytes = _generateSoldCheerWav();
      _timeoutGongBytes = _generateGongWav();
      _rtmAlertBytes = _generateRtmAlertWav();
    } catch (e) {
      debugPrint('AuctionSfxService WAV render notice: $e');
    }
  }

  static bool get _isInTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  AudioPlayer? _getOrCreatePlayer(int type) {
    if (_isInTest) return null;
    try {
      if (type == 0) {
        return _sfxPlayer ??= AudioPlayer()..setVolume(_volume);
      } else if (type == 1) {
        return _clockPlayer ??= AudioPlayer()..setVolume(_volume * 0.75);
      } else {
        return _ambientPlayer ??= AudioPlayer()..setVolume(_volume * 0.5);
      }
    } catch (e) {
      debugPrint('AudioPlayer platform notice: $e');
      return null;
    }
  }

  void toggleSfx() {
    _isSfxEnabled = !_isSfxEnabled;
    if (!_isSfxEnabled) {
      stopAll();
    }
    notifyListeners();
  }

  void setSfxEnabled(bool val) {
    _isSfxEnabled = val;
    if (!_isSfxEnabled) {
      stopAll();
    }
    notifyListeners();
  }

  void setVolume(double val) {
    _volume = val.clamp(0.0, 1.0);
    try {
      _sfxPlayer?.setVolume(_volume);
      _clockPlayer?.setVolume(_volume * 0.75);
      _ambientPlayer?.setVolume(_volume * 0.5);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> stopAll() async {
    try {
      await _sfxPlayer?.stop();
      await _clockPlayer?.stop();
      await _ambientPlayer?.stop();
    } catch (_) {}
  }

  Future<void> _playBytes(int playerType, Uint8List bytes) async {
    if (!_isSfxEnabled) return;
    try {
      final player = _getOrCreatePlayer(playerType);
      if (player == null) return;
      await player.stop();
      await player.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('SFX play error: $e');
    }
  }

  // ==========================================
  // PLAYBACK TRIGGERS
  // ==========================================

  /// Play crisp paddle raise click when user or AI places a bid
  Future<void> playPaddleClick() async {
    if (!_isSfxEnabled) return;
    _paddleClickBytes ??= _generatePaddleClickWav();
    await _playBytes(0, _paddleClickBytes!);
  }

  /// Play single gavel wooden tap (Going Once / Going Twice)
  Future<void> playGavelTap() async {
    if (!_isSfxEnabled) return;
    _gavelSingleBytes ??= _generateGavelKnockWav(doubleStrike: false);
    await _playBytes(0, _gavelSingleBytes!);
  }

  /// Play authoritative wooden hammer-down impact when player is SOLD
  Future<void> playHammerDown() async {
    if (!_isSfxEnabled) return;
    _gavelHammerDownBytes ??= _generateGavelKnockWav(doubleStrike: true);
    await _playBytes(0, _gavelHammerDownBytes!);
  }

  /// Play tense heartbeat clock tick in the final countdown seconds
  Future<void> playCountdownTick({required int secondsRemaining}) async {
    if (!_isSfxEnabled || secondsRemaining > 6 || secondsRemaining <= 0) return;
    _heartbeatTickBytes ??= _generateHeartbeatWav();
    await _playBytes(1, _heartbeatTickBytes!);
  }

  /// Play crowd gasp/murmur when huge jump bid or marquee arrival happens
  Future<void> playCrowdGasp() async {
    if (!_isSfxEnabled) return;
    _crowdGaspBytes ??= _generateCrowdGaspWav();
    await _playBytes(2, _crowdGaspBytes!);
  }

  /// Play celebratory sold fanfare chord
  Future<void> playSoldCheer() async {
    if (!_isSfxEnabled) return;
    _soldCheerBytes ??= _generateSoldCheerWav();
    await _playBytes(0, _soldCheerBytes!);
  }

  /// Play strategic timeout gong
  Future<void> playTimeoutGong() async {
    if (!_isSfxEnabled) return;
    _timeoutGongBytes ??= _generateGongWav();
    await _playBytes(0, _timeoutGongBytes!);
  }

  /// Play dynamic RTM card trigger chime
  Future<void> playRtmAlert() async {
    if (!_isSfxEnabled) return;
    _rtmAlertBytes ??= _generateRtmAlertWav();
    await _playBytes(0, _rtmAlertBytes!);
  }

  // ==========================================
  // PROCEDURAL 16-BIT 44.1kHz WAV SYNTHESIS
  // ==========================================

  /// Generate wooden gavel strike with oak chamber acoustic resonance
  static Uint8List _generateGavelKnockWav({bool doubleStrike = false}) {
    const sampleRate = 44100;
    final totalDuration = doubleStrike ? 0.65 : 0.35;
    final numSamples = (sampleRate * totalDuration).toInt();
    final samples = Float32List(numSamples);

    void addStrike(int startSample, double intensity) {
      for (int i = 0; i < (sampleRate * 0.28).toInt(); i++) {
        final idx = startSample + i;
        if (idx >= numSamples) break;
        final t = i / sampleRate;

        // Wood impact click (high transient)
        final click = (Random().nextDouble() * 2 - 1) * exp(-t * 90);
        // Resonant wood body frequencies (140Hz, 280Hz, 460Hz)
        final body1 = sin(2 * pi * 145 * t) * exp(-t * 22);
        final body2 = sin(2 * pi * 290 * t) * exp(-t * 30) * 0.6;
        final body3 = sin(2 * pi * 480 * t) * exp(-t * 45) * 0.4;

        final val = (click * 0.45 + body1 * 0.65 + body2 * 0.35 + body3 * 0.25) * intensity;
        samples[idx] += val;
      }
    }

    addStrike(0, 1.0);
    if (doubleStrike) {
      addStrike((sampleRate * 0.16).toInt(), 0.92);
      addStrike((sampleRate * 0.32).toInt(), 1.05);
    }

    return _encodeWav(samples, sampleRate);
  }

  /// Generate crisp paddle raise click
  static Uint8List _generatePaddleClickWav() {
    const sampleRate = 44100;
    const duration = 0.08;
    final numSamples = (sampleRate * duration).toInt();
    final samples = Float32List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final noise = (Random().nextDouble() * 2 - 1) * exp(-t * 140);
      final tone = sin(2 * pi * 720 * t) * exp(-t * 80);
      samples[i] = (noise * 0.6 + tone * 0.5).clamp(-1.0, 1.0);
    }

    return _encodeWav(samples, sampleRate);
  }

  /// Generate tense sub-bass heartbeat pulse
  static Uint8List _generateHeartbeatWav() {
    const sampleRate = 44100;
    const duration = 0.28;
    final numSamples = (sampleRate * duration).toInt();
    final samples = Float32List(numSamples);

    // Lub-dub double low-frequency pump
    void addThump(int startSample, double freq, double amp) {
      for (int i = 0; i < (sampleRate * 0.12).toInt(); i++) {
        final idx = startSample + i;
        if (idx >= numSamples) break;
        final t = i / sampleRate;
        final sub = sin(2 * pi * freq * t) * exp(-t * 32);
        samples[idx] += (sub * amp);
      }
    }

    addThump(0, 75, 0.95);
    addThump((sampleRate * 0.09).toInt(), 60, 0.85);

    return _encodeWav(samples, sampleRate);
  }

  /// Generate crowd gasp ambient whoosh
  static Uint8List _generateCrowdGaspWav() {
    const sampleRate = 44100;
    const duration = 0.85;
    final numSamples = (sampleRate * duration).toInt();
    final samples = Float32List(numSamples);

    double filterState = 0;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Envelope: swell up at 0.25s then fade out
      final envelope = (t < 0.25) ? (t / 0.25) : exp(-(t - 0.25) * 3.5);
      final whiteNoise = Random().nextDouble() * 2 - 1;

      // Low pass filter
      filterState += (whiteNoise - filterState) * 0.08;
      final vocalHarmonic = sin(2 * pi * (320 + sin(t * 8) * 40) * t) * 0.25;

      samples[i] = ((filterState * 0.75 + vocalHarmonic) * envelope * 0.7).clamp(-1.0, 1.0);
    }

    return _encodeWav(samples, sampleRate);
  }

  /// Generate celebratory sold fanfare chime
  static Uint8List _generateSoldCheerWav() {
    const sampleRate = 44100;
    const duration = 0.9;
    final numSamples = (sampleRate * duration).toInt();
    final samples = Float32List(numSamples);

    // Major Triad (C5 - 523Hz, E5 - 659Hz, G5 - 784Hz, C6 - 1046Hz)
    final notes = [523.25, 659.25, 783.99, 1046.50];

    for (int n = 0; n < notes.length; n++) {
      final startSample = (sampleRate * (n * 0.08)).toInt();
      final freq = notes[n];
      for (int i = 0; i < (sampleRate * 0.55).toInt(); i++) {
        final idx = startSample + i;
        if (idx >= numSamples) break;
        final t = i / sampleRate;
        final bell = sin(2 * pi * freq * t) * exp(-t * 7.5);
        final shimmer = sin(2 * pi * (freq * 2) * t) * exp(-t * 12) * 0.3;
        samples[idx] += ((bell + shimmer) * 0.45);
      }
    }

    return _encodeWav(samples, sampleRate);
  }

  /// Generate deep strategic timeout gong
  static Uint8List _generateGongWav() {
    const sampleRate = 44100;
    const duration = 1.6;
    final numSamples = (sampleRate * duration).toInt();
    final samples = Float32List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final f1 = sin(2 * pi * 320 * t) * exp(-t * 2.2);
      final f2 = sin(2 * pi * 580 * t) * exp(-t * 3.5) * 0.6;
      final f3 = sin(2 * pi * 840 * t) * exp(-t * 5.0) * 0.35;
      final click = (i < 200) ? (Random().nextDouble() * 2 - 1) * 0.5 : 0.0;
      samples[i] = ((f1 + f2 + f3 + click) * 0.7).clamp(-1.0, 1.0);
    }

    return _encodeWav(samples, sampleRate);
  }

  /// Generate RTM activation alert
  static Uint8List _generateRtmAlertWav() {
    const sampleRate = 44100;
    const duration = 0.5;
    final numSamples = (sampleRate * duration).toInt();
    final samples = Float32List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Rising frequency siren/pulse (600Hz -> 1200Hz)
      final freq = 600 + (t / duration) * 600;
      final tone = sin(2 * pi * freq * t) * exp(-t * 4.0);
      samples[i] = (tone * 0.8).clamp(-1.0, 1.0);
    }

    return _encodeWav(samples, sampleRate);
  }

  /// Standard PCM 16-bit Mono 44.1kHz RIFF WAV Header Encoder
  static Uint8List _encodeWav(Float32List floatSamples, int sampleRate) {
    final byteData = ByteData(44 + floatSamples.length * 2);

    // RIFF chunk descriptor
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, 36 + floatSamples.length * 2, Endian.little);
    byteData.setUint8(8, 0x57);  // 'W'
    byteData.setUint8(9, 0x41);  // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // 'fmt ' sub-chunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    byteData.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
    byteData.setUint16(32, 2, Endian.little);  // BlockAlign (NumChannels * BitsPerSample/8)
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample (16-bit)

    // 'data' sub-chunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, floatSamples.length * 2, Endian.little);

    // 16-bit PCM sample values
    int offset = 44;
    for (int i = 0; i < floatSamples.length; i++) {
      final s = (floatSamples[i].clamp(-1.0, 1.0) * 32767).toInt();
      byteData.setInt16(offset, s, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}
