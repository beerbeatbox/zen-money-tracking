# Flutter Widget Creation Guidelines

This doc consolidates all `.cursor/rules/*.mdc` guidance for widgets, screens, navigation, copy, and async patterns.

## Overview
- Extract and compose widgets; keep build trees shallow (≤4 levels).
- Follow consistent naming, styling, routing, and file layout.
- Use encouraging, action-first UX copy.
- Prefer reusable patterns: extensions, shared dialogs, enum routes, concurrent APIs.

## UX Writing (always on)
- Use positive, action-led, personalized labels (“Your balance”, “Add expense”).
- Empty states should invite action (“Start tracking your expenses”); avoid “No…/Empty”.
- Keep copy short and clear; guide the next step.
- Buttons use verbs; headers use concise title case; success and error copy stays friendly.
- Checklist: positive, action-oriented, personalized when helpful, concise, avoids negative framing, gives guidance.

## Naming & File Organization
- Class names: public widgets `PascalCase`; private widgets `_PascalCase`.
- File names: snake_case matching class; screens end with `_screen.dart`.
- Locations: screens in `lib/features/{feature}/presentation/screens/`; reusable widgets in `widgets/`; private/screen-only widgets can live with the screen (extract if large).
- Extract to a separate file when reusable, ≥50 lines, complex state, or shared across screens.
- Import order: Flutter → third-party → core utilities → project imports.

## Widget Extraction & Composition
- Never exceed 4 levels of nesting in a `build()`; extract sections instead.
- Extract when reused, visually distinct, >20 lines, or readability drops.
- Patterns: private widgets for screen-specific pieces; public widgets in `widgets/` for reuse.
- Prefer composition helpers (`_buildHeader()`, `_ContentSection()`) over deep inline trees.
- Checklist: nesting ≤4, reusable parts extracted, clear visual intent, readability improved.

## Styling & Spacing
- Colors: `Colors.white` backgrounds; `Colors.black` primary text; `Colors.grey[400/500]` secondary; `Colors.blue`/`Colors.red` for accents; use `.withValues(alpha: 0.1)` for soft fills.
- Typography: headers 24/bold; titles 16–18/w600; body 14–16/w500; subtitles 14 with grey.
- Spacing: 4, 8, 16, 24, 32; prefer extension padding (`.paddingAll`, `.paddingSymmetric`, `.paddingOnly`) to reduce nesting; constants in `lib/core/constants/app_sizes.dart` (e.g., `Sizes.kP16`).
- Shapes & shadow: cards radius 24, buttons radius 30, subtle shadows via low-opacity greys.
- Patterns: use card/icon/button patterns from `.cursor/rules/widget-styling.mdc`; extract repeated decoration (≥3 uses) into helpers or reusable widgets.

## Widget Extensions (padding + onTap)
- Extensions live in `lib/core/extensions/widget_extension.dart` (`.padding*`, `.onTap`, `.withBackButtonListener`).
- Use `.onTap` when ripple is not needed and you want light haptics; avoid when you need Material ripple/hover/focus or already trigger haptics.
- Defaults: `GestureDetector` with `HitTestBehavior.opaque`, light haptic before callback; set `behavior: HitTestBehavior.translucent` for smaller tap targets.
- Keep handlers short; avoid double haptics by not duplicating feedback in callbacks.

## Screen Structure
- Screens are `Scaffold` + `SafeArea`, white background, typical padding `24.0`.
- Extract sections: `_HeaderSection`, `_ContentSection`, `_ActionButtons`, `_FooterSection`.
- Common layouts: simple list (Column with spacing), scrollable (`CustomScrollView`/`SliverList`), stack-based onboarding with background/floating/content layers.
- Navigation: use `go_router` (`context.go/push`) with enum paths; prefer extension padding to keep trees shallow.
- Checklist: uses `Scaffold`, `SafeArea`, consistent padding, sections extracted, spacing clear, file named `{name}_screen.dart`.

## Dialog Usage
- Use shared outlined confirmation dialog (e.g., `OutlinedConfirmationDialog`) for confirmations; keep UI in widgets and logic in controllers/mixins.
- Supply title/description; primary action required, optional secondary for safe path; labels should follow UX writing (“Clear everything”, “Keep my data”).
- Builder pattern: `showDialog<bool>(builder: (ctx) => OutlinedConfirmationDialog(...))`; pop with `true/false`, then handle result (snackbar/state refresh) in caller.
- Styling: outlined surface; primary button red/white by default, secondary black/white.
- Checklist: shared dialog used, title/description set, primary pops with result, secondary optional, caller handles outcomes.

## Mixins for Events
- File ends with `_events.dart`; mixin ends with `Events`; live beside screens.
- Purpose: orchestration only—call controllers/services, prepare labels. Do not build widgets, dialogs, snackbars, or navigation.
- Accept `WidgetRef` (and simple data); avoid owning `BuildContext` unless for lookups.
- Use mixins on screens (`with SettingsEvents`) and keep UI feedback in the widget layer.
- Checklist: naming correct, logic-only, accepts `WidgetRef`, UI stays in widgets.

## Router Structure
- Enum `AppRouter` defines routes with a `path` getter; values use camelCase, paths use kebab-case.
- Main router in `lib/core/router/app_router.dart` with `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref)` and `part 'app_router.g.dart';`.
- Use `NoTransitionPage` for bottom-nav tabs; shell routes share a navigator; avoid hardcoded paths—use enum `.path`/`.name`.
- Handle extras, query params, and path params via `state.extra`, `state.uri.queryParameters`, and `state.pathParameters`.
- Run codegen after router changes: `dart run build_runner build --delete-conflicting-outputs` (or watch).
- Checklist: enum updated, path getter set, GoRoute added, screen import added, build_runner run.

## API Concurrency
- Use sequential `await` only when calls depend on prior results.
- Use `Future.wait` (or Dart 3 records `.wait`) for independent calls to cut latency; cast or destructure results for type safety.
- Error handling: default fails fast; set `eagerError: false` to collect errors; use `catchError` for graceful degradation per call.
- Mixed patterns: fetch prerequisite, then run dependent batches concurrently.
- Avoid `await` inside `Future.wait` arrays and avoid parallelizing dependent calls.
- Checklist: independence confirmed, parallelized when safe, errors handled, types preserved.

## Widget Creation Checklist
- [ ] File in correct folder (`widgets/` or `screens/`), snake_case name; screens end `_screen.dart`.
- [ ] Class uses PascalCase; private widgets prefixed with `_`.
- [ ] `const` constructor where possible; includes `super.key`; required params marked.
- [ ] Widget tree ≤4 levels; sections extracted; reusable pieces moved to `widgets/` when shared or large.
- [ ] Styling follows color/typography/spacing rules; reuse patterns or extracted decorations.
- [ ] Extensions used to reduce nesting; `.onTap` chosen appropriately (no duplicate haptics).
- [ ] Copy follows UX writing (positive, action-led, personalized); labels and empty states guide users.
- [ ] Screens use `Scaffold` + `SafeArea` + standard padding; navigation via `go_router` enum.
- [ ] Dialogs use shared confirmation widget; results handled by caller.
- [ ] Async code uses `Future.wait` for independent calls; types and errors handled.

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
import 'package:go_router/go_router.dart'; // If navigation needed
import 'package:anti/core/extensions/widget_extension.dart'; // Optional extensions

class ScreenName extends StatelessWidget {
  const ScreenName({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection().paddingOnly(bottom: 32),
            _ContentSection(),
            const Spacer(),
            _ActionButtons(),
          ],
        ).paddingAll(24.0),
      ),
    );
  }
}
```

## State & Data Flow (Controller → Service → Repository with Riverpod codegen)
- Layers: controllers (UI-only, no I/O), services (orchestration), repositories (data access/mapping), datasources (raw storage/API).
- File locations: controllers `presentation/controllers/`; services `domain/usecases/`; repositories `data/repositories/`; datasources `data/datasources/`.
- Riverpod pattern: add `part '<file>.g.dart';`, use `@riverpod`; chain controller → service provider → repository provider → datasource provider.
- Run `dart run build_runner build --delete-conflicting-outputs` after codegen changes.
- UI usage: read via controller providers; for writes call service, then `ref.invalidate(<queryProvider>)` and `await ref.read(<queryProvider>.future)` to refresh.
- Naming: providers `<noun>Provider`; services `<Entity>Service`; repos `<Entity>Repository`; datasources `<Entity>LocalDatasource`.
- Don’ts: no business logic/I/O in controllers; do not bypass service layer from UI.

## Resources
- [Clean UI Code in Flutter](https://medium.com/@ximya/clean-your-ui-code-in-flutter-7c58bf3e267d) - Core principles
- [Cursor Rules Documentation](https://cursor.com/docs/context/rules) - Rules system
- Project rules in `.cursor/rules/` directory

