import 'dart:io';

import 'package:flutter/services.dart';

/// Keeps Android's Flutter timers alive while an active practice runs with
/// the display off. Other platforms do not use this Android foreground service.
class AndroidPracticePlayback {
  AndroidPracticePlayback._();

  static const MethodChannel _channel =
      MethodChannel('com.abhyas/practice_playback');

  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('startPracticePlayback');
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('stopPracticePlayback');
  }
}
