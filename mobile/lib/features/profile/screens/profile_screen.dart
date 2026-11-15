import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:openair/app/theme.dart';
import 'package:openair/features/auth/bloc/auth_bloc.dart';
import 'package:openair/features/auth/models/auth_models.dart';
import 'package:openair/features/settings/bloc/settings_bloc.dart';

/// The account and app settings, opened from the Home header.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => state is AuthSuccess
                ? _AccountCard(user: state.user)
                : const _GuestCard(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Appearance', style: theme.textTheme.titleSmall?.copyWith(color: colors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) => SwitchListTile(
                title: const Text('Dark mode'),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: state.themeMode == ThemeMode.dark,
                onChanged: (_) => context.read<SettingsBloc>().add(ThemeToggled()),
              ),
            ),
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is! AuthSuccess) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: OutlinedButton.icon(
                  onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AuthUser user;
  const _AccountCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final initial = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.brand,
              foregroundColor: colors.onBrand,
              child: Text(initial, style: theme.textTheme.titleLarge?.copyWith(color: colors.onBrand)),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('You are browsing as a guest', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sign in to keep your library and watch history, and to subscribe.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Sign in'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => context.go('/register'),
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
