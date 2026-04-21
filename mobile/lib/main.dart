import 'package:flutter/material.dart';
import 'package:openair/app/app.dart';
import 'package:openair/core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const OpenAirApp());
}