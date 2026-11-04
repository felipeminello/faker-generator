import 'package:flutter/material.dart';

/// Notice shown on the document generators (CPF, CNPJ) saying what the
/// numbers are for and what they are not.
///
/// It stays on screen, rather than in a one-time dialog, because App Review
/// rejected the app under guideline 5 (legal) for generating Brazilian
/// taxpayer numbers: whoever opens the page has to see that they are
/// fictitious test data that must not be used as someone's document.
class TestDataNotice extends StatelessWidget {
  const TestDataNotice({super.key});

  static const text =
      'Só para testar software. Os números são sorteados pelo algoritmo '
      'público dos dígitos verificadores: não são documentos, não saem de '
      'nenhum cadastro da Receita Federal e não devem ser usados para '
      'identificar você ou outra pessoa em cadastros reais. Usar documento '
      'de terceiros ou falso é crime.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.science_outlined,
              size: 20,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
