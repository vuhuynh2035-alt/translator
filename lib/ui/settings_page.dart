import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../models/language.dart';
import '../models/settings.dart';
import '../services/settings_store.dart';
import '../services/translation/offline_translator.dart';
import '../theme.dart';
import 'booth_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings, required this.offline});

  final SettingsStore settings;
  final OfflineTranslator offline;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings draft = widget.settings.settings;
  late final TextEditingController _key = TextEditingController(text: draft.apiKey);
  late final TextEditingController _gemini = TextEditingController(text: draft.geminiModel);
  late final TextEditingController _openai = TextEditingController(text: draft.openAiModel);
  late final TextEditingController _base = TextEditingController(text: draft.openAiBaseUrl);
  String? _modelMessage;
  bool _downloading = false;
  
  List<String> _geminiModels = [
    'gemini-2.5-flash',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash-exp'
  ];
  bool _fetchingModels = false;
  String? _modelFetchNotice;

  Future<void> _fetchGeminiModels() async {
    final key = _key.text.trim();
    if (key.isEmpty) {
      setState(() => _modelFetchNotice = 'Vui lòng nhập API Key trước');
      return;
    }
    setState(() {
      _fetchingModels = true;
      _modelFetchNotice = null;
    });
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$key'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final models = (data['models'] as List).cast<Map<String, dynamic>>();
        final names = models
            .where((m) => (m['supportedGenerationMethods'] as List?)?.contains('generateContent') ?? false)
            .map((m) => (m['name'] as String).replaceFirst('models/', ''))
            .toList();
        if (names.isNotEmpty) {
          setState(() {
            _geminiModels = names;
            if (!names.contains(_gemini.text)) {
              _gemini.text = names.first;
              _write();
            }
            _modelFetchNotice = 'Đã tải ${names.length} mô hình';
          });
        }
      } else {
        setState(() => _modelFetchNotice = 'Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _modelFetchNotice = 'Lỗi kết nối mạng');
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  @override
  void dispose() {
    _key.dispose();
    _gemini.dispose();
    _openai.dispose();
    _base.dispose();
    super.dispose();
  }

  Future<void> _write({bool announce = false}) async {
    final next = draft.copyWith(
      apiKey: _key.text.trim(),
      geminiModel: _gemini.text.trim(),
      openAiModel: _openai.text.trim(),
      openAiBaseUrl: _base.text.trim(),
    );
    setState(() => draft = next);
    await widget.settings.update(next);
    if (!announce || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu cài đặt trên máy.')));
  }

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _modelMessage = null;
    });
    try {
      await widget.offline.ensureModels(AppLanguage.byCode(draft.heardLanguage), AppLanguage.byCode(draft.myLanguage));
      _modelMessage = 'Đã có mô hình trên máy cho cặp ngôn ngữ này.';
    } catch (e) {
      _modelMessage = 'Lỗi tải: $e\nCần mạng hoặc Google Play Services.';
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.booth.ink,
        foregroundColor: context.booth.paper,
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Eyebrow('Giao diện'),
          const SizedBox(height: 8),
          ChoiceChips<int>(
            selected: draft.themeMode,
            onSelected: (mode) {
              draft = draft.copyWith(themeMode: mode);
              _write();
            },
            options: const [
              (0, 'Hệ thống'),
              (1, 'Sáng'),
              (2, 'Tối'),
            ],
          ),
          const SizedBox(height: 18),
          const Eyebrow('Cỡ chữ bản dịch'),
          const SizedBox(height: 8),
          Slider(
            value: draft.fontSize,
            min: 14.0,
            max: 48.0,
            divisions: 17, // (48-14)/2 = 17 steps
            activeColor: BoothColors.lime,
            label: '${draft.fontSize.round()} px',
            onChanged: (value) {
              draft = draft.copyWith(fontSize: value);
              _write();
            },
          ),
          const SizedBox(height: 18),
          const Eyebrow('Độ chính xác'),
          const SizedBox(height: 8),
          ChoiceChips<EngineMode>(
            selected: draft.engine,
            onSelected: (mode) {
              draft = draft.copyWith(engine: mode);
              _write();
            },
            options: const [
              (EngineMode.online, 'Online · AI'),
              (EngineMode.offline, 'Offline'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Online gửi câu nói và vài lượt trước đó tới AI để giữ ngữ cảnh. Offline dùng mô hình trên máy, không cần mạng sau khi tải.',
            style: TextStyle(color: context.booth.mute, height: 1.35),
          ),
          const SizedBox(height: 18),
          const Eyebrow('Nhà cung cấp AI'),
          const SizedBox(height: 8),
          ChoiceChips<AiProvider>(
            selected: draft.provider,
            onSelected: (provider) {
              draft = draft.copyWith(provider: provider);
              _write();
            },
            options: const [
              (AiProvider.gemini, 'Gemini'),
              (AiProvider.openai, 'OpenAI'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _key,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'API key'),
          ),
          const SizedBox(height: 8),
          if (draft.provider == AiProvider.gemini)
            SelectableText(
              'Lấy API Key miễn phí tại: https://aistudio.google.com/app/apikey',
              style: TextStyle(color: context.booth.mute, fontSize: 13),
            )
          else
            SelectableText(
              'Lấy API Key tại: https://platform.openai.com/api-keys',
              style: TextStyle(color: context.booth.mute, fontSize: 13),
            ),
          const SizedBox(height: 12),
          if (draft.provider == AiProvider.gemini) ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _geminiModels.contains(_gemini.text) ? _gemini.text : (_geminiModels.isNotEmpty ? _geminiModels.first : null),
                    decoration: const InputDecoration(labelText: 'Chọn Mô hình AI (Online)'),
                    items: _geminiModels.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _gemini.text = value;
                        _write();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _fetchingModels ? null : _fetchGeminiModels,
                  icon: _fetchingModels ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                  tooltip: 'Tải danh sách mô hình',
                ),
              ],
            ),
            if (_modelFetchNotice != null) ...[
              const SizedBox(height: 4),
              Text(_modelFetchNotice!, style: const TextStyle(color: BoothColors.lime, fontSize: 13)),
            ],
          ] else ...[
            TextField(
              controller: _openai,
              decoration: const InputDecoration(labelText: 'Model', hintText: 'gpt-4o-mini'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _base,
              decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://api.openai.com/v1'),
            ),
          ],
          const SizedBox(height: 18),
          const Eyebrow('Nhịp ngắt câu'),
          Text('${draft.silenceMs} ms im lặng thì chốt câu', style: TextStyle(color: context.booth.mute)),
          Slider(
            value: draft.silenceMs.toDouble(),
            min: 400,
            max: 1600,
            divisions: 12,
            activeColor: BoothColors.lime,
            label: '${draft.silenceMs} ms',
            onChanged: (value) {
              draft = draft.copyWith(silenceMs: value.round());
              _write();
            },
          ),
          const SizedBox(height: 18),
          const Eyebrow('Giọng đọc (TTS)'),
          const SizedBox(height: 8),
          Text('Tốc độ đọc: ${draft.ttsRate.toStringAsFixed(2)}', style: TextStyle(color: context.booth.mute)),
          Slider(
            value: draft.ttsRate,
            min: 0.1,
            max: 1.5,
            divisions: 14,
            activeColor: BoothColors.lime,
            label: draft.ttsRate.toStringAsFixed(2),
            onChanged: (value) {
              draft = draft.copyWith(ttsRate: value);
              _write();
            },
          ),
          Text('Tone giọng (Pitch): ${draft.ttsPitch.toStringAsFixed(2)}', style: TextStyle(color: context.booth.mute)),
          Slider(
            value: draft.ttsPitch,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            activeColor: BoothColors.lime,
            label: draft.ttsPitch.toStringAsFixed(2),
            onChanged: (value) {
              draft = draft.copyWith(ttsPitch: value);
              _write();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vừa nghe vừa phát'),
            subtitle: Text(
              'Bật khi đeo tai nghe để cuộc nói không phải dừng. Tắt nếu dùng loa, kẻo micro nghe lại bản dịch.',
              style: TextStyle(color: context.booth.mute),
            ),
            value: draft.overlapListening,
            activeThumbColor: BoothColors.lime,
            onChanged: (value) {
              draft = draft.copyWith(overlapListening: value);
              _write();
            },
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: () => _write(announce: true), child: const Text('Lưu khóa API')),
          const SizedBox(height: 22),
          const Eyebrow('Mô hình trên máy'),
          const SizedBox(height: 8),
          Text(
            'Tải ${AppLanguage.byCode(draft.heardLanguage).name} và ${AppLanguage.byCode(draft.myLanguage).name}. Khoảng vài chục MB mỗi ngôn ngữ.',
            style: TextStyle(color: context.booth.mute, height: 1.35),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _downloading ? null : _download,
            child: Text(_downloading ? 'Đang tải...' : 'Tải mô hình offline'),
          ),
          if (_modelMessage != null) ...[
            const SizedBox(height: 8),
            Text(_modelMessage!, style: const TextStyle(color: BoothColors.mint)),
          ],
          const SizedBox(height: 22),
          Text(
            'Nhận dạng giọng nói dùng công cụ của điện thoại. iOS có thể nhận dạng trên máy nếu đã tải ngôn ngữ. Một số máy Android vẫn cần mạng cho bước nghe, dù phần dịch đã offline.',
            style: TextStyle(color: context.booth.mute, height: 1.4),
          ),
          const SizedBox(height: 32),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final info = snapshot.data!;
                return Text(
                  'Phiên bản: ${info.version}+${info.buildNumber}',
                  style: TextStyle(color: context.booth.mute, fontSize: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
