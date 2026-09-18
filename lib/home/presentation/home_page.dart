import 'package:flutter/material.dart';

import '../../cnpj/presentation/cnpj_page.dart';
import '../../cpf/presentation/cpf_page.dart';
import '../../uuid/presentation/uuid_page.dart';

/// Root page hosting a [NavigationRail] that switches between the three
/// generator features.
///
/// Only the selected page is built; each feature's Bloc lives above [HomePage]
/// (provided in `main.dart`), so generated values survive tab switches.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    UuidPage(),
    CpfPage(),
    CnpjPage(),
  ];

  static const _destinations = <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.fingerprint_outlined),
      selectedIcon: Icon(Icons.fingerprint),
      label: Text('UUID v4'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.badge_outlined),
      selectedIcon: Icon(Icons.badge),
      label: Text('CPF'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.business_outlined),
      selectedIcon: Icon(Icons.business),
      label: Text('CNPJ'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fake Generator')),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: _destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
