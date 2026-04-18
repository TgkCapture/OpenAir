import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openair/features/home/screens/home_screen.dart';
import 'package:openair/features/tv/screens/tv_screen.dart';
import 'package:openair/features/radio/screens/radio_screen.dart';
import 'package:openair/features/library/screens/library_screen.dart';
import 'package:openair/features/profile/screens/profile_screen.dart';
import 'package:openair/features/auth/screens/login_screen.dart';
import 'package:openair/features/auth/screens/register_screen.dart';
import 'package:openair/app/shell.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/tv', builder: (_, __) => const TvScreen()),
          GoRoute(path: '/radio', builder: (_, __) => const RadioScreen()),
          GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
}