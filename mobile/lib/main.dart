import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:openair/app/app.dart';
import 'package:openair/core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  configureDependencies();
  runApp(const OpenAirApp());
}