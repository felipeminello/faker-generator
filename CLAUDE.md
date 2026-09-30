# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

This is a Flutter project in early development. The app is called **Fake Generator** (Dart package `fake_generator`) and generates UUID v4, CPF, and CNPJ values, Lorem Ipsum placeholder text, and passwords, and has a cron expression editor.

**Windows, macOS, Linux, Android, and iOS** runner directories are configured (see `.metadata`); there is no `web/`. Add it with `flutter create --platforms=web .` before targeting it. Development happens on Windows, so `flutter run` defaults to `-d windows`.

The display name lives in a different file on every platform — see the "Where the app name lives" table in [README.md](README.md) and change all of them together.

## App icon

The icon is **drawn by code**, not stored as an editable binary: [tool/generate_icon.py](tool/generate_icon.py) (Python 3 + pillow + numpy) writes every source PNG in `assets/icon/`, the Windows `.ico`, and the Linux hicolor icons. After changing it:

```powershell
python tool/generate_icon.py     # redraw the sources
dart run flutter_launcher_icons  # propagate to android/, ios/, macos/
```

Do not hand-edit the generated icons under `android/`, `ios/`, `macos/`, `windows/runner/resources/`, or `linux/packaging/icons/` — they are overwritten. Windows and Linux are handled by the script rather than by `flutter_launcher_icons`; README.md explains why.

## Architecture standard

This project **must follow the BLoC (Business Logic Component) pattern** for state management. All new feature work should adhere to it:

- Keep business logic out of widgets. UI widgets only dispatch events and render state.
- Each feature has a Bloc (or Cubit) with explicit **State** classes and, for Blocs, explicit **Event** classes.
- Use the `flutter_bloc` package (`BlocProvider`, `BlocBuilder`, `BlocListener`, `context.read`/`context.watch`).
- Suggested layering: `presentation` (widgets) → `bloc` (blocs/cubits, events, states) → `domain`/`data` (repositories, models). Widgets never call repositories directly; the Bloc mediates.
- The UUID feature lives under [lib/uuid/](lib/uuid/), split into `presentation/` (`UuidPage` + view widgets), `bloc/` (`UuidBloc` with `UuidEvent`/`UuidState`), and `data/` (`UuidRepository`, `UuidModel`). [lib/main.dart](lib/main.dart) wires them together with `RepositoryProvider` + `BlocProvider`. New features should follow the same layering.
- CPF, CNPJ, and Lorem Ipsum ([lib/lorem/](lib/lorem/)) follow the same layout. Lorem Ipsum is the configurable one: its options (unit, amount, opening sentence) live in a single `LoremState`, not in the widgets.
- The cron editor ([lib/cron/](lib/cron/)) is modeled on crontab.guru: `CronState` holds the typed text plus either a `CronModel` (Portuguese description + next runs) or a `CronFormatException` (message + the field at fault). Parsing, descriptions and the cursor→field lookup live in `data/`; the view only mirrors the text field into `CronExpressionChanged`/`CronCursorMoved`, and its input formatter inserts the spaces `CronSchedule.missingSpaces` says are missing between fields. It follows Vixie cron semantics, including the day-of-month/day-of-week "or" rule — keep `CronSchedule.runsOn` and the description in `cron_description.dart` in agreement.
- The password feature ([lib/password/](lib/password/)) is configurable the same way (`PasswordOptions` inside `PasswordState`) and is the only one with persistence: `PasswordHistoryRepository` keeps the last 10 passwords through `shared_preferences`. `PasswordBloc` only saves after the stored history has been loaded (`PasswordHistoryRequested`, added in `main.dart`), so an early generation cannot overwrite it.

## Commands

```powershell
flutter pub get                 # install/sync dependencies (run after editing pubspec.yaml)
flutter run -d windows          # run the app on Windows desktop with hot reload
flutter analyze                 # static analysis / lint (rules from flutter_lints, see analysis_options.yaml)
flutter test                    # run all tests
flutter test test/widget_test.dart                              # run a single test file
flutter test --plain-name "Counter increments smoke test"       # run a single test by name
flutter build windows           # release build (also: macos, linux, apk, ipa)
python tool/generate_icon.py    # redraw the icon sources (Python 3 + pillow + numpy)
dart run flutter_launcher_icons # apply icons to android/, ios/, macos/
dart format .                   # format code
tool/notarize.sh                # after flutter build macos: Developer ID signing + notarization + zip
```

Releases: pushing a `vX.Y.Z` tag runs [.github/workflows/release.yml](.github/workflows/release.yml), which builds macOS (notarized), Windows, and Linux and attaches the zips to a GitHub Release. The macOS Release config signs with Apple Development (for `tool/applestore_publish.sh`), so CI builds with an `XCODE_XCCONFIG_FILE` ad-hoc override before `notarize.sh` re-signs — keep that step if the signing settings change. See "Releases" in README.md for the required secrets.

## Notes

- **Whenever new files are created, update [README.md](README.md) with the current project structure** so it always reflects the files and directories that exist in the repo.
- Dart SDK constraint is `>=3.4.4 <4.0.0` (`pubspec.yaml`). Flutter channel is `stable`.
- Non-SDK dependencies: `flutter_bloc` (state management), `cupertino_icons`, `shared_preferences` (password history); dev-only: `bloc_test`, `flutter_launcher_icons`, `shared_preferences_platform_interface`. Add new packages via `flutter pub add <name>` so `pubspec.yaml` and `pubspec.lock` stay in sync.
- Widget tests that open the password page need `SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty()` (see `test/widget_test.dart`): the plugin is not registered under `flutter test`. Likewise, copying hangs in tests unless the `SystemChannels.platform` clipboard call is mocked.
- [test/widget_test.dart](test/widget_test.dart) covers the `UuidBloc` (driven by a fake repository) and the `UuidPage` widget (empty state, UUID render, close). It no longer references the removed counter.