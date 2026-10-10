import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'services/settings_store.dart';
import 'services/translation/offline_translator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsStore();
  await settings.load();
  runApp(TranslatorApp(settings: settings, offline: OfflineTranslator(), client: http.Client()));
}
