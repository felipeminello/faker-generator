import 'package:flutter/material.dart';

import 'feature_header.dart';
import 'generator_actions.dart';
import 'responsive.dart';
import 'value_list_card.dart';

/// Reusable presentation widget for a generator that makes one value at a
/// time (UUID); `ListGeneratorView` is its counterpart for lists.
///
/// It is intentionally free of business logic: pages wire a Bloc to it by
/// passing the current [value] plus the [onGenerate]/[onClear] callbacks.
class GeneratorView extends StatelessWidget {
  const GeneratorView({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.onGenerate,
    required this.onClear,
    this.generateLabel = 'Gerar',
  });

  /// Feature title shown above the result.
  final String title;

  /// Short explanation of what the feature generates.
  final String description;

  /// Icon representing the feature.
  final IconData icon;

  /// The currently generated value, or `null` when nothing has been generated.
  final String? value;

  /// Called when the user asks for a new value.
  final VoidCallback onGenerate;

  /// Called when the user clears the current value.
  final VoidCallback onClear;

  /// Label for the generate button.
  final String generateLabel;

  @override
  Widget build(BuildContext context) {
    final value = this.value;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FeatureHeader(icon: icon, title: title, description: description),
              const SizedBox(height: 24),
              ValueListCard(values: [?value]),
              const SizedBox(height: 24),
              GeneratorActions(
                value: value,
                onGenerate: onGenerate,
                onClear: onClear,
                generateLabel: generateLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
