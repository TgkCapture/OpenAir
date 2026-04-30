import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:openair/app/shell.dart';
import 'package:openair/features/auth/screens/forgot_password_screen.dart';
import 'package:openair/features/auth/screens/login_screen.dart';
import 'package:openair/features/auth/screens/register_screen.dart';
import 'package:openair/features/home/screens/home_screen.dart';
import 'package:openair/features/tv/screens/tv_screen.dart';
import 'package:openair/features/radio/screens/radio_screen.dart';
import 'package:openair/features/schedule/screens/schedule_screen.dart';
import 'package:openair/features/library/screens/library_screen.dart';
import 'package:openair/features/profile/screens/profile_screen.dart';

class AppRouter {
  static const bool _bypassAuth = kDebugMode;

  static final router = GoRouter(
    initialLocation: _bypassAuth ? '/home' : '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/tv', builder: (context, state) => const TvScreen()),
          GoRoute(path: '/radio', builder: (context, state) => const RadioScreen()),
          GoRoute(path: '/schedule', builder: (context, state) => const ScheduleScreen()),
          GoRoute(path: '/library', builder: (context, state) => const LibraryScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
  );
}