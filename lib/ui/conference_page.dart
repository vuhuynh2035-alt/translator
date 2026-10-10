import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/settings.dart';
import '../services/settings_store.dart';
import '../services/translation/offline_translator.dart';
import '../session/conference_session.dart';
import '../theme.dart';
import 'booth_widgets.dart';

class ConferencePage extends StatefulWidget {
  const ConferencePage({super.key, required this.settings, required this.offline, required this.client});

  final SettingsStore settings;
  final OfflineTranslator offline;
  final http.Client client;

  @override
  State<ConferencePage> createState() => _ConferencePageState();
}

class _ConferencePageState extends State<ConferencePage> {
  late final ConferenceSession session = ConferenceSession(
    settings: widget.settings,
    offline: widget.offline,
    client: widget.client,
  );

  bool _saverMode = false;

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.booth.panel,
        title: const Text('Lưu nội dung?'),
        content: const Text('Bạn có muốn lưu lại toàn bộ nội dung đã dịch vào bộ nhớ tạm (clipboard) không?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to Home Page
            },
            child: const Text('Thoát không lưu', style: TextStyle(color: BoothColors.coral)),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: session.exportTranscript()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã copy lịch sử hội thoại')));
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to Home Page
            },
            style: FilledButton.styleFrom(
              backgroundColor: BoothColors.lime,
              foregroundColor: const Color(0xFF1A2208),
            ),
            child: const Text('Lưu & Thoát'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_saverMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _saverMode = false),
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: Text(
              'Đang nghe hội thảo...\nChạm để bật lại màn hình',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 18, height: 1.5),
            ),
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: Listenable.merge([session, widget.settings]),
      builder: (context, _) {
        final current = widget.settings.settings;
        
        if (session.running) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(24),
                      itemCount: session.fullHistory.length + 1,
                      itemBuilder: (context, i) {
                        final index = session.fullHistory.length - i;
                        if (index == session.fullHistory.length) {
                          // Live partial
                          if (session.livePartial.isEmpty && session.liveTranslation.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (session.livePartial.isNotEmpty)
                                  Text(
                                    session.livePartial,
                                    style: TextStyle(
                                      color: context.booth.mute,
                                      fontSize: current.fontSize * 0.75,
                                      height: 1.35,
                                    ),
                                  ),
                                if (session.liveTranslation.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    session.liveTranslation,
                                    style: TextStyle(
                                      fontSize: current.fontSize,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                      color: BoothColors.mint,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }
                        
                        // History items
                        final item = session.fullHistory[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.source,
                                style: TextStyle(
                                  color: context.booth.mute,
                                  fontSize: current.fontSize * 0.75,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.translation,
                                style: TextStyle(
                                  fontSize: current.fontSize,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  color: BoothColors.lime, // slightly different for history
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      height: 64,
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: BoothColors.coral,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          session.stop();
                          _showSaveDialog(context);
                        },
                        child: const Text('Dừng ghi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final showText = current.output != OutputMode.audio;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.booth.ink,
            foregroundColor: context.booth.paper,
            title: const Text('Hội thảo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Xóa lịch sử',
                onPressed: session.fullHistory.isEmpty ? null : () {
                  session.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa lịch sử')));
                },
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy lịch sử',
                onPressed: session.fullHistory.isEmpty ? null : () {
                  Clipboard.setData(ClipboardData(text: session.exportTranscript()));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã copy lịch sử hội thoại')));
                },
              ),
              IconButton(
                icon: const Icon(Icons.battery_saver),
                tooltip: 'Tiết kiệm pin',
                onPressed: () => setState(() => _saverMode = true),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: Text(engineLabel(current.engine), style: const TextStyle(color: BoothColors.lime))),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
                      icon: const Icon(Icons.swap_horiz),
                      color: context.booth.mute,
                      onPressed: session.running ? null : () {
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
                const SizedBox(height: 12),
                ChoiceChips<OutputMode>(
                  selected: current.output,
                  onSelected: (mode) => widget.settings.update(current.copyWith(output: mode)),
                  options: const [
                    (OutputMode.text, 'Chỉ chữ'),
                    (OutputMode.audio, 'Chỉ giọng'),
                    (OutputMode.both, 'Cả hai'),
                  ],
                ),
                const SizedBox(height: 8),
                ChoiceChips<PlaybackTarget>(
                  selected: current.playback,
                  onSelected: (target) => widget.settings.update(current.copyWith(playback: target)),
                  options: const [
                    (PlaybackTarget.headphones, 'Tai nghe'),
                    (PlaybackTarget.speaker, 'Loa'),
                  ],
                ),
                const SizedBox(height: 16),
                LiveMeter(level: session.sound, active: session.running),
                const SizedBox(height: 8),
                Text(
                  session.lastLatencyMs == null ? session.phase : '${session.phase}  ·  ${session.lastLatencyMs} ms',
                  style: TextStyle(color: context.booth.mute),
                ),
                if (session.notice != null) ...[
                  const SizedBox(height: 8),
                  Text(session.notice!, style: const TextStyle(color: BoothColors.mint)),
                ],
                if (session.error != null) ...[
                  const SizedBox(height: 8),
                  Text(session.error!, style: const TextStyle(color: BoothColors.coral)),
                ],
                const SizedBox(height: 16),
                BoothPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Đang nghe'),
                      const SizedBox(height: 8),
                      Text(
                        session.livePartial.isEmpty ? '...' : session.livePartial,
                        style: TextStyle(color: context.booth.mute, fontSize: 16, height: 1.35),
                      ),
                      const SizedBox(height: 16),
                      const Eyebrow('Bản dịch', color: BoothColors.mint),
                      const SizedBox(height: 8),
                      Text(
                        session.liveTranslation.isEmpty ? (showText ? 'Bản dịch hiện ở đây.' : 'Bản dịch sẽ được đọc lên.') : session.liveTranslation,
                        style: TextStyle(
                          fontSize: showText ? 28 : 18,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: showText ? context.booth.paper : context.booth.mute,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _HoldButton(
                  running: session.running,
                  onPressed: () => session.running ? session.stop() : session.start(),
                ),
                if (current.playback == PlaybackTarget.speaker)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Loa dễ lọt vào micro. Tai nghe giúp cuộc nói tiếp tục mà không phải chờ máy đọc xong.',
                      style: TextStyle(color: context.booth.mute, height: 1.35),
                    ),
                  ),
                if (session.history.length > 1) ...[
                  const SizedBox(height: 22),
                  const Eyebrow('Vừa rồi'),
                  const SizedBox(height: 8),
                  for (final caption in session.history.reversed.skip(1).take(6))
                    InkWell(
                      onTap: () => session.replay(caption.translation),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.volume_up, size: 16, color: BoothColors.lime),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                caption.translation,
                                style: TextStyle(color: context.booth.mute, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.running, required this.onPressed});

  final bool running;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: running ? BoothColors.coral : BoothColors.lime,
          foregroundColor: const Color(0xFF1A2208),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onPressed,
        child: Text(running ? 'Dừng' : 'Bắt đầu nghe', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
