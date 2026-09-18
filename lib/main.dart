import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cnpj/bloc/cnpj_bloc.dart';
import 'cnpj/data/cnpj_repository.dart';
import 'cpf/bloc/cpf_bloc.dart';
import 'cpf/data/cpf_repository.dart';
import 'home/presentation/home_page.dart';
import 'lorem/bloc/lorem_bloc.dart';
import 'lorem/data/lorem_repository.dart';
import 'uuid/bloc/uuid_bloc.dart';
import 'uuid/data/uuid_repository.dart';

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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => UuidBloc(context.read<UuidRepository>()),
          ),
          BlocProvider(
            create: (context) => CpfBloc(context.read<CpfRepository>()),
          ),
          BlocProvider(
            create: (context) => CnpjBloc(context.read<CnpjRepository>()),
          ),
          BlocProvider(
            create: (context) => LoremBloc(context.read<LoremRepository>()),
          ),
        ],
        child: MaterialApp(
          title: 'Fake Generator',
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
