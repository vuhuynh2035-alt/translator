import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../../models/language.dart';
import 'translation_engine.dart';

class OfflineTranslator {
  final _translators = <String, OnDeviceTranslator>{};
  final _models = OnDeviceTranslatorModelManager();

  Future<void> ensureModels(AppLanguage from, AppLanguage to) async {
    for (final language in [from, to]) {
      final code = language.mlkit.bcpCode;
      final ready = await _models.isModelDownloaded(code);
      if (!ready) {
        await _models.downloadModel(code, isWifiRequired: false);
      }
    }
  }

  Future<bool> hasModels(AppLanguage from, AppLanguage to) async {
    final source = await _models.isModelDownloaded(from.mlkit.bcpCode);
    final target = await _models.isModelDownloaded(to.mlkit.bcpCode);
    return source && target;
  }

  Future<String> translateText(AppLanguage from, AppLanguage to, String text) {
    final key = '${from.code}>${to.code}';
    final translator = _translators.putIfAbsent(
      key,
      () => OnDeviceTranslator(sourceLanguage: from.mlkit, targetLanguage: to.mlkit),
    );
    return translator.translateText(text);
  }

  Future<void> close() async {
    for (final translator in _translators.values) {
      await translator.close();
    }
    _translators.clear();
  }
}

class OfflineEngine implements TranslationEngine {
  OfflineEngine(this.offline);

  final OfflineTranslator offline;

  @override
  Stream<String> translate(TranslationRequest request) async* {
    if (request.from.code == request.to.code) {
      yield request.text;
      return;
    }
    try {
      yield await offline.translateText(request.from, request.to, request.text);
    } catch (_) {
      throw TranslationException(
        'Chưa có mô hình ngoại tuyến. Mở Cài đặt, tải mô hình khi có mạng, rồi dùng offline.',
      );
    }
  }
}
