import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'services/settings_store.dart';
import 'services/translation/offline_translator.dart';
import 'theme.dart';
import 'ui/home_page.dart';

class TranslatorApp extends StatelessWidget {
  const TranslatorApp({super.key, required this.settings, required this.offline, required this.client});

  final SettingsStore settings;
  final OfflineTranslator offline;
  final http.Client client;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final themeMode = switch (settings.settings.themeMode) {
          1 => ThemeMode.light,
          2 => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        return MaterialApp(
          title: 'phiendich',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: buildBoothTheme(brightness: Brightness.light),
          darkTheme: buildBoothTheme(brightness: Brightness.dark),
          home: HomePage(settings: settings, offline: offline, client: client),
        );
      },
    );
  }
}
