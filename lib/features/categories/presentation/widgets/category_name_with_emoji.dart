import 'package:baht/features/categories/domain/entities/category.dart';
import 'package:flutter/material.dart';

class CategoryNameWithEmoji extends StatelessWidget {
  final String label;
  final String? emoji;
  final TextStyle? textStyle;
  final double spacing;
  final double emojiSizeDelta;
  final double emojiMinSize;
  final double emojiMaxSize;
  final int maxLines;

  const CategoryNameWithEmoji({
    super.key,
    required this.label,
    required this.emoji,
    this.textStyle,
    this.spacing = 8,
    this.emojiSizeDelta = 6,
    this.emojiMinSize = 18,
    this.emojiMaxSize = 28,
    this.maxLines = 1,
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
      return Text(
        label,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          normalizedEmoji,
          style: (style ?? const TextStyle()).copyWith(fontSize: emojiFontSize),
        ),
        SizedBox(width: spacing),
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
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

  // Composite labels: "Main - Sub"
  final parts = label.split(' - ');
  if (parts.length == 2) {
    final mainLabel = parts[0].trim().toLowerCase();
    final subLabel = parts[1].trim().toLowerCase();
    if (mainLabel.isNotEmpty && subLabel.isNotEmpty) {
      Category? main;
      for (final c in candidates) {
        if (c.parentId != null) continue;
        if (c.label.trim().toLowerCase() != mainLabel) continue;
        main = c;
        break;
      }

      if (main != null) {
        // Prefer sub emoji under the matched main.
        for (final c in candidates) {
          if (c.parentId != main.id) continue;
          if (c.label.trim().toLowerCase() != subLabel) continue;
          final e = (c.emoji ?? '').trim();
          if (e.isNotEmpty) return e;
          break;
        }

        // Fallback to main emoji.
        final e = (main.emoji ?? '').trim();
        return e.isEmpty ? null : e;
      }
    }
  }

  for (final c in candidates) {
    if (c.label.trim().toLowerCase() != normalizedLabel) continue;
    final e = (c.emoji ?? '').trim();
    return e.isEmpty ? null : e;
  }

  return null;
}
