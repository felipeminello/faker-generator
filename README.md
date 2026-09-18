# uuid_generator

A Flutter (Windows desktop) app that generates **UUID v4**, **CPF**, and **CNPJ**
values, with one-click copy to the clipboard. CPF and CNPJ are generated with
valid check digits.

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

test/
├── widget_test.dart               # App shell + UUID page widget tests
├── uuid/                          # UuidRepository + UuidBloc tests
├── cpf/                           # CpfRepository (check-digit validation) + CpfBloc tests
└── cnpj/                          # CnpjRepository (check-digit validation) + CnpjBloc tests
```

## Commands

```powershell
flutter pub get             # install/sync dependencies
flutter run -d windows      # run on Windows desktop with hot reload
flutter analyze             # static analysis / lint
flutter test                # run all tests
flutter build windows       # build a release Windows executable
dart format .               # format code
```

## Dependencies

- `flutter_bloc` — state management (BLoC).
- `cupertino_icons` — icons.
- `bloc_test` (dev) — Bloc unit testing.
