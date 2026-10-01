# Fake Generator

A Flutter app that generates **UUID v4**, **CPF**, **CNPJ**, **Lorem Ipsum**
placeholder text, **passwords** and **QR Codes**, and edits **cron**
expressions, with one-click copy to the clipboard. CPF and CNPJ are generated with valid check
digits.

Supported targets: **Windows, macOS, Linux, Android, and iOS**.

## Features

- **UUID v4** — random RFC 4122 version-4 identifiers (generated with
  `Random.secure()`).
- **CPF** — valid Cadastro de Pessoa Física numbers, formatted `XXX.XXX.XXX-XX`.
- **CNPJ** — valid Cadastro Nacional da Pessoa Jurídica numbers, formatted
  `XX.XXX.XXX/XXXX-XX` (head-office branch `0001`).
- **Lorem Ipsum** — placeholder text in the spirit of [lipsum.com](https://lipsum.com/).
  Pick the unit (**parágrafos**, **palavras**, **letras** or **listas**), the
  amount, and whether the text opens with the classic
  "Lorem ipsum dolor sit amet...". Word and letter amounts are exact; changing
  an option regenerates the text on the spot.
- **Senha** — random passwords (`Random.secure()`), 4 to 64 characters
  (default 16). Toggle **Letras maiúsculas (A-Z)**, **Letras minúsculas
  (a-z)**, **Números (0-9)** and **Caracteres especiais**, and pick which
  special characters to use: all 32 ASCII punctuation characters are offered,
  and `` `!@#$%^&*()_+-={}|;:',.<>/?~ `` are selected by default (`[ ] " \` are
  left out, since many sites reject them). Every enabled class contributes at
  least one character. Changing an option regenerates the password on the
  spot; **Gerar nova** makes another one.

  **Recentes** lists the last 10 passwords (tap one to copy it) and can clear
  them. The history survives restarts: it is stored with `shared_preferences`,
  in plain text inside the app's own storage. Tuning the options replaces the
  newest entry instead of adding one per step (so dragging the length slider
  does not flush the history), unless that password was copied.

- **Cron** — a cron schedule editor in the spirit of
  [crontab.guru](https://crontab.guru/). Type an expression and it is explained
  on the spot in Portuguese ("Às 04:05.", "A cada 15 minutos nas horas de 9 a
  17, de segunda-feira a sexta-feira."), with the **next 5 runs** in local
  time. Fields typed or pasted without the space between them are spaced
  out automatically (`*****` → `* * * * *`, `*/5*` → `*/5 *`); numbers and
  names are never split, and `@` shortcuts are left alone. The chips under the
  field (minuto, hora, dia (mês), mês, dia (semana))
  follow the cursor, select that field when tapped, and turn red on the field
  an error points at; the **Referência** card lists `*` `,` `-` `/` plus the
  values the current field accepts (or the `@` shortcuts). **Exemplos** offers
  common schedules, and **Gerar** makes up a random, valid expression.

  The syntax is Vixie cron's, as crontab.guru describes it: names
  (`JAN`–`DEC`, `SUN`–`SAT`), 7 as Sunday, steps no larger than the field,
  `@yearly`/`@annually`/`@monthly`/`@weekly`/`@daily`/`@midnight`/`@hourly`/`@reboot`,
  and `5/15` (every 15 from 5) as an extension. When both day of month and day
  of week are restricted the job runs on days matching **either** — unless one
  of them starts with `*`, and then **both** must match; the description and
  the next runs follow that rule. Dates that never exist (`0 0 30 2 *`) are
  flagged.
- **QR Code** — type a text, link, Wi-Fi string, e-mail or phone and the code
  is drawn as you type, black on white with the standard 4-module quiet zone.
  Pick the error correction level (**L** ~7%, **M** ~15%, **Q** ~25%, **H**
  ~30%); the code grows to the smallest version (1–40) that fits, and the line
  under it shows version, size in modules and bytes. Text too long for the
  level (over 2,953 bytes at L down to 1,273 at H) is flagged instead of drawn.
  Accented text is written as UTF-8 behind an ECI header, so scanners do not
  read "ç" as "Ã§". **Gerar** makes up a sample content (link, Wi-Fi, e-mail,
  phone or text). Instead of **Copiar**, this page has **Download**: it saves
  the code as a **512×512 PNG** (black on white, quiet zone included) through
  the platform's "save as" dialog — a file dialog on desktop, the system
  document picker on Android/iOS — and a snack bar says where it went.
  Encoding uses the pure-Dart [`qr`](https://pub.dev/packages/qr) package; the
  preview is a `CustomPainter`, and the PNG is written pixel by pixel in Dart
  (no anti-aliasing), so it does not need the rendering engine.

  On macOS the sandbox only lets the app write where the user chose with the
  `com.apple.security.files.user-selected.read-write` entitlement, present in
  both `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.

Each feature has an empty state, **Gerar / Gerar novo**, **Copiar** (or
**Download**, for QR Codes), and **Limpar** actions.

The layout is responsive, with a single breakpoint at 600 logical pixels
(`lib/shared/presentation/responsive.dart`):

| | Wide (desktop, tablet) | Compact (phone) |
| --- | --- | --- |
| Navigation | `NavigationRail` on the side | `NavigationBar` at the bottom |
| Page padding | 32 | 16 |
| Actions | the three buttons share one row | **Gerar** takes a full-width row of its own, with **Copiar** + **Limpar** below it |
| Generated value | `headlineSmall` | `titleMedium`, scaled down to fit a 36-character UUID |

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
│       └── home_page.dart         # Shell: rail on desktop, bottom bar on phones
├── shared/
│   └── presentation/
│       ├── generator_view.dart    # Reusable result card + generate/copy/clear UI
│       ├── generator_actions.dart # Gerar/Copiar/Limpar bar (Copiar replaceable), stacked when compact
│       ├── responsive.dart        # Compact breakpoint + page padding helpers
│       ├── monospace.dart         # Monospace text style (passwords, cron)
│       └── copy_to_clipboard.dart # Clipboard copy + confirmation snack bar
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
├── cnpj/
│   ├── bloc/                      # CnpjBloc, CnpjEvent, CnpjState
│   │   ├── cnpj_bloc.dart
│   │   ├── cnpj_event.dart
│   │   └── cnpj_state.dart
│   ├── data/
│   │   ├── cnpj_model.dart
│   │   └── cnpj_repository.dart
│   └── presentation/
│       └── cnpj_page.dart
├── lorem/
│   ├── bloc/                      # LoremBloc, LoremEvent, LoremState
│   │   ├── lorem_bloc.dart
│   │   ├── lorem_event.dart
│   │   └── lorem_state.dart
│   ├── data/
│   │   ├── lorem_model.dart
│   │   ├── lorem_repository.dart
│   │   └── lorem_unit.dart        # Unit enum (parágrafos/palavras/letras/listas) + ranges
│   └── presentation/
│       ├── lorem_page.dart        # Bloc wiring
│       └── lorem_view.dart        # Options + result UI
├── password/
│   ├── bloc/                      # PasswordBloc, PasswordEvent, PasswordState
│   │   ├── password_bloc.dart
│   │   ├── password_event.dart
│   │   └── password_state.dart
│   ├── data/
│   │   ├── password_charset.dart  # Character classes (A-Z, a-z, 0-9, special) + labels
│   │   ├── password_options.dart  # Length, enabled classes, chosen special characters + limits
│   │   ├── password_model.dart
│   │   ├── password_repository.dart         # Generation (Random.secure)
│   │   └── password_history_repository.dart # Last 10 passwords, via shared_preferences
│   └── presentation/
│       ├── password_page.dart     # Bloc wiring
│       ├── password_view.dart     # Options + result UI
│       └── recent_passwords.dart  # "Recentes": bottom sheet on phones, dialog on desktop
├── qr_code/
│   ├── bloc/                      # QrCodeBloc, QrCodeEvent, QrCodeState
│   │   ├── qr_code_bloc.dart
│   │   ├── qr_code_event.dart
│   │   └── qr_code_state.dart
│   ├── data/
│   │   ├── qr_code_level.dart     # Error correction levels L/M/Q/H + byte limits
│   │   ├── qr_code_model.dart     # Encoded modules + QrCodeTooLongException
│   │   ├── qr_code_repository.dart # encode() (qr package, UTF-8 + ECI), random() samples
│   │   ├── qr_code_png.dart       # 512×512 PNG encoder (pure Dart: zlib + CRC32)
│   │   └── qr_code_download_repository.dart # Saves the PNG via file_picker's "save as"
│   └── presentation/
│       ├── qr_code_page.dart      # Bloc wiring
│       ├── qr_code_view.dart      # Text field, level selector, preview
│       └── qr_code_painter.dart   # CustomPainter: modules + quiet zone
└── cron/
    ├── bloc/                      # CronBloc, CronEvent, CronState
    │   ├── cron_bloc.dart
    │   ├── cron_event.dart
    │   └── cron_state.dart
    ├── data/
    │   ├── cron_field.dart        # The 5 fields: ranges, JAN-DEC / SUN-SAT names
    │   ├── cron_macro.dart        # @yearly ... @reboot and what they stand for
    │   ├── cron_schedule.dart     # Parser (with per-field errors) + next runs
    │   ├── cron_description.dart  # Portuguese description ("Às 04:05.")
    │   ├── cron_text.dart         # Portuguese words: lists, month and weekday names
    │   ├── cron_model.dart        # Explained expression: description + next runs
    │   ├── cron_example.dart      # The "Exemplos" list
    │   └── cron_repository.dart   # explain(), random(), field positions
    └── presentation/
        ├── cron_page.dart         # Bloc wiring (refreshes the next runs when shown)
        ├── cron_view.dart         # Description, editor + field chips, next runs, reference
        └── cron_examples.dart     # "Exemplos": bottom sheet on phones, dialog on desktop

assets/
└── icon/                          # Icon sources (generated, see "App icon")
    ├── app_icon.png               # 1024² rounded square — Windows .ico, Linux, fallback
    ├── app_icon_ios.png           # 1024² opaque square — iOS applies its own mask
    ├── app_icon_macos.png         # 1024² canvas, 824² body (Apple's macOS grid)
    ├── app_icon_background.png    # Android adaptive icon — background layer
    ├── app_icon_foreground.png    # Android adaptive icon — foreground layer
    └── app_icon_monochrome.png    # Android 13+ themed icon layer

tool/
├── generate_icon.py               # Draws every icon source; also writes the .ico and Linux icons
├── playstore_publish.sh           # Builds the AAB and publishes it to a Google Play track
├── applestore_publish.sh          # Builds the iOS IPA or macOS .pkg and sends it to TestFlight / App Store review
└── notarize.sh                    # Signs the macOS .app with Developer ID, notarizes it and zips it

.github/workflows/
└── release.yml                    # Tag v*.*.* → macOS/Windows/Linux builds on a GitHub Release

linux/packaging/                   # .desktop entry + hicolor icon theme (see its README)

test/
├── widget_test.dart               # App shell, UUID/Lorem/password/cron/QR Code pages, phone-sized layout
├── uuid/                          # UuidRepository + UuidBloc tests
├── cpf/                           # CpfRepository (check-digit validation) + CpfBloc tests
├── cnpj/                          # CnpjRepository (check-digit validation) + CnpjBloc tests
├── lorem/                         # LoremRepository (unit/amount rules) + LoremBloc tests
├── password/                      # Generation, options, persisted history + PasswordBloc tests
├── cron/                          # Parser + next runs, descriptions, random, CronBloc tests
└── qr_code/                       # Encoding, level limits, samples, PNG output, QrCodeBloc (incl. download) tests

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
`br.dev.minello.fakegenerator` on every platform (no underscore, since Apple
bundle identifiers do not accept one). It is set in
`android/app/build.gradle.kts` (`namespace` + `applicationId`, plus the
`android/app/src/main/kotlin/br/dev/minello/fakegenerator/` package directory),
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

## Releases

[.github/workflows/release.yml](.github/workflows/release.yml) builds the desktop
apps and attaches them to a GitHub Release. Trigger it by pushing a tag, or
from *Actions → Release → Run workflow* with a version (the workflow then
creates the tag on the commit it built):

```bash
git tag v1.2.0 && git push origin v1.2.0
```

The version (`X.Y.Z`) becomes the `--build-name` of every build. The release
gets `FakeGenerator-macos.zip`, `FakeGenerator-windows.zip` and
`FakeGenerator-linux.zip`, with notes generated from the commits.

The macOS zip is signed with Developer ID and notarized, so it opens without a
Gatekeeper warning. A local `flutter build macos` is only good on the machine
that built it. To do the same locally:

```bash
flutter build macos --release
tool/notarize.sh   # signs with Developer ID, notarizes, writes build/macos/FakeGenerator-macos.zip
```

It uses the same `ASC_ISSUER_ID`, `ASC_KEY_ID` and `TEAM_ID` as
`tool/applestore_publish.sh`, and needs the *Developer ID Application*
certificate in the keychain (Xcode → Settings → Accounts → Manage Certificates
→ +).

The Release configuration signs with the team's *Apple Development* certificate
(which `applestore_publish.sh` relies on), and the CI runner does not have it.
The workflow therefore builds with an `XCODE_XCCONFIG_FILE` override that makes
the build ad-hoc signed; `notarize.sh` then re-signs it with Developer ID.

The workflow reads these repository secrets:

| Secret | Content |
| --- | --- |
| `MACOS_CERTIFICATE_P12` | Developer ID Application certificate + private key, exported as `.p12`, in base64 |
| `MACOS_CERTIFICATE_PASSWORD` | Password of that `.p12` |
| `ASC_KEY_P8` | Contents of the App Store Connect API key (`AuthKey_<ID>.p8`) |
| `ASC_KEY_ID` | ID of that key |
| `ASC_ISSUER_ID` | Issuer ID (App Store Connect → Users and Access → Integrations) |

## Dependencies

- `flutter_bloc` — state management (BLoC).
- `cupertino_icons` — icons.
- `shared_preferences` — keeps the recent passwords across restarts.
- `qr` — QR Code encoding (pure Dart).
- `file_picker` — the "save as" dialog used to download QR Codes as PNG.
- `bloc_test` (dev) — Bloc unit testing.
- `shared_preferences_platform_interface` (dev) — in-memory preferences for
  tests (`InMemorySharedPreferencesAsync`), since the plugin is not registered
  there.
- `file_picker_platform_interface` (dev) — lets the widget tests replace the
  native save dialog with a fake.
- `flutter_launcher_icons` (dev) — generates the native launcher icons.
