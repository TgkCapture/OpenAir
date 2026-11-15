import 'package:go_router/go_router.dart';
import 'package:openair/app/shell.dart';
import 'package:openair/features/auth/screens/forgot_password_screen.dart';
import 'package:openair/features/auth/screens/login_screen.dart';
import 'package:openair/features/auth/screens/register_screen.dart';
import 'package:openair/features/home/screens/home_screen.dart';
import 'package:openair/features/library/screens/library_screen.dart';
import 'package:openair/features/live/screens/live_screen.dart';
import 'package:openair/features/profile/screens/profile_screen.dart';
import 'package:openair/features/schedule/screens/schedule_screen.dart';
import 'package:openair/features/search/screens/search_screen.dart';

class AppRouter {
  // The app opens on Home for everyone. Guests can browse and play free
  // content; signing in is offered from the Profile screen.
  static final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),

      // Opened on top of the tabs from the Home header.
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),

      // TV and radio used to be separate tabs; both now live under Live.
      GoRoute(path: '/tv', redirect: (context, state) => '/live'),
      GoRoute(path: '/radio', redirect: (context, state) => '/live'),

      // The four main tabs share the shell (mini player and tab bar). They
      // switch without a slide animation, as tabs should.
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen())),
          GoRoute(path: '/live', pageBuilder: (context, state) => const NoTransitionPage(child: LiveScreen())),
          GoRoute(path: '/schedule', pageBuilder: (context, state) => const NoTransitionPage(child: ScheduleScreen())),
          GoRoute(path: '/library', pageBuilder: (context, state) => const NoTransitionPage(child: LibraryScreen())),
        ],
      ),
    ],
  );
}
