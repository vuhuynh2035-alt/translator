$ErrorActionPreference = "Stop"

Write-Host "Configuring for web..."
flutter create . --platforms web

Write-Host "Backing up..."
if (Test-Path lib_bak) { Remove-Item lib_bak -Recurse -Force }
Copy-Item -Path "lib" -Destination "lib_bak" -Recurse -Force

Write-Host "Modifying pubspec..."
(Get-Content pubspec.yaml) -replace "google_mlkit_translation:.*", "" | Set-Content pubspec.yaml

Write-Host "Modifying language.dart..."
$lang = Get-Content lib\models\language.dart
$lang = $lang -replace "import 'package:google_mlkit_translation/google_mlkit_translation.dart';", ""
$lang = $lang -replace "final TranslateLanguage mlkit;", "final int mlkit;"
$lang = $lang -replace "TranslateLanguage\.\w+", "0"
$lang | Set-Content lib\models\language.dart

Write-Host "Modifying offline_translator.dart..."
$offline = @"
import '../../models/language.dart';
import 'translation_engine.dart';

class OfflineTranslator {
  Future<void> ensureModels(AppLanguage from, AppLanguage to) async {}
  Future<bool> hasModels(AppLanguage from, AppLanguage to) async => false;
  Future<String> translateText(AppLanguage from, AppLanguage to, String text) async {
    throw TranslationException('Dịch ngoại tuyến không hỗ trợ trên Web.');
  }
  Future<void> close() async {}
}

class OfflineEngine implements TranslationEngine {
  OfflineEngine(this.offline);
  final OfflineTranslator offline;

  @override
  Stream<String> translate(TranslationRequest request) async* {
    throw TranslationException('Dịch ngoại tuyến không hỗ trợ trên Web.');
  }
}
"@
$offline | Set-Content lib\services\translation\offline_translator.dart

Write-Host "Building web..."
flutter build web

Write-Host "Zipping web build..."
if (Test-Path web-build.zip) { Remove-Item web-build.zip -Force }
Compress-Archive -Path build\web\* -DestinationPath web-build.zip -Force

Write-Host "Restoring..."
Remove-Item -Path "lib" -Recurse -Force
Rename-Item -Path "lib_bak" -NewName "lib"
flutter pub add google_mlkit_translation:^0.15.1

Write-Host "Done!"
