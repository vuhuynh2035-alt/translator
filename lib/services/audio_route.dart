import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/settings.dart';

class AudioRoute {
  Future<void> apply(PlaybackTarget target) async {
    if (kIsWeb) return;
    final speaker = target == PlaybackTarget.speaker;
    final session = await AudioSession.instance;
    final iosOptions = AVAudioSessionCategoryOptions.allowBluetooth |
        AVAudioSessionCategoryOptions.allowBluetoothA2dp |
        (speaker ? AVAudioSessionCategoryOptions.defaultToSpeaker : AVAudioSessionCategoryOptions.none);
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: iosOptions,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
    if (Platform.isAndroid) {
      final manager = AndroidAudioManager();
      await manager.setMode(AndroidAudioHardwareMode.inCommunication);
      await manager.setSpeakerphoneOn(speaker);
    }
    if (Platform.isIOS) {
      final tts = FlutterTts();
      await tts.setSharedInstance(true);
      await tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playAndRecord,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          if (speaker) IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
        IosTextToSpeechAudioMode.voiceChat,
      );
    }
  }

  Future<void> release() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      final manager = AndroidAudioManager();
      await manager.setMode(AndroidAudioHardwareMode.normal);
      await manager.setSpeakerphoneOn(false);
    }
    // On iOS, resetting isn't strictly necessary for SpeechToText
  }
}
