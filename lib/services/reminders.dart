import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models.dart';

/// Android owns the alarm, snooze and completion checks, even when Flutter closes.
class Reminders {
  static const _channel = MethodChannel('com.josh.tracker/reminders');
  bool available = false;
  bool permitted = false;
  String? error;
  void Function(String?)? onOpen;
  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<void> init() async {
    if (!supported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openHabit') onOpen?.call(call.arguments as String?);
    });
    await status();
  }
  Future<void> status() async {
    if (!supported) return;
    try {
      permitted = await _channel.invokeMethod<bool>('status') ?? false;
      available = true; error = null;
    } catch (_) { error = 'Reminders could not connect. Restart the app.'; }
  }
  Future<bool> request() async {
    if (!supported) return false;
    try {
      permitted = await _channel.invokeMethod<bool>('requestPermission') ?? false;
      return permitted;
    } catch (_) { error = 'Could not enable notifications.'; return false; }
  }
  Future<void> update(TrackerData data, String? userId) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod('configure', jsonEncode({'user':userId, 'state':data.json}));
      error = null;
    } catch (_) { error = 'Reminders need attention. Open Settings to retry.'; }
  }
  Future<String?> launchHabit() async {
    if (!supported) return null;
    try { return await _channel.invokeMethod<String>('launchHabit'); } catch (_) { return null; }
  }
  Future<bool> snooze(String id) async {
    if (!supported) return false;
    try { return await _channel.invokeMethod<bool>('snooze', id) ?? false; } catch (_) { return false; }
  }
  Future<void> openSettings() async {
    if (supported) await _channel.invokeMethod('settings');
  }
  Future<void> test() async {
    if (supported) await _channel.invokeMethod('test');
  }
}
