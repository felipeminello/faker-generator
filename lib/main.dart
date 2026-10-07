import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cnpj/bloc/cnpj_bloc.dart';
import 'cnpj/data/cnpj_repository.dart';
import 'cpf/bloc/cpf_bloc.dart';
import 'cpf/data/cpf_repository.dart';
import 'cron/bloc/cron_bloc.dart';
import 'cron/data/cron_repository.dart';
import 'home/presentation/home_page.dart';
import 'lorem/bloc/lorem_bloc.dart';
import 'lorem/data/lorem_repository.dart';
import 'password/bloc/password_bloc.dart';
import 'password/data/password_history_repository.dart';
import 'password/data/password_repository.dart';
import 'qr_code/bloc/qr_code_bloc.dart';
import 'qr_code/data/qr_code_download_repository.dart';
import 'qr_code/data/qr_code_repository.dart';
import 'shared/data/list_export_repository.dart';
import 'uuid/bloc/uuid_bloc.dart';
import 'uuid/data/uuid_repository.dart';
import 'validator/bloc/validator_bloc.dart';
import 'validator/data/validator_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => UuidRepository()),
        RepositoryProvider(create: (_) => CpfRepository()),
        RepositoryProvider(create: (_) => CnpjRepository()),
        RepositoryProvider(create: (_) => LoremRepository()),
        RepositoryProvider(create: (_) => PasswordRepository()),
        RepositoryProvider(create: (_) => PasswordHistoryRepository()),
        RepositoryProvider(create: (_) => CronRepository()),
        RepositoryProvider(create: (_) => QrCodeRepository()),
        RepositoryProvider(create: (_) => QrCodeDownloadRepository()),
        RepositoryProvider(create: (_) => ListExportRepository()),
        RepositoryProvider(create: (_) => const ValidatorRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => UuidBloc(context.read<UuidRepository>()),
          ),
          BlocProvider(
            create: (context) => CpfBloc(
              context.read<CpfRepository>(),
              context.read<ListExportRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => CnpjBloc(
              context.read<CnpjRepository>(),
              context.read<ListExportRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                ValidatorBloc(context.read<ValidatorRepository>()),
          ),
          BlocProvider(
            create: (context) => LoremBloc(context.read<LoremRepository>()),
          ),
          BlocProvider(
            create: (context) => PasswordBloc(
              context.read<PasswordRepository>(),
              context.read<PasswordHistoryRepository>(),
            )..add(const PasswordHistoryRequested()),
          ),
          BlocProvider(
            create: (context) => CronBloc(context.read<CronRepository>()),
          ),
          BlocProvider(
            create: (context) => QrCodeBloc(
              context.read<QrCodeRepository>(),
              context.read<QrCodeDownloadRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const HomePage(),
        ),
      ),
    );
  }
}
