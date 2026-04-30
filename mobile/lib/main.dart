import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:openair/app/app.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await NotificationService.init();
  await configureDependencies();
  runApp(const OpenAirApp());
}