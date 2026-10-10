import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/settings_store.dart';
import '../services/translation/offline_translator.dart';
import '../theme.dart';
import 'booth_widgets.dart';
import 'continuous_page.dart';
import 'conference_page.dart';
import 'settings_page.dart';
import 'two_way_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.settings, required this.offline, required this.client});

  final SettingsStore settings;
  final OfflineTranslator offline;
  final http.Client client;

  @override
  Widget build(BuildContext context) {
    final current = settings.settings;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('Phiên dịch trực tiếp'),
                      SizedBox(height: 8),
                      Text('Nghe và nói,\ngần như cùng lúc.', style: TextStyle(fontSize: 34, height: 1.05, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cài đặt',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsPage(settings: settings, offline: offline),
                      ),
                    );
                  },
                  icon: const Icon(Icons.tune, color: BoothColors.lime),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '${engineLabel(current.engine)}  ·  ${outputLabel(current.output)}',
              style: TextStyle(color: context.booth.mute),
            ),
            const SizedBox(height: 22),
            _ModeCard(
              kicker: 'Liên tục',
              title: 'Cuộc nói chuyện, bài nói',
              body: 'Nghe ngôn ngữ đối phương và dịch liên tục vào tai nghe. Câu được dịch ngay khi vừa rõ, để bạn theo kịp và trả lời như cuộc trò chuyện thường.',
              accent: BoothColors.lime,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ContinuousPage(settings: settings, offline: offline, client: client),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _ModeCard(
              kicker: 'Hai chiều',
              title: 'Một nút nghe, một nút nói',
              body: 'Bấm Nghe để dịch lời đối phương cho bạn. Bấm Nói để dịch lời bạn và phát ra loa cho đối phương nghe.',
              accent: BoothColors.mint,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TwoWayPage(settings: settings, offline: offline, client: client),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _ModeCard(
              kicker: 'Hội thảo',
              title: 'Bài giảng, diễn thuyết dài',
              body: 'Dịch liên tục và lưu trữ mọi lời nói. Giữ cho điện thoại không bao giờ ngủ, có thể tắt đen màn hình để tiết kiệm pin tối đa.',
              accent: BoothColors.coral,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ConferencePage(settings: settings, offline: offline, client: client),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            Text(
              'Dùng tai nghe ở chế độ liên tục. Máy dịch sẵn trong lúc người kia còn đang nói, nên khi họ ngừng thì bản dịch ra gần như ngay.',
              style: TextStyle(color: context.booth.mute, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.kicker,
    required this.title,
    required this.body,
    required this.accent,
    required this.onTap,
  });

  final String kicker;
  final String title;
  final String body;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.booth.panel,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.booth.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(kicker, color: accent),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(body, style: TextStyle(color: context.booth.mute, height: 1.4)),
              const SizedBox(height: 14),
              Icon(Icons.arrow_forward, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
