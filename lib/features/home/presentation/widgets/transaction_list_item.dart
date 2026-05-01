import 'package:baht/core/controllers/amount_mask_controller.dart';
import 'package:baht/core/extensions/widget_extension.dart';
import 'package:baht/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionListItem extends ConsumerWidget {
  const TransactionListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.emoji,
    this.onTap,
    this.titleWidget,
    this.iconBackgroundColor,
    this.titleSubtitleSpacing = 4,
  });

  final String title;

  /// When non-null, replaces the default [title] [Text].
  final Widget? titleWidget;
  final String subtitle; // Format: "Category • Date/Time"
  final double amount;
  final String? emoji; // Category emoji for icon container
  final VoidCallback? onTap;

  /// When set, fills the leading icon container instead of the income/expense defaults.
  final Color? iconBackgroundColor;

  /// Vertical gap between [title]/[titleWidget] and [subtitle].
  final double titleSubtitleSpacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = amount > 0;
    const brandTeal = Color(0xFF1A5C52);
    final amountColor = isIncome ? brandTeal : Colors.black;

    final amountText = formatCurrencySignedMasked(
      amount,
      isMasked: ref.watch(amountMaskControllerProvider),
    );

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon container
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
                iconBackgroundColor ??
                (isIncome
                    ? brandTeal.withValues(alpha: 0.08)
                    : Colors.grey[100]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child:
                emoji != null && emoji!.trim().isNotEmpty
                    ? Text(emoji!.trim(), style: const TextStyle(fontSize: 24))
                    : Icon(
                      isIncome
                          ? Icons.arrow_circle_up
                          : Icons.arrow_circle_down,
                      color: Colors.grey[600],
                      size: 24,
                    ),
          ),
        ),
        const SizedBox(width: 12),
        // Text block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget ??
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              SizedBox(height: titleSubtitleSpacing),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Amount
        Text(
          amountText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: amountColor,
          ),
        ),
      ],
    );

    if (onTap != null) {
      content = content.onTap(onTap: onTap);
    }

    return content;
  }
}
