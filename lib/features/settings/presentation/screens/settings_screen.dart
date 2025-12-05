import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:anti/core/extensions/widget_extension.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(),
            const SizedBox(height: 32),
            _ContentSection(),
          ],
        ).paddingAll(24.0),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Settings',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsItem(
          icon: Icons.account_balance_wallet,
          title: 'Money Tracker with AI',
          color: Colors.blue,
          onTap: () {
            // TODO: Navigate to Money Tracker with AI
          },
        ),
        const SizedBox(height: 16),
        _SettingsItem(
          icon: Icons.logout,
          title: 'Log Out',
          color: Colors.red,
          onTap: () {
            context.go('/onboarding');
          },
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color == Colors.red ? Colors.red : Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }
}
