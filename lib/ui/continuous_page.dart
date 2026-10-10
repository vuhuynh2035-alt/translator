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

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([session, widget.settings]),
      builder: (context, _) {
        final current = widget.settings.settings;
        final showText = current.output != OutputMode.audio;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.booth.ink,
            foregroundColor: context.booth.paper,
            title: const Text('Liên tục'),
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
                      ),
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
                      ),
                    ),
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
