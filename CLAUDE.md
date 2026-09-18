# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

This is a Flutter project in early development, with a single feature Generate UUID.

Only the **Windows desktop** platform is configured (see [windows/](windows/) and `.metadata`). There are no `android/`, `ios/`, `web/`, `linux/`, or `macos/` runner directories, so `flutter run` / `flutter build` target Windows. Add platforms with `flutter create --platforms=<name> .` before targeting them.

## Architecture standard

This project **must follow the BLoC (Business Logic Component) pattern** for state management. All new feature work should adhere to it:

- Keep business logic out of widgets. UI widgets only dispatch events and render state.
- Each feature has a Bloc (or Cubit) with explicit **State** classes and, for Blocs, explicit **Event** classes.
- Use the `flutter_bloc` package (`BlocProvider`, `BlocBuilder`, `BlocListener`, `context.read`/`context.watch`). Add it with `flutter pub add flutter_bloc` — it is not yet a dependency.
- Suggested layering: `presentation` (widgets) → `bloc` (blocs/cubits, events, states) → `domain`/`data` (repositories, models). Widgets never call repositories directly; the Bloc mediates.
- The UUID feature lives under [lib/uuid/](lib/uuid/), split into `presentation/` (`UuidPage` + view widgets), `bloc/` (`UuidBloc` with `UuidEvent`/`UuidState`), and `data/` (`UuidRepository`, `UuidModel`). [lib/main.dart](lib/main.dart) wires them together with `RepositoryProvider` + `BlocProvider`. New features should follow the same layering.

## Commands

```powershell
flutter pub get                 # install/sync dependencies (run after editing pubspec.yaml)
flutter run -d windows          # run the app on Windows desktop with hot reload
flutter analyze                 # static analysis / lint (rules from flutter_lints, see analysis_options.yaml)
flutter test                    # run all tests
flutter test test/widget_test.dart                              # run a single test file
flutter test --plain-name "Counter increments smoke test"       # run a single test by name
flutter build windows           # build a release Windows executable
dart format .                   # format code
```

## Notes

- **Whenever new files are created, update [README.md](README.md) with the current project structure** so it always reflects the files and directories that exist in the repo.
- Dart SDK constraint is `>=3.4.4 <4.0.0` (`pubspec.yaml`). Flutter channel is `stable`.
- Non-SDK dependencies: `flutter_bloc` (state management), `cupertino_icons`. Add new packages via `flutter pub add <name>` so `pubspec.yaml` and `pubspec.lock` stay in sync.
- [test/widget_test.dart](test/widget_test.dart) covers the `UuidBloc` (driven by a fake repository) and the `UuidPage` widget (empty state, UUID render, close). It no longer references the removed counter.