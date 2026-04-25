# Anti

A modern Flutter application built with clean architecture principles, featuring state management with Riverpod, declarative routing with Go Router, and a feature-based project structure.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Development](#development)
- [Code Generation](#code-generation)
- [Environments](#environments)
- [Guidelines](#guidelines)
- [Scripts](#scripts)

## 🎯 Overview

Anti is a Flutter application that demonstrates best practices in mobile app development, including:

- **Clean Architecture** with clear separation of concerns
- **Feature-based organization** for scalable codebase
- **Modern state management** with Riverpod
- **Type-safe routing** with Go Router
- **Multi-environment support** for different deployment stages
- **Clean UI code** principles with widget composition

## ✨ Features

- 🏠 **Dashboard** - Main application screen with navigation
- 👤 **Profile** - User profile management
- ⚙️ **Settings** - Application settings and preferences
- 💸 **Cash Out** - Transaction and recipient management
- 🚀 **Onboarding** - Feature flags and initial setup

## 🛠 Tech Stack

### Core Framework
- **Flutter** `3.38.2` (managed via FVM)
- **Dart SDK** `^3.7.0`

### State Management & Dependency Injection
- **flutter_riverpod** `^3.0.3` - State management and dependency injection
- **riverpod_annotation** `^3.0.3` - Code generation for Riverpod
- **riverpod_generator** `^3.0.3` - Build runner integration

### Navigation
- **go_router** `^17.0.0` - Declarative routing solution

### Networking
- **dio** `^5.4.0` - HTTP client
- **pretty_dio_logger** `^1.4.0` - Request/response logging

### Development Tools
- **build_runner** `^2.7.1` - Code generation
- **flutter_lints** `^5.0.0` - Linting rules
- **rps** `^0.9.1` - Script runner

## 🏗 Architecture

This project follows **Clean Architecture** principles with a feature-based structure:

```
lib/
├── core/                    # Shared utilities and infrastructure
│   ├── constants/          # App-wide constants
│   ├── extensions/         # Widget and type extensions
│   ├── network/            # HTTP client configuration
│   ├── router/             # App routing configuration
│   └── usecase/            # Base use case classes
│
└── features/               # Feature modules
    └── {feature}/
        ├── data/           # Data layer
        │   ├── models/     # Data models
        │   └── repositories/ # Repository implementations
        ├── domain/         # Domain layer
        │   └── entities/   # Business entities
        └── presentation/   # Presentation layer
            ├── controllers/ # State controllers
            ├── screens/    # Screen widgets
            └── widgets/    # Reusable widgets
```

### Architecture Layers

1. **Presentation Layer** (`presentation/`)
   - UI components (screens, widgets)
   - State controllers (Riverpod providers)
   - User interactions

2. **Domain Layer** (`domain/`)
   - Business entities
   - Use cases
   - Business logic

3. **Data Layer** (`data/`)
   - API models
   - Repository implementations
   - Data sources

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `3.38.2` (or use FVM to manage versions)
- Dart SDK `^3.7.0`
- FVM (Flutter Version Management) - [Installation Guide](https://fvm.app/docs/getting_started/installation)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ugk
   ```

2. **Install FVM and Flutter version**
   ```bash
   # Install FVM (if not already installed)
   dart pub global activate fvm
   
   # Install the Flutter version specified in .fvmrc
   fvm install
   ```

3. **Install dependencies**
   ```bash
   # Using FVM
   fvm flutter pub get
   
   # Or using RPS scripts
   rps pub:get
   ```

4. **Generate code**
   ```bash
   # Using RPS scripts
   rps gen:build
   
   # Or manually
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Run the application**
   ```bash
   # Development environment
   fvm flutter run --target lib/main_dev.dart
   
   # Or use the configured launch configurations in VS Code
   ```

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_sizes.dart          # Spacing and size constants
│   ├── extensions/
│   │   └── widget_extension.dart   # Widget extension methods
│   ├── network/
│   │   └── dio_client.dart         # HTTP client setup
│   ├── router/
│   │   └── app_router.dart         # Main app router
│   └── usecase/
│       └── usecase.dart            # Base use case class
│
├── features/
│   ├── cash_out/
│   │   └── presentation/
│   │       └── screens/
│   │           └── select_recipient_screen.dart
│   │
│   ├── home/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   └── profile_screen.dart
│   │   │   └── widgets/
│   │   │       ├── custom_bottom_nav.dart
│   │   │       ├── number_keyboard_bottom_sheet.dart
│   │   │       └── scaffold_with_nav_bar.dart
│   │   └── router/
│   │       └── profile_router.dart
│   │
│   ├── onboarding/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── feature_flags_response.dart
│   │   │   └── repositories/
│   │   │       └── onboarding_repository.dart
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── feature_flags.dart
│   │   ├── presentation/
│   │   │   ├── controllers/
│   │   │   │   └── onboarding_controller.dart
│   │   │   └── screens/
│   │   │       └── onboarding_screen.dart
│   │   └── router/
│   │       └── onboarding_router.dart
│   │
│   └── settings/
│       └── presentation/
│           └── screens/
│               └── settings_screen.dart
│
├── main.dart                        # Common app entry point
├── main_dev.dart                    # Development environment
├── main_sit.dart                    # SIT environment
├── main_uat.dart                    # UAT environment
└── main_prod.dart                   # Production environment
```

## 💻 Development

### Widget Creation Guidelines

This project follows clean UI code principles. When creating widgets:

- **Extract widgets** to avoid deep nesting (max 4 levels)
- **Use composition** over deep nesting
- **Follow consistent styling** patterns
- **Organize files** according to feature-based architecture
- **Use proper naming** conventions

See [AGENTS.md](./AGENTS.md) for detailed widget creation guidelines.

### Key Principles

1. **Widget Extraction**: Keep widget trees shallow (max 4 levels)
2. **Const Constructors**: Always use `const` when possible
3. **Naming**: PascalCase for classes, snake_case for files
4. **Private Widgets**: Prefix with `_` for screen-specific widgets
5. **Styling**: Use consistent spacing, typography, and colors

### Widget Extensions

The project includes convenient widget extensions in `lib/core/extensions/widget_extension.dart`:

```dart
// Padding
widget.paddingAll(16)
widget.paddingSymmetric(horizontal: 16)
widget.paddingOnly(left: 8, top: 16)

// Gestures
widget.onTap(() => doSomething())

// Back button handling
widget.withBackButtonListener(() => handleBack())
```

## 🔧 Code Generation

This project uses code generation for Riverpod providers. After making changes to annotated providers:

### Watch Mode (Recommended for Development)
```bash
rps gen:code
# or
dart run build_runner watch --delete-conflicting-outputs
```

### One-time Build
```bash
rps gen:build
# or
dart run build_runner build --delete-conflicting-outputs
```

### Clean Generated Files
```bash
rps gen:clean
# or
dart run build_runner clean
```

## 🌍 Environments

The project supports multiple environments:

- **Development** (`main_dev.dart`) - Local development
- **SIT** (`main_sit.dart`) - System Integration Testing
- **UAT** (`main_uat.dart`) - User Acceptance Testing
- **Production** (`main_prod.dart`) - Production deployment

Each environment can have different:
- API base URLs
- App titles
- Feature flags
- Configuration settings

### Running Different Environments

```bash
# Development
fvm flutter run --target lib/main_dev.dart

# SIT
fvm flutter run --target lib/main_sit.dart

# UAT
fvm flutter run --target lib/main_uat.dart

# Production
fvm flutter run --target lib/main_prod.dart
```

## 📝 Guidelines

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter_lints` package rules (configured in `analysis_options.yaml`)
- Run `flutter analyze` before committing

### Widget Guidelines

- **Location**: Reusable widgets in `widgets/`, screens in `screens/`
- **Naming**: PascalCase for classes, snake_case for files
- **Const**: Always use `const` constructors when possible
- **Nesting**: Maximum 4 levels of widget nesting
- **Extraction**: Extract complex sections into separate widgets

### Project Rules

This project uses Cursor's rules system. See `.cursor/rules/` for:
- Widget extraction rules
- Widget styling rules
- Widget naming rules
- Screen structure rules
- Router structure rules
- API concurrency rules
- UX writing guidelines

## 📜 Scripts

This project uses [RPS](https://pub.dev/packages/rps) for script management:

### Code Generation
```bash
rps gen:code      # Watch mode for code generation
rps gen:build     # One-time build
rps gen:clean     # Clean generated files
```

### Package Management
```bash
rps pub:get       # Get dependencies
rps pub:upgrade   # Upgrade dependencies
```

### Clean
```bash
rps clean         # Clean build and reinstall dependencies
```

## 🧪 Testing

```bash
# Run all tests
fvm flutter test

# Run tests with coverage
fvm flutter test --coverage
```

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Go Router Documentation](https://pub.dev/documentation/go_router/latest/)
- [FVM Documentation](https://fvm.app/)
- [Clean UI Code in Flutter](https://medium.com/@ximya/clean-your-ui-code-in-flutter-7c58bf3e267d)

## 📄 License

[Add your license information here]

---

**Built with ❤️ using Flutter**
