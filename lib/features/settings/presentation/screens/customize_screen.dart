import 'package:baht/core/widgets/section_card.dart';
import 'package:baht/features/settings/domain/entities/bottom_nav_style.dart';
import 'package:baht/features/settings/presentation/controllers/bottom_nav_style_setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CustomizeScreen extends ConsumerWidget {
  const CustomizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styleAsync = ref.watch(bottomNavStyleSettingControllerProvider);
    final style = styleAsync.value ?? BottomNavStyle.floating;
    final busy = styleAsync.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TopBar(),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bottom navigation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StyleOptionRow(
                      value: BottomNavStyle.floating,
                      groupValue: style,
                      title: 'Floating',
                      description: 'Rounded bar that floats above your content.',
                      enabled: !busy,
                      onChanged:
                          (v) => ref
                              .read(
                                bottomNavStyleSettingControllerProvider
                                    .notifier,
                              )
                              .setStyle(v),
                    ),
                    const SizedBox(height: 12),
                    _StyleOptionRow(
                      value: BottomNavStyle.standard,
                      groupValue: style,
                      title: 'Standard',
                      description: 'Full-width white bar along the bottom edge.',
                      enabled: !busy,
                      onChanged:
                          (v) => ref
                              .read(
                                bottomNavStyleSettingControllerProvider
                                    .notifier,
                              )
                              .setStyle(v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customize',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Shape the look of your main navigation',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StyleOptionRow extends StatelessWidget {
  const _StyleOptionRow({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onChanged,
  });

  final BottomNavStyle value;
  final BottomNavStyle groupValue;
  final String title;
  final String description;
  final bool enabled;
  final void Function(BottomNavStyle value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onChanged(value) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<BottomNavStyle>(
                value: value,
                groupValue: groupValue,
                onChanged:
                    enabled
                        ? (v) {
                          if (v != null) onChanged(v);
                        }
                        : null,
                activeColor: Colors.black,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
