# Flutter Widget Creation Guidelines

This document provides instructions for creating Flutter widgets following clean UI code principles and project conventions.

## Overview

When creating Flutter widgets, follow these core principles:
- **Extract widgets** to avoid deep nesting (max 4 levels)
- **Use composition** over deep nesting
- **Follow consistent styling** patterns
- **Organize files** according to feature-based architecture
- **Use proper naming** conventions

## Quick Reference

### File Locations
- **Reusable widgets**: `lib/features/{feature}/presentation/widgets/{name}.dart`
- **Screen widgets**: `lib/features/{feature}/presentation/screens/{name}_screen.dart`
- **Private widgets**: Same file as screen (if screen-specific)

### Naming
- **Class**: PascalCase (`InfoCard`, `SettingsScreen`)
- **File**: snake_case (`info_card.dart`, `settings_screen.dart`)
- **Private**: Prefix with `_` (`_FloatingItem`, `_AIBadge`)

### Code Style
- Always use `const` constructors when possible
- Always include `super.key` in constructor
- Use `required` for non-nullable required parameters
- Use nullable types (`String?`) for optional parameters
- Prefer widget extension methods for padding and gestures when it reduces nesting

## Detailed Rules

This project uses Cursor's rules system with focused sub-rules:

### Widget Extraction Rules
See `.cursor/rules/widget-extraction.mdc` for:
- When to extract widgets
- Maximum nesting depth (4 levels)
- Private vs public widget patterns
- Composition guidelines

### Styling Rules
See `.cursor/rules/widget-styling.mdc` for:
- Color system and usage
- Typography scale
- Spacing system
- Common styling patterns
- Border radius and shadows

### Naming Rules
See `.cursor/rules/widget-naming.mdc` for:
- Naming conventions
- File organization
- Public vs private widgets
- Import organization

### Screen Structure Rules
See `.cursor/rules/screen-structure.mdc` for:
- Screen widget templates
- Section extraction patterns
- Common screen layouts
- Navigation patterns

### Widget Extensions
The project includes `lib/core/extensions/widget_extension.dart` with convenient methods:
- `.padding()`, `.paddingAll()`, `.paddingSymmetric()`, `.paddingOnly()` - For cleaner padding
- `.onTap()` - For gesture handling
- `.withBackButtonListener()` - For back button handling

See `.cursor/rules/widget-styling.mdc` for usage examples.

## Widget Creation Checklist

Before creating a widget:
- [ ] File is in correct location (`widgets/` or `screens/`)
- [ ] File name uses snake_case
- [ ] Class name uses PascalCase
- [ ] Uses `const` constructor
- [ ] Has `super.key` in constructor
- [ ] Required parameters marked with `required`
- [ ] Optional parameters have defaults or are nullable
- [ ] No widget tree exceeds 4 levels of nesting
- [ ] Complex sections are extracted into separate widgets
- [ ] Follows project styling patterns
- [ ] Uses consistent spacing and typography

## Common Patterns

### Reusable Widget Template
```dart
import 'package:flutter/material.dart';

class WidgetName extends StatelessWidget {
  final String requiredParam;
  final String? optionalParam;

  const WidgetName({
    super.key,
    required this.requiredParam,
    this.optionalParam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Implementation
    );
  }
}
```

### Screen Widget Template
```dart
import 'package:flutter/material.dart';

class ScreenName extends StatelessWidget {
  const ScreenName({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderSection(),
              const SizedBox(height: 32),
              _ContentSection(),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Styling Quick Reference

### Colors
- Primary: `Colors.white`, `Colors.black`
- Secondary: `Colors.grey[400]`, `Colors.grey[500]`
- Accents: `Colors.blue`, `Colors.red`
- Transparent: `Colors.blue.withValues(alpha: 0.1)`

### Typography
- Headers: `fontSize: 24`, `fontWeight: FontWeight.bold`
- Titles: `fontSize: 16-18`, `fontWeight: FontWeight.w600`
- Body: `fontSize: 14-16`, `fontWeight: FontWeight.w500`
- Subtitles: `fontSize: 14`, `color: Colors.grey[500]`

### Spacing
- Common values: 4, 8, 16, 24, 32
- Use `SizedBox(height: X)` or `SizedBox(width: X)`
- Prefer widget extension methods: `.paddingAll(16)`, `.paddingSymmetric(horizontal: 16)`
- Constants available in `lib/core/constants/app_sizes.dart` (e.g., `Sizes.kP16`)

### Border Radius
- Cards: `BorderRadius.circular(24)`
- Buttons: `BorderRadius.circular(30)`

## Examples

See existing codebase for reference:
- `lib/features/home/presentation/widgets/info_card.dart` - Reusable widget
- `lib/features/settings/presentation/screens/settings_screen.dart` - Screen widget
- `lib/features/onboarding/presentation/screens/money_tracker_onboard_screen.dart` - Screen with private widgets
- `lib/core/extensions/widget_extension.dart` - Widget extension methods
- `lib/core/constants/app_sizes.dart` - Spacing constants

## Resources

- [Clean UI Code in Flutter](https://medium.com/@ximya/clean-your-ui-code-in-flutter-7c58bf3e267d) - Core principles
- [Cursor Rules Documentation](https://cursor.com/docs/context/rules) - Rules system
- Project rules in `.cursor/rules/` directory

