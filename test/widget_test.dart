import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/app.dart';
import 'package:translator/services/settings_store.dart';
import 'package:translator/services/translation/offline_translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home shows both interpreter modes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsStore();
    await settings.load();
    await tester.pumpWidget(
      TranslatorApp(settings: settings, offline: OfflineTranslator(), client: http.Client()),
    );
    expect(find.text('Cuộc nói chuyện, bài nói'), findsOneWidget);
    expect(find.text('Một nút nghe, một nút nói'), findsOneWidget);
    expect(find.textContaining('gần như cùng lúc'), findsOneWidget);
  });
}
