import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:flutter/material.dart';

class CategoryNameWithEmoji extends StatelessWidget {
  final String label;
  final String? emoji;
  final TextStyle? textStyle;
  final double spacing;
  final double emojiSizeDelta;
  final double emojiMinSize;
  final double emojiMaxSize;

  const CategoryNameWithEmoji({
    super.key,
    required this.label,
    required this.emoji,
    this.textStyle,
    this.spacing = 8,
    this.emojiSizeDelta = 6,
    this.emojiMinSize = 18,
    this.emojiMaxSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedEmoji = (emoji ?? '').trim();
    final style = textStyle;
    final baseFontSize = style?.fontSize ?? 14;
    final emojiFontSize = (baseFontSize + emojiSizeDelta).clamp(
      emojiMinSize,
      emojiMaxSize,
    );

    if (normalizedEmoji.isEmpty) {
      return Text(label, style: style);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          normalizedEmoji,
          style: (style ?? const TextStyle()).copyWith(fontSize: emojiFontSize),
        ),
        SizedBox(width: spacing),
        Flexible(child: Text(label, style: style)),
      ],
    );
  }
}

String? resolveCategoryEmoji({
  required String label,
  required List<Category> categories,
  CategoryType? type,
}) {
  final normalizedLabel = label.trim().toLowerCase();
  if (normalizedLabel.isEmpty) return null;

  final candidates =
      type == null
          ? categories
          : categories.where((c) => c.type == type).toList(growable: false);

  for (final c in candidates) {
    if (c.label.trim().toLowerCase() != normalizedLabel) continue;
    final e = (c.emoji ?? '').trim();
    return e.isEmpty ? null : e;
  }

  return null;
}
