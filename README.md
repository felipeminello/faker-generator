# Fake Generator

A Flutter app that generates **UUID v4**, **CPF**, and **CNPJ** values, with
one-click copy to the clipboard. CPF and CNPJ are generated with valid check
digits.

Supported targets: **Windows, macOS, Linux, Android, and iOS**.

## Features

- **UUID v4** — random RFC 4122 version-4 identifiers (generated with
  `Random.secure()`).
- **CPF** — valid Cadastro de Pessoa Física numbers, formatted `XXX.XXX.XXX-XX`.
- **CNPJ** — valid Cadastro Nacional da Pessoa Jurídica numbers, formatted
  `XX.XXX.XXX/XXXX-XX` (head-office branch `0001`).

Each feature has an empty state, **Gerar / Gerar novo**, **Copiar**, and
**Limpar** actions. Navigation between features uses a `NavigationRail`.

## Architecture

The app follows the **BLoC pattern** (see [CLAUDE.md](CLAUDE.md)). Each feature
is split into `presentation/` → `bloc/` → `data/` layers; widgets dispatch
events and render state, and never touch repositories directly.

## Project structure

```
lib/
├── main.dart                      # MultiRepositoryProvider + MultiBlocProvider, MaterialApp
├── home/
│   └── presentation/
│       └── home_page.dart         # NavigationRail shell switching between features
├── shared/
│   └── presentation/
│       └── generator_view.dart    # Reusable result card + generate/copy/clear UI
├── uuid/
│   ├── bloc/                      # UuidBloc, UuidEvent, UuidState
│   │   ├── uuid_bloc.dart
│   │   ├── uuid_event.dart
│   │   └── uuid_state.dart
│   ├── data/
│   │   ├── uuid_model.dart
│   │   └── uuid_repository.dart
│   └── presentation/
│       └── uuid_page.dart
├── cpf/
│   ├── bloc/                      # CpfBloc, CpfEvent, CpfState
│   │   ├── cpf_bloc.dart
│   │   ├── cpf_event.dart
│   │   └── cpf_state.dart
│   ├── data/
│   │   ├── cpf_model.dart
│   │   └── cpf_repository.dart
│   └── presentation/
│       └── cpf_page.dart
└── cnpj/
    ├── bloc/                      # CnpjBloc, CnpjEvent, CnpjState
    │   ├── cnpj_bloc.dart
    │   ├── cnpj_event.dart
    │   └── cnpj_state.dart
    ├── data/
    │   ├── cnpj_model.dart
    │   └── cnpj_repository.dart
    └── presentation/
        └── cnpj_page.dart

assets/
└── icon/                          # Icon sources (generated, see "App icon")
    ├── app_icon.png               # 1024² rounded square — Windows .ico, Linux, fallback
    ├── app_icon_ios.png           # 1024² opaque square — iOS applies its own mask
    ├── app_icon_macos.png         # 1024² canvas, 824² body (Apple's macOS grid)
    ├── app_icon_background.png    # Android adaptive icon — background layer
    ├── app_icon_foreground.png    # Android adaptive icon — foreground layer
    └── app_icon_monochrome.png    # Android 13+ themed icon layer

tool/
└── generate_icon.py               # Draws every icon source; also writes the .ico and Linux icons

linux/packaging/                   # .desktop entry + hicolor icon theme (see its README)

test/
├── widget_test.dart               # App shell + UUID page widget tests
├── uuid/                          # UuidRepository + UuidBloc tests
├── cpf/                           # CpfRepository (check-digit validation) + CpfBloc tests
└── cnpj/                          # CnpjRepository (check-digit validation) + CnpjBloc tests

android/  ios/  linux/  macos/  windows/    # platform runners
```

## App icon

The icon (an ID card with a "just generated" sparkle, on the app's deep-purple
gradient) is drawn programmatically — there is no binary source file to edit.

```powershell
python tool/generate_icon.py     # redraw assets/icon/*, windows .ico, linux icons
dart run flutter_launcher_icons  # propagate to android/, ios/, macos/
```

`tool/generate_icon.py` needs Python 3 with `pillow` and `numpy`. Edit the
constants at the top of that script (colors, tilt) to restyle the icon.

Which tool owns what:

| Platform | Icon location | Written by |
| --- | --- | --- |
| Android | `android/app/src/main/res/{mipmap,drawable}-*/` | `flutter_launcher_icons` |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | `flutter_launcher_icons` |
| macOS | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` | `flutter_launcher_icons` |
| Windows | `windows/runner/resources/app_icon.ico` | `tool/generate_icon.py` |
| Linux | window icon at runtime + `linux/packaging/icons/` | `tool/generate_icon.py` |

Windows is handled by the script instead of `flutter_launcher_icons` because the
package writes a single 256px frame, while the script embeds 16–256px frames for
a sharp taskbar icon. Linux has no `flutter_launcher_icons` support at all: the
GTK runner loads `assets/icon/app_icon.png` from the bundle at startup
(`linux/runner/my_application.cc`), and packaging uses
[linux/packaging/](linux/packaging/README.md).

The `flutter_launcher_icons` configuration lives in the section of the same name
in [pubspec.yaml](pubspec.yaml).

## Where the app name lives

"Fake Generator" is set per platform; update all of these together:

| Platform | File | Key |
| --- | --- | --- |
| Flutter | `lib/main.dart`, `lib/home/presentation/home_page.dart` | `MaterialApp.title`, `AppBar` |
| Android | `android/app/src/main/AndroidManifest.xml` | `android:label` |
| iOS | `ios/Runner/Info.plist` | `CFBundleDisplayName`, `CFBundleName` |
| macOS | `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_NAME` |
| Linux | `linux/runner/my_application.cc`, `linux/packaging/*.desktop` | window title, `Name=` |
| Windows | `windows/runner/main.cpp`, `windows/runner/Runner.rc` | window title, `ProductName` |

The Dart package is `fake_generator`; the application id is
`br.dev.minello.fake_generator` (`br.dev.minello.fakeGenerator` on Apple
platforms, since bundle identifiers do not accept underscores). It is set in
`android/app/build.gradle.kts` (`namespace` + `applicationId`, plus the
`android/app/src/main/kotlin/br/dev/minello/fake_generator/` package directory),
`ios/Runner.xcodeproj/project.pbxproj`,
`macos/Runner/Configs/AppInfo.xcconfig`, `linux/CMakeLists.txt`
(`APPLICATION_ID`) and `tool/generate_icon.py` (`LINUX_APP_ID`, which names the
generated hicolor icon files) — and it names the `.desktop` entry and the
icons under `linux/packaging/`, so those files must be renamed alongside it.

## Commands

```powershell
flutter pub get             # install/sync dependencies
flutter run -d windows      # run on Windows desktop with hot reload
flutter analyze             # static analysis / lint
flutter test                # run all tests
dart format .               # format code

flutter build windows       # release build per platform
flutter build macos
flutter build linux
flutter build apk
flutter build ipa
```

Desktop builds keep a CMake cache under `build/`. After renaming the binary or
changing CMake settings, run `flutter clean` first, and close any running copy of
the app — a running instance locks `flutter_windows.dll` and the build fails on
the install step with `Permission denied`.

## Dependencies

- `flutter_bloc` — state management (BLoC).
- `cupertino_icons` — icons.
- `bloc_test` (dev) — Bloc unit testing.
- `flutter_launcher_icons` (dev) — generates the native launcher icons.
