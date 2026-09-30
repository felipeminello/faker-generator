/// Portuguese words shared by the parser messages and the descriptions.
library;

/// Joins [words] the Portuguese way: "a", "a e b", "a, b e c" (or "a, b ou
/// c" with [last] set to "ou").
String joinWords(Iterable<String> words, {String last = 'e'}) {
  final list = words.toList();
  if (list.length < 2) return list.join();
  return '${list.sublist(0, list.length - 1).join(', ')} $last ${list.last}';
}

String twoDigits(int value) => value.toString().padLeft(2, '0');

/// Month names, January first.
const monthNames = <String>[
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// Day names, Sunday first (cron's 0).
const weekdayNames = <String>[
  'domingo',
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
];

/// [weekdayNames] in the plural, for recurring days ("às segundas-feiras").
const weekdayPlurals = <String>[
  'domingos',
  'segundas-feiras',
  'terças-feiras',
  'quartas-feiras',
  'quintas-feiras',
  'sextas-feiras',
  'sábados',
];
