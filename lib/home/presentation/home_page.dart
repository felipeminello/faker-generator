import 'dart:math';

import 'package:flutter/material.dart';

import '../../cnpj/presentation/cnpj_page.dart';
import '../../cpf/presentation/cpf_page.dart';
import '../../cron/presentation/cron_page.dart';
import '../../lorem/presentation/lorem_page.dart';
import '../../password/presentation/password_page.dart';
import '../../qr_code/presentation/qr_code_page.dart';
import '../../shared/presentation/responsive.dart';
import '../../uuid/presentation/uuid_page.dart';
import '../../validator/presentation/validator_page.dart';

/// Name shown in the app bar.
const appTitle = 'Massa de Teste';

/// Root page that switches between the tools.
///
/// The tools come in sections, the Brazilian documents first. Wide windows
/// list them all in a side panel, under their section titles; medium ones
/// get a [NavigationRail]; phone-sized ones keep the document tools in a
/// [NavigationBar] at the bottom (the reachable spot on a touch device) and
/// the rest behind its "Mais" entry, in a bottom sheet.
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

  static const _sections = <_Section>[
    _Section('Documentos', [
      _Tool(
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge,
        label: 'CPF',
        page: CpfPage(),
      ),
      _Tool(
        icon: Icons.business_outlined,
        selectedIcon: Icons.business,
        label: 'CNPJ',
        page: CnpjPage(),
      ),
      _Tool(
        icon: Icons.fact_check_outlined,
        selectedIcon: Icons.fact_check,
        label: 'Validar',
        page: ValidatorPage(),
      ),
    ]),
    _Section('Desenvolvimento', [
      _Tool(
        icon: Icons.fingerprint_outlined,
        selectedIcon: Icons.fingerprint,
        label: 'UUID v4',
        page: UuidPage(),
      ),
      _Tool(
        icon: Icons.schedule_outlined,
        selectedIcon: Icons.schedule,
        label: 'Cron',
        page: CronPage(),
      ),
    ]),
    _Section('Outras ferramentas', [
      _Tool(
        icon: Icons.article_outlined,
        selectedIcon: Icons.article,
        label: 'Lorem',
        page: LoremPage(),
      ),
      _Tool(
        icon: Icons.password_outlined,
        selectedIcon: Icons.password,
        label: 'Senha',
        page: PasswordPage(),
      ),
      _Tool(
        icon: Icons.qr_code_2_outlined,
        selectedIcon: Icons.qr_code_2,
        label: 'QR Code',
        page: QrCodePage(),
      ),
    ]),
  ];

  /// Every tool, in navigation order.
  static final _tools = [for (final section in _sections) ...section.tools];

  /// The tools with their own entry in the phone's bottom bar.
  static final _barTools = _sections.first.tools;

  @override
  Widget build(BuildContext context) {
    final page = _tools[_selectedIndex].page;
    final appBar = AppBar(title: const Text(appTitle));

    if (isCompact(context)) {
      return Scaffold(
        appBar: appBar,
        body: SafeArea(child: page),
        bottomNavigationBar: NavigationBar(
          // Any tool past the bar's own lights up "Mais".
          selectedIndex: min(_selectedIndex, _barTools.length),
          onDestinationSelected: (index) =>
              index < _barTools.length ? _select(index) : _showMore(context),
          destinations: [
            for (final tool in _barTools)
              NavigationDestination(
                icon: Icon(tool.icon),
                selectedIcon: Icon(tool.selectedIcon),
                label: tool.label,
              ),
            const NavigationDestination(
              icon: Icon(Icons.apps_outlined),
              selectedIcon: Icon(Icons.apps),
              label: 'Mais',
            ),
          ],
        ),
      );
    }

    if (!isExpanded(context)) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              scrollable: true,
              destinations: [
                for (final tool in _tools)
                  NavigationRailDestination(
                    icon: Icon(tool.icon),
                    selectedIcon: Icon(tool.selectedIcon),
                    label: Text(tool.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: page),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          SizedBox(
            width: 232,
            // Same color as the page and no elevation: the panel reads as
            // part of the window, set apart only by the divider.
            child: NavigationDrawer(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              backgroundColor: theme.colorScheme.surface,
              elevation: 0,
              children: [
                for (final section in _sections) ...[
                  _SectionTitle(section.title),
                  for (final tool in section.tools)
                    NavigationDrawerDestination(
                      icon: Icon(tool.icon),
                      selectedIcon: Icon(tool.selectedIcon),
                      label: Text(tool.label),
                    ),
                ],
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: page),
        ],
      ),
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  /// Lists the tools that are not in the phone's bottom bar, by section.
  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      // As tall as the list, rather than the default 9/16 of the screen, so
      // every tool shows without scrolling on all but the smallest phones.
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final section in _sections.skip(1)) ...[
              _SectionTitle(section.title),
              for (final tool in section.tools)
                ListTile(
                  leading: Icon(tool.icon),
                  title: Text(tool.label),
                  selected: _tools.indexOf(tool) == _selectedIndex,
                  onTap: () {
                    Navigator.pop(context);
                    _select(_tools.indexOf(tool));
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A group of tools under a title.
class _Section {
  const _Section(this.title, this.tools);

  final String title;
  final List<_Tool> tools;
}

/// One tool, rendered as a bottom-bar, rail, side-panel or sheet entry.
class _Tool {
  const _Tool({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
