# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

This is a Flutter project in early development. The app is called **Massa de Teste** ("Massa Teste" under the icon on iOS/Android; it was "Fake Generator" until 1.2, and the Dart package `fake_generator` and the id `br.dev.minello.fakegenerator` keep that name). It is test data for Brazilian developers and QA: it generates CPF and CNPJ values (numeric and the new alphanumeric CNPJ) one at a time or in exportable lists, validates pasted CPFs/CNPJs, generates UUID v4s, has a cron expression editor, and — under "Outras ferramentas" — Lorem Ipsum, password and QR Code generators. The Apple review rejected 1.2 under guideline 4.3 (spam: "just another generator"), so keep new work pointed at what sets it apart (Brazilian documents, developer tooling) rather than at more generic generators.

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
- Lorem Ipsum ([lib/lorem/](lib/lorem/)) follows the same layout and keeps its options (unit, amount, opening sentence) in a single `LoremState`, not in the widgets.
- CPF ([lib/cpf/](lib/cpf/)) and CNPJ ([lib/cnpj/](lib/cnpj/)) are configurable the same way: `CpfState`/`CnpjState` hold the options (amount up to `maxCount`, `Uf` / `CnpjKind` + head office, punctuation), the generated list, and the export status. Both pages render `ListGeneratorView` (shared), and **Exportar** goes `CpfExportRequested`/`CnpjExportRequested` → `ListExportRepository` (shared, `file_picker`'s `saveFile`, CSV/JSON/TXT via `ExportFormat`). The check digits are static `CpfRepository.checkDigits`/`CnpjRepository.checkDigits`; the CNPJ one follows the Receita Federal alphanumeric rule (ASCII code − 48), which leaves numeric CNPJs unchanged — keep `12.ABC.345/01DE-35` passing.
- The validator ([lib/validator/](lib/validator/)) checks as the user types, like the cron editor: `ValidatorState` holds the text plus one `DocumentValidation` per line. `ValidatorRepository` (pure, `const`) tells CPF from CNPJ by length, reuses the two `checkDigits`, and writes the Portuguese explanations and suggestions; the view only mirrors the text field (and Colar reads the clipboard there).
- The cron editor ([lib/cron/](lib/cron/)) is modeled on crontab.guru: `CronState` holds the typed text plus either a `CronModel` (Portuguese description + next runs) or a `CronFormatException` (message + the field at fault). Parsing, descriptions and the cursor→field lookup live in `data/`; the view only mirrors the text field into `CronExpressionChanged`/`CronCursorMoved`, and its input formatter inserts the spaces `CronSchedule.missingSpaces` says are missing between fields. It follows Vixie cron semantics, including the day-of-month/day-of-week "or" rule — keep `CronSchedule.runsOn` and the description in `cron_description.dart` in agreement.
- The QR Code feature ([lib/qr_code/](lib/qr_code/)) encodes as the user types, like the cron editor: `QrCodeState` holds the text, the `QrCodeLevel` and either a `QrCodeModel` (the module grid) or a `QrCodeTooLongException`. Encoding is done by the pure-Dart `qr` package inside `QrCodeRepository` only; non-ASCII text goes in as UTF-8 behind an ECI header, because the package would otherwise leave Latin-1 characters like "ç" without one. `QrCodePainter` draws black on white regardless of theme. Instead of "Copiar" the page has "Download" (`GeneratorActions.secondaryAction`): `QrCodeDownloadRequested` → `QrCodeDownloadRepository` writes a 512×512 PNG (`encodeQrCodePng`, pure Dart) through `file_picker`'s `saveFile`, and `QrCodeState.download` drives the snack bar. macOS needs the `com.apple.security.files.user-selected.read-write` entitlement for that — keep it in both entitlements files.
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
python3 tool/store_media/capture.py <udid> iphone  # App Store screenshots (also: <udid> ipad, mac), then compose.py
python3 tool/store_media/creative.py               # App Store header and search result images (after capture.py iphone)
```

Releases: pushing a `vX.Y.Z` tag runs [.github/workflows/release.yml](.github/workflows/release.yml), which builds macOS (notarized), Windows, and Linux and attaches the zips to a GitHub Release. The macOS Release config signs with Apple Development (for `tool/applestore_publish.sh`), so CI builds with an `XCODE_XCCONFIG_FILE` ad-hoc override before `notarize.sh` re-signs — keep that step if the signing settings change. See "Releases" in README.md for the required secrets.

## Notes

- **Whenever new files are created, update [README.md](README.md) with the current project structure** so it always reflects the files and directories that exist in the repo.
- Dart SDK constraint is `^3.12.1` (`pubspec.yaml`), so null-aware collection elements (`[?value]`) are fine. Flutter channel is `stable`.
- Non-SDK dependencies: `flutter_bloc` (state management), `cupertino_icons`, `shared_preferences` (password history), `qr` (QR Code encoding), `file_picker` (QR Code PNG download, CPF/CNPJ list export); dev-only: `bloc_test`, `file_picker_platform_interface`, `flutter_launcher_icons`, `shared_preferences_platform_interface`. Add new packages via `flutter pub add <name>` so `pubspec.yaml` and `pubspec.lock` stay in sync.
- Widget tests that open the password page need `SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty()` (see `test/widget_test.dart`): the plugin is not registered under `flutter test`. Likewise, copying hangs in tests unless the `SystemChannels.platform` clipboard call is mocked, and the QR Code download and the list export need a fake `FilePickerPlatform.instance` (`_FakeFilePicker` there, which answers `/tmp/<suggested name>`).
- [test/widget_test.dart](test/widget_test.dart) covers the app shell and every page. The default 800×600 test window gets the `NavigationRail` (use `_open`, which scrolls it); phone-sized tests reach the tools outside the bottom bar through "Mais" (`_openOnPhone`). Bloc tests fake file saving with `test/shared/fake_save_dialog.dart`.
- Navigation ([lib/home/presentation/home_page.dart](lib/home/presentation/home_page.dart)) groups the tools in sections, documents first: side panel ≥ 840 px, rail 600–840, bottom bar (CPF, CNPJ, Validar, Mais) below 600. Adding a tool means adding it to `_sections`, and to `integration_test/store_media_test.dart` if it belongs in the screenshots.