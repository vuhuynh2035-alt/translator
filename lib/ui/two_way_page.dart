import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/language.dart';
import '../models/settings.dart';
import '../services/settings_store.dart';
import '../services/translation/offline_translator.dart';
import '../session/two_way_session.dart';
import '../theme.dart';
import 'booth_widgets.dart';

class TwoWayPage extends StatefulWidget {
  const TwoWayPage({super.key, required this.settings, required this.offline, required this.client});

  final SettingsStore settings;
  final OfflineTranslator offline;
  final http.Client client;

  @override
  State<TwoWayPage> createState() => _TwoWayPageState();
}

class _TwoWayPageState extends State<TwoWayPage> {
  late final TwoWaySession session = TwoWaySession(
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
        final locked = session.listening != null || session.working;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.booth.ink,
            foregroundColor: context.booth.paper,
            title: const Text('Hai chiều'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Xóa phiên dịch',
                onPressed: session.fullHistory.isEmpty ? null : () {
                  session.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phiên dịch')));
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
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(session.status, style: TextStyle(color: context.booth.mute)),
                  ],
                ),
                if (session.latencyMs != null)
                  Text('${session.latencyMs} ms tới bản dịch', style: const TextStyle(color: BoothColors.lime)),
                if (session.notice != null) Text(session.notice!, style: const TextStyle(color: BoothColors.mint)),
                if (session.error != null) Text(session.error!, style: const TextStyle(color: BoothColors.coral)),
                const SizedBox(height: 12),
                BoothPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Eyebrow('Đối phương'),
                          ChoiceChips<PlaybackTarget>(
                            selected: session.topPlayback,
                            onSelected: locked ? (_) {} : (t) => session.topPlayback = t,
                            options: const [(PlaybackTarget.speaker, 'Loa'), (PlaybackTarget.headphones, 'Tai nghe')],
                          ),
                        ],
                      ),
                      LanguageMenu(
                        value: current.heardLanguage,
                        onChanged: locked ? (_) {} : (code) => widget.settings.update(current.copyWith(heardLanguage: code)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.listening == BoothSide.other ? session.live : session.otherSaid,
                        style: TextStyle(color: context.booth.mute, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              session.forMe.isEmpty ? 'Bản dịch cho bạn' : session.forMe,
                              style: const TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (session.forMe.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.volume_up, color: BoothColors.mint),
                              onPressed: () => session.replay(session.forMe, AppLanguage.byCode(current.myLanguage)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SideButton(
                        label: session.listening == BoothSide.other ? '■ Dừng nghe đối phương' : '● Liên tục nghe đối phương',
                        color: BoothColors.mint,
                        enabled: !session.working && session.listening != BoothSide.mine,
                        onPressed: () => session.toggle(BoothSide.other),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                BoothPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Eyebrow('Bạn', color: BoothColors.mint),
                          ChoiceChips<PlaybackTarget>(
                            selected: session.bottomPlayback,
                            onSelected: locked ? (_) {} : (t) => session.bottomPlayback = t,
                            options: const [(PlaybackTarget.speaker, 'Loa'), (PlaybackTarget.headphones, 'Tai nghe')],
                          ),
                        ],
                      ),
                      LanguageMenu(
                        value: current.myLanguage,
                        onChanged: locked ? (_) {} : (code) => widget.settings.update(current.copyWith(myLanguage: code)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.listening == BoothSide.mine ? session.live : session.iSaid,
                        style: TextStyle(color: context.booth.mute, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              session.forThem.isEmpty ? 'Bản dịch phát ra loa' : session.forThem,
                              style: const TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (session.forThem.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.volume_up, color: BoothColors.lime),
                              onPressed: () => session.replay(session.forThem, AppLanguage.byCode(current.heardLanguage)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SideButton(
                        label: session.listening == BoothSide.mine ? '■ Dừng nghe tôi' : '● Liên tục nghe tôi',
                        color: BoothColors.lime,
                        enabled: !session.working && session.listening != BoothSide.other,
                        onPressed: () => session.toggle(BoothSide.mine),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LiveMeter(level: session.sound, active: session.listening != null),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.label, required this.color, required this.enabled, required this.onPressed});

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: enabled ? color : context.booth.line,
          foregroundColor: const Color(0xFF1A2208),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: enabled ? onPressed : null,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
