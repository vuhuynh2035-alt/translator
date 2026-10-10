import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.sttLocale,
    required this.ttsLocale,
    required this.mlkit,
  });

  final String code;
  final String name;
  final String sttLocale;
  final String ttsLocale;
  final TranslateLanguage mlkit;

  static const all = <AppLanguage>[
    AppLanguage(
      code: 'vi',
      name: 'Tiếng Việt',
      sttLocale: 'vi_VN',
      ttsLocale: 'vi-VN',
      mlkit: TranslateLanguage.vietnamese,
    ),
    AppLanguage(
      code: 'en',
      name: 'English',
      sttLocale: 'en_US',
      ttsLocale: 'en-US',
      mlkit: TranslateLanguage.english,
    ),
    AppLanguage(
      code: 'zh',
      name: '中文',
      sttLocale: 'zh_CN',
      ttsLocale: 'zh-CN',
      mlkit: TranslateLanguage.chinese,
    ),
    AppLanguage(
      code: 'ja',
      name: '日本語',
      sttLocale: 'ja_JP',
      ttsLocale: 'ja-JP',
      mlkit: TranslateLanguage.japanese,
    ),
    AppLanguage(
      code: 'ko',
      name: '한국어',
      sttLocale: 'ko_KR',
      ttsLocale: 'ko-KR',
      mlkit: TranslateLanguage.korean,
    ),
    AppLanguage(
      code: 'fr',
      name: 'Français',
      sttLocale: 'fr_FR',
      ttsLocale: 'fr-FR',
      mlkit: TranslateLanguage.french,
    ),
    AppLanguage(
      code: 'de',
      name: 'Deutsch',
      sttLocale: 'de_DE',
      ttsLocale: 'de-DE',
      mlkit: TranslateLanguage.german,
    ),
    AppLanguage(
      code: 'es',
      name: 'Español',
      sttLocale: 'es_ES',
      ttsLocale: 'es-ES',
      mlkit: TranslateLanguage.spanish,
    ),
    AppLanguage(
      code: 'th',
      name: 'ไทย',
      sttLocale: 'th_TH',
      ttsLocale: 'th-TH',
      mlkit: TranslateLanguage.thai,
    ),
    AppLanguage(
      code: 'id',
      name: 'Indonesia',
      sttLocale: 'id_ID',
      ttsLocale: 'id-ID',
      mlkit: TranslateLanguage.indonesian,
    ),
    AppLanguage(
      code: 'ru',
      name: 'Русский',
      sttLocale: 'ru_RU',
      ttsLocale: 'ru-RU',
      mlkit: TranslateLanguage.russian,
    ),
    AppLanguage(
      code: 'hi',
      name: 'हिन्दी',
      sttLocale: 'hi_IN',
      ttsLocale: 'hi-IN',
      mlkit: TranslateLanguage.hindi,
    ),
    AppLanguage(
      code: 'pt',
      name: 'Português',
      sttLocale: 'pt_BR',
      ttsLocale: 'pt-BR',
      mlkit: TranslateLanguage.portuguese,
    ),
    AppLanguage(
      code: 'it',
      name: 'Italiano',
      sttLocale: 'it_IT',
      ttsLocale: 'it-IT',
      mlkit: TranslateLanguage.italian,
    ),
    AppLanguage(
      code: 'ar',
      name: 'العربية',
      sttLocale: 'ar_SA',
      ttsLocale: 'ar-SA',
      mlkit: TranslateLanguage.arabic,
    ),
  ];

  static AppLanguage byCode(String code) {
    return all.firstWhere((language) => language.code == code, orElse: () => all.first);
  }
}
