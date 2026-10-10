import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/settings.dart';
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
            Row(
              children: [
                Expanded(
                  child: _AudioToggle(
                    icon: Icons.volume_up_rounded,
                    label: 'Loa ngoài',
                    isActive: current.output != OutputMode.text && current.playback == PlaybackTarget.speaker,
                    onTap: () {
                      if (current.output != OutputMode.text && current.playback == PlaybackTarget.speaker) {
                        settings.update(current.copyWith(output: OutputMode.text));
                      } else {
                        settings.update(current.copyWith(output: OutputMode.both, playback: PlaybackTarget.speaker));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AudioToggle(
                    icon: Icons.headphones_rounded,
                    label: 'Tai nghe',
                    isActive: current.output != OutputMode.text && current.playback == PlaybackTarget.headphones,
                    onTap: () {
                      if (current.output != OutputMode.text && current.playback == PlaybackTarget.headphones) {
                        settings.update(current.copyWith(output: OutputMode.text));
                      } else {
                        settings.update(current.copyWith(output: OutputMode.both, playback: PlaybackTarget.headphones));
                      }
                    },
                  ),
                ),
              ],
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: context.booth.panel,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: context.booth.line, width: 0.5),
              borderRadius: BorderRadius.circular(24),
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
      ),
    );
  }
}

class _AudioToggle extends StatelessWidget {
  const _AudioToggle({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: BoothColors.lime.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Material(
        color: isActive ? BoothColors.lime : context.booth.panel,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: isActive ? BoothColors.lime : context.booth.line, width: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isActive ? const Color(0xFF1A2208) : context.booth.paper, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? const Color(0xFF1A2208) : context.booth.paper,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
