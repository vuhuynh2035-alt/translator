enum EngineMode { online, offline }

enum AiProvider { gemini, openai }

enum OutputMode { text, audio, both }

enum PlaybackTarget { headphones, speaker }

class AppSettings {
  const AppSettings({
    required this.engine,
    required this.provider,
    required this.apiKey,
    required this.geminiModel,
    required this.openAiModel,
    required this.openAiBaseUrl,
    required this.heardLanguage,
    required this.myLanguage,
    required this.output,
    required this.playback,
    required this.overlapListening,
    required this.silenceMs,
    required this.ttsRate,
    required this.ttsPitch,
  });

  final EngineMode engine;
  final AiProvider provider;
  final String apiKey;
  final String geminiModel;
  final String openAiModel;
  final String openAiBaseUrl;
  final String heardLanguage;
  final String myLanguage;
  final OutputMode output;
  final PlaybackTarget playback;
  final bool overlapListening;
  final int silenceMs;
  final double ttsRate;
  final double ttsPitch;

  static const fallback = AppSettings(
    engine: EngineMode.online,
    provider: AiProvider.gemini,
    apiKey: '',
    geminiModel: 'gemini-2.5-flash',
    openAiModel: 'gpt-4o-mini',
    openAiBaseUrl: 'https://api.openai.com/v1',
    heardLanguage: 'en',
    myLanguage: 'vi',
    output: OutputMode.both,
    playback: PlaybackTarget.headphones,
    overlapListening: true,
    silenceMs: 700,
    ttsRate: 0.56,
    ttsPitch: 1.0,
  );

  bool get speaks => output != OutputMode.text;

  bool get effectiveOverlap => overlapListening && playback == PlaybackTarget.headphones;

  AppSettings copyWith({
    EngineMode? engine,
    AiProvider? provider,
    String? apiKey,
    String? geminiModel,
    String? openAiModel,
    String? openAiBaseUrl,
    String? heardLanguage,
    String? myLanguage,
    OutputMode? output,
    PlaybackTarget? playback,
    bool? overlapListening,
    int? silenceMs,
    double? ttsRate,
    double? ttsPitch,
  }) {
    return AppSettings(
      engine: engine ?? this.engine,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      geminiModel: geminiModel ?? this.geminiModel,
      openAiModel: openAiModel ?? this.openAiModel,
      openAiBaseUrl: openAiBaseUrl ?? this.openAiBaseUrl,
      heardLanguage: heardLanguage ?? this.heardLanguage,
      myLanguage: myLanguage ?? this.myLanguage,
      output: output ?? this.output,
      playback: playback ?? this.playback,
      overlapListening: overlapListening ?? this.overlapListening,
      silenceMs: silenceMs ?? this.silenceMs,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
    );
  }
}
