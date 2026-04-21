import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:openair/features/auth/bloc/auth_bloc.dart';
import 'package:openair/features/settings/bloc/settings_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthSuccess) {
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        state.user.fullName.isNotEmpty ? state.user.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(state.user.fullName, style: Theme.of(context).textTheme.titleLarge),
                    Text(state.user.email, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark mode',
            trailing: BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) => Switch(
                value: state.themeMode == ThemeMode.dark,
                onChanged: (_) => context.read<SettingsBloc>().add(ThemeToggled()),
              ),
            ),
          ),
          const Divider(),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.subscriptions_outlined,
            title: 'Subscription',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.history,
            title: 'Watch history',
            onTap: () {},
          ),
          const Divider(),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sign out',
            color: Colors.red,
            onTap: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const _SettingsTile({required this.icon, required this.title, this.trailing, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}