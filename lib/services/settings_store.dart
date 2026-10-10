import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore({AppSettings? initial}) : _settings = initial ?? AppSettings.fallback;

  AppSettings _settings;
  AppSettings get settings => _settings;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = AppSettings(
      engine: _enum(EngineMode.values, prefs.getString('engine'), AppSettings.fallback.engine),
      provider: _enum(AiProvider.values, prefs.getString('provider'), AppSettings.fallback.provider),
      apiKey: prefs.getString('apiKey') ?? '',
      geminiModel: prefs.getString('geminiModel') ?? AppSettings.fallback.geminiModel,
      openAiModel: prefs.getString('openAiModel') ?? AppSettings.fallback.openAiModel,
      openAiBaseUrl: prefs.getString('openAiBaseUrl') ?? AppSettings.fallback.openAiBaseUrl,
      heardLanguage: prefs.getString('heardLanguage') ?? AppSettings.fallback.heardLanguage,
      myLanguage: prefs.getString('myLanguage') ?? AppSettings.fallback.myLanguage,
      output: _enum(OutputMode.values, prefs.getString('output'), AppSettings.fallback.output),
      playback: _enum(PlaybackTarget.values, prefs.getString('playback'), AppSettings.fallback.playback),
      overlapListening: prefs.getBool('overlapListening') ?? AppSettings.fallback.overlapListening,
      silenceMs: prefs.getInt('silenceMs') ?? AppSettings.fallback.silenceMs,
      ttsRate: prefs.getDouble('ttsRate') ?? AppSettings.fallback.ttsRate,
      ttsPitch: prefs.getDouble('ttsPitch') ?? AppSettings.fallback.ttsPitch,
    );
    notifyListeners();
  }

  Future<void> update(AppSettings next) async {
    _settings = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('engine', next.engine.name);
    await prefs.setString('provider', next.provider.name);
    await prefs.setString('apiKey', next.apiKey);
    await prefs.setString('geminiModel', next.geminiModel);
    await prefs.setString('openAiModel', next.openAiModel);
    await prefs.setString('openAiBaseUrl', next.openAiBaseUrl);
    await prefs.setString('heardLanguage', next.heardLanguage);
    await prefs.setString('myLanguage', next.myLanguage);
    await prefs.setString('output', next.output.name);
    await prefs.setString('playback', next.playback.name);
    await prefs.setBool('overlapListening', next.overlapListening);
    await prefs.setInt('silenceMs', next.silenceMs);
    await prefs.setDouble('ttsRate', next.ttsRate);
    await prefs.setDouble('ttsPitch', next.ttsPitch);
  }

  static T _enum<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
