import 'package:flutter/material.dart';

import '../../cnpj/presentation/cnpj_page.dart';
import '../../cpf/presentation/cpf_page.dart';
import '../../lorem/presentation/lorem_page.dart';
import '../../shared/presentation/responsive.dart';
import '../../uuid/presentation/uuid_page.dart';

/// Root page that switches between the generator features.
///
/// Wide windows get a [NavigationRail] on the side; phone-sized windows get a
/// [NavigationBar] at the bottom, which is the reachable spot on a touch
/// device and leaves the full width to the feature.
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
    LoremPage(),
  ];

  /// One entry per feature, shared by the rail and the bottom bar.
  static const _destinations = <_Destination>[
    _Destination(
      icon: Icons.fingerprint_outlined,
      selectedIcon: Icons.fingerprint,
      label: 'UUID v4',
    ),
    _Destination(
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
      label: 'CPF',
    ),
    _Destination(
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
      label: 'CNPJ',
    ),
    _Destination(
      icon: Icons.article_outlined,
      selectedIcon: Icons.article,
      label: 'Lorem',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final page = _pages[_selectedIndex];

    if (isCompact(context)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fake Generator')),
        body: SafeArea(child: page),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final destination in _destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Fake Generator')),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _select,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final destination in _destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: page),
        ],
      ),
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);
}

/// Feature entry rendered either as a rail or as a bottom-bar destination.
class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
