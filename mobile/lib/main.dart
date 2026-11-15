import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:openair/app/app.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keeps radio and podcasts playing in the background, with controls in the
  // notification and on the lock screen.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.tgkcapture.openair.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  await NotificationService.init();
  await configureDependencies();
  runApp(const OpenAirApp());
}