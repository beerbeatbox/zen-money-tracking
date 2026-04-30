import 'package:baht/core/extensions/widget_extension.dart';
import 'package:baht/features/home/domain/entities/dashboard_layout.dart';
import 'package:baht/features/home/presentation/controllers/dashboard_layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';

class EditDashboardDrawer extends ConsumerWidget {
  const EditDashboardDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutAsync = ref.watch(dashboardLayoutControllerProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: layoutAsync.when(
          data:
              (layout) => _EditDashboardBody(
                layout: layout,
                onClose: () => Navigator.of(context).maybePop(),
                onReset:
                    () =>
                        ref
                            .read(dashboardLayoutControllerProvider.notifier)
                            .resetToDefault(),
                onReorderActive:
                    (fromIndex, toIndex) => ref
                        .read(dashboardLayoutControllerProvider.notifier)
                        .reorderActive(fromIndex, toIndex),
                onReorderInactive:
                    (fromIndex, toIndex) => ref
                        .read(dashboardLayoutControllerProvider.notifier)
                        .reorderInactive(fromIndex, toIndex),
                onMoveToActive:
                    (sectionId, index) => ref
                        .read(dashboardLayoutControllerProvider.notifier)
                        .moveToActive(sectionId, index: index),
                onMoveToInactive:
                    (sectionId, index) => ref
                        .read(dashboardLayoutControllerProvider.notifier)
                        .moveToInactive(sectionId, index: index),
              ),
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
          error:
              (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Let's try that again.",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed:
                          () =>
                              ref
                                  .read(
                                    dashboardLayoutControllerProvider.notifier,
                                  )
                                  .resetToDefault(),
                      child: const Text(
                        'Reset layout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

class _EditDashboardBody extends StatelessWidget {
  const _EditDashboardBody({
    required this.layout,
    required this.onClose,
    required this.onReset,
    required this.onReorderActive,
    required this.onReorderInactive,
    required this.onMoveToActive,
    required this.onMoveToInactive,
  });

  final DashboardLayout layout;
  final VoidCallback onClose;
  final VoidCallback onReset;
  final void Function(int fromIndex, int toIndex) onReorderActive;
  final void Function(int fromIndex, int toIndex) onReorderInactive;
  final void Function(DashboardSectionId id, int? index) onMoveToActive;
  final void Function(DashboardSectionId id, int? index) onMoveToInactive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DrawerHeader(onClose: onClose, onReset: onReset),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionList(
                  title: 'Active sections',
                  subtitle: 'These show on your dashboard',
                  sections: layout.active,
                  isActiveList: true,
                  onReorder: onReorderActive,
                  onMoveFromOtherList: onMoveToActive,
                ),
                const SizedBox(height: 16),
                _SectionList(
                  title: 'Inactive sections',
                  subtitle: 'These stay hidden for now',
                  sections: layout.inactive,
                  isActiveList: false,
                  onReorder: onReorderInactive,
                  onMoveFromOtherList: onMoveToInactive,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.onClose, required this.onReset});

  final VoidCallback onClose;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: onReset,
            icon: HeroIcon(
              HeroIcons.arrowPath,
              style: HeroIconStyle.outline,
              color: Colors.black,
            ),
            tooltip: 'Reset layout',
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.black),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.title,
    required this.subtitle,
    required this.sections,
    required this.isActiveList,
    required this.onReorder,
    required this.onMoveFromOtherList,
  });

  final String title;
  final String subtitle;
  final List<DashboardSectionId> sections;
  final bool isActiveList;
  final void Function(int fromIndex, int toIndex) onReorder;
  final void Function(DashboardSectionId id, int? index) onMoveFromOtherList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        _SectionDropList(
          sections: sections,
          isActiveList: isActiveList,
          onReorder: onReorder,
          onMoveFromOtherList: onMoveFromOtherList,
        ),
      ],
    );
  }
}

class _SectionDropList extends StatelessWidget {
  const _SectionDropList({
    required this.sections,
    required this.isActiveList,
    required this.onReorder,
    required this.onMoveFromOtherList,
  });

  final List<DashboardSectionId> sections;
  final bool isActiveList;
  final void Function(int fromIndex, int toIndex) onReorder;
  final void Function(DashboardSectionId id, int? index) onMoveFromOtherList;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var index = 0; index <= sections.length; index++) {
      children.add(
        _DropZone(
          isActiveList: isActiveList,
          targetIndex: index,
          onReorder: onReorder,
          onMoveFromOtherList: onMoveFromOtherList,
        ),
      );

      if (index < sections.length) {
        final section = sections[index];
        children.add(
          _SectionTile(
            section: section,
            isActiveList: isActiveList,
            index: index,
          ),
        );
      }
    }

    return Column(children: children);
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.isActiveList,
    required this.index,
  });

  final DashboardSectionId section;
  final bool isActiveList;
  final int index;

  @override
  Widget build(BuildContext context) {
    final data = _DragData(
      sectionId: section,
      fromActive: isActiveList,
      fromIndex: index,
    );

    return LongPressDraggable<_DragData>(
      data: data,
      feedback: _DragFeedback(section: section),
      childWhenDragging: _DragPlaceholder(section: section),
      child: _SectionCard(section: section),
    ).paddingOnly(bottom: 8);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final DashboardSectionId section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: Colors.black, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  section.subtitle,
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
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.section});

  final DashboardSectionId section;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          section.title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _DragPlaceholder extends StatelessWidget {
  const _DragPlaceholder({required this.section});

  final DashboardSectionId section;

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: 0.35, child: _SectionCard(section: section));
  }
}

class _DropZone extends StatefulWidget {
  const _DropZone({
    required this.isActiveList,
    required this.targetIndex,
    required this.onReorder,
    required this.onMoveFromOtherList,
  });

  final bool isActiveList;
  final int targetIndex;
  final void Function(int fromIndex, int toIndex) onReorder;
  final void Function(DashboardSectionId id, int? index) onMoveFromOtherList;

  @override
  State<_DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone> {
  bool _hasTriggeredHaptic = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DragData>(
      onWillAcceptWithDetails:
          (details) =>
              (details.data.fromActive != widget.isActiveList ||
                  details.data.fromIndex != widget.targetIndex),
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data.fromActive == widget.isActiveList) {
          widget.onReorder(data.fromIndex, widget.targetIndex);
        } else {
          widget.onMoveFromOtherList(data.sectionId, widget.targetIndex);
        }
        _hasTriggeredHaptic = false;
      },
      onLeave: (_) {
        _hasTriggeredHaptic = false;
      },
      builder: (context, candidates, _) {
        final isActive = candidates.isNotEmpty;
        if (isActive && !_hasTriggeredHaptic) {
          HapticFeedback.lightImpact();
          _hasTriggeredHaptic = true;
        }
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 4),
          height: isActive ? 8 : 4,
          decoration: BoxDecoration(
            color: isActive ? Colors.black.withValues(alpha: 0.08) : null,
            borderRadius: BorderRadius.circular(12),
            border:
                isActive ? Border.all(color: Colors.black, width: 1.5) : null,
          ),
        );
      },
    );
  }
}

@immutable
class _DragData {
  const _DragData({
    required this.sectionId,
    required this.fromActive,
    required this.fromIndex,
  });

  final DashboardSectionId sectionId;
  final bool fromActive;
  final int fromIndex;
}
