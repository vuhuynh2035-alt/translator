import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/settings.dart';
import '../services/settings_store.dart';
import '../services/translation/offline_translator.dart';
import '../session/continuous_session.dart';
import '../theme.dart';
import 'booth_widgets.dart';

class ContinuousPage extends StatefulWidget {
  const ContinuousPage({super.key, required this.settings, required this.offline, required this.client});

  final SettingsStore settings;
  final OfflineTranslator offline;
  final http.Client client;

  @override
  State<ContinuousPage> createState() => _ContinuousPageState();
}

class _ContinuousPageState extends State<ContinuousPage> {
  late final ContinuousSession session = ContinuousSession(
    settings: widget.settings,
    offline: widget.offline,
    client: widget.client,
  );

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    session.addListener(_autoScroll);
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    session.removeListener(_autoScroll);
    _scrollController.dispose();
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([session, widget.settings]),
      builder: (context, _) {
        final current = widget.settings.settings;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.booth.ink,
            foregroundColor: context.booth.paper,
            title: const Text('1 chiều'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Xóa lịch sử',
                onPressed: session.fullHistory.isEmpty
                    ? null
                    : () {
                        session.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa lịch sử')));
                      },
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Sao chép nội dung',
                onPressed: session.fullHistory.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: session.exportTranscript()));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã copy toàn bộ nội dung dịch')));
                      },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    engineLabel(current.engine),
                    style: const TextStyle(color: BoothColors.lime, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // 1. Compact Control Bar
                Container(
                  color: context.booth.ink,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: LanguageMenu(
                              value: current.heardLanguage,
                              onChanged: session.running
                                  ? (_) {}
                                  : (code) => widget.settings.update(current.copyWith(heardLanguage: code)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.swap_horiz, size: 20),
                            color: context.booth.mute,
                            onPressed: session.running
                                ? null
                                : () {
                                    widget.settings.update(current.copyWith(
                                      heardLanguage: current.myLanguage,
                                      myLanguage: current.heardLanguage,
                                    ));
                                  },
                          ),
                          Expanded(
                            child: LanguageMenu(
                              value: current.myLanguage,
                              onChanged: session.running
                                  ? (_) {}
                                  : (code) => widget.settings.update(current.copyWith(myLanguage: code)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Tai nghe'),
                            selected: current.output != OutputMode.text && current.playback == PlaybackTarget.headphones,
                            onSelected: (selected) {
                              if (selected) {
                                widget.settings.update(current.copyWith(output: OutputMode.both, playback: PlaybackTarget.headphones));
                              } else {
                                widget.settings.update(current.copyWith(output: OutputMode.text));
                              }
                            },
                            selectedColor: BoothColors.lime,
                            labelStyle: TextStyle(
                              color: (current.output != OutputMode.text && current.playback == PlaybackTarget.headphones)
                                  ? const Color(0xFF1A2208)
                                  : context.booth.paper,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Loa'),
                            selected: current.output != OutputMode.text && current.playback == PlaybackTarget.speaker,
                            onSelected: (selected) {
                              if (selected) {
                                widget.settings.update(current.copyWith(output: OutputMode.both, playback: PlaybackTarget.speaker));
                              } else {
                                widget.settings.update(current.copyWith(output: OutputMode.text));
                              }
                            },
                            selectedColor: BoothColors.lime,
                            labelStyle: TextStyle(
                              color: (current.output != OutputMode.text && current.playback == PlaybackTarget.speaker)
                                  ? const Color(0xFF1A2208)
                                  : context.booth.paper,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Spacer(),
                          if (session.running) ...[
                            SizedBox(
                              width: 50,
                              height: 14,
                              child: LiveMeter(level: session.sound, active: session.running),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              session.phase,
                              style: TextStyle(
                                color: session.phase == 'Đang nói'
                                    ? BoothColors.lime
                                    : (session.phase == 'Đang dịch' ? BoothColors.coral : context.booth.mute),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (session.notice != null) ...[
                        const SizedBox(height: 4),
                        Text(session.notice!, style: const TextStyle(color: BoothColors.mint, fontSize: 12)),
                      ],
                      if (session.error != null) ...[
                        const SizedBox(height: 4),
                        Text(session.error!, style: const TextStyle(color: BoothColors.coral, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),

                // 2. Continuous Transcription Display
                Expanded(
                  child: session.fullHistory.isEmpty && session.livePartial.isEmpty && session.liveTranslation.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                session.running ? Icons.mic : Icons.translate,
                                size: 44,
                                color: context.booth.mute.withOpacity(0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                session.running ? 'Đang lắng nghe... Hãy nói vào micro' : 'Nhấn "Bắt đầu nghe" để phiên dịch liên tục',
                                style: TextStyle(color: context.booth.mute, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: session.fullHistory.length + 1,
                          itemBuilder: (context, index) {
                            if (index == session.fullHistory.length) {
                              if (session.livePartial.isEmpty && session.liveTranslation.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.booth.panel.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: BoothColors.lime.withOpacity(0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (session.livePartial.isNotEmpty)
                                      Text(
                                        session.livePartial,
                                        style: TextStyle(
                                          color: context.booth.mute,
                                          fontSize: (current.fontSize * 0.85).clamp(12.0, 24.0),
                                          height: 1.35,
                                        ),
                                      ),
                                    if (session.liveTranslation.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        session.liveTranslation,
                                        style: TextStyle(
                                          color: BoothColors.mint,
                                          fontSize: current.fontSize.clamp(14.0, 32.0),
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }
                            final item = session.fullHistory[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.booth.panel,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: context.neuShadows,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.source,
                                          style: TextStyle(
                                            color: context.booth.mute,
                                            fontSize: (current.fontSize * 0.85).clamp(12.0, 24.0),
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.volume_up, size: 18, color: BoothColors.lime),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Đọc lại',
                                        onPressed: () => session.replay(item.translation),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.translation,
                                    style: TextStyle(
                                      color: BoothColors.mint,
                                      fontSize: current.fontSize.clamp(14.0, 32.0),
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // 3. Compact Bottom Control Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: session.running ? BoothColors.coral : BoothColors.lime,
                        foregroundColor: const Color(0xFF1A2208),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(session.running ? Icons.stop_rounded : Icons.mic_rounded, size: 20),
                      label: Text(
                        session.running ? 'Dừng nghe' : 'Bắt đầu nghe',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => session.running ? session.stop() : session.start(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
