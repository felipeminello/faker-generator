import 'dart:math';

import 'lorem_model.dart';
import 'lorem_unit.dart';

/// Generates "Lorem Ipsum" placeholder text, in the spirit of lipsum.com.
///
/// Sentences are assembled from the classic Lorem Ipsum vocabulary; the amount
/// is interpreted according to the requested [LoremUnit].
class LoremRepository {
  LoremRepository({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// The canonical opening sentence, optionally used to start the text.
  static const openingSentence =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';

  /// [openingSentence] split into words, keeping its comma.
  static const _openingWords = <String>[
    'lorem',
    'ipsum',
    'dolor',
    'sit',
    'amet,',
    'consectetur',
    'adipiscing',
    'elit',
  ];

  /// Bullet used to render list items.
  static const _bullet = '•';

  static const _vocabulary = <String>[
    'lorem',
    'ipsum',
    'dolor',
    'sit',
    'amet',
    'consectetur',
    'adipiscing',
    'elit',
    'sed',
    'do',
    'eiusmod',
    'tempor',
    'incididunt',
    'ut',
    'labore',
    'et',
    'dolore',
    'magna',
    'aliqua',
    'enim',
    'ad',
    'minim',
    'veniam',
    'quis',
    'nostrud',
    'exercitation',
    'ullamco',
    'laboris',
    'nisi',
    'aliquip',
    'ex',
    'ea',
    'commodo',
    'consequat',
    'duis',
    'aute',
    'irure',
    'in',
    'reprehenderit',
    'voluptate',
    'velit',
    'esse',
    'cillum',
    'eu',
    'fugiat',
    'nulla',
    'pariatur',
    'excepteur',
    'sint',
    'occaecat',
    'cupidatat',
    'non',
    'proident',
    'sunt',
    'culpa',
    'qui',
    'officia',
    'deserunt',
    'mollit',
    'anim',
    'id',
    'est',
    'laborum',
    'at',
    'vero',
    'eos',
    'accusamus',
    'iusto',
    'odio',
    'dignissimos',
    'ducimus',
    'blanditiis',
    'praesentium',
    'voluptatum',
    'deleniti',
    'atque',
    'corrupti',
    'quos',
    'dolores',
    'quas',
    'molestias',
    'excepturi',
    'occaecati',
    'cupiditate',
    'similique',
    'mollitia',
    'animi',
    'dolorem',
    'quia',
    'voluptas',
    'aspernatur',
    'aut',
    'odit',
    'fugit',
    'magni',
    'ratione',
    'sequi',
    'nesciunt',
    'neque',
    'porro',
    'quisquam',
    'numquam',
    'eius',
    'modi',
    'tempora',
    'incidunt',
    'magnam',
    'quaerat',
    'nostrum',
    'exercitationem',
    'corporis',
    'suscipit',
    'laboriosam',
    'aliquid',
    'commodi',
    'consequatur',
    'autem',
    'vel',
    'eum',
    'iure',
    'quam',
    'nihil',
    'molestiae',
    'illum',
    'quo',
    'perferendis',
    'doloribus',
    'asperiores',
    'repellat',
    'maiores',
    'alias',
    'perspiciatis',
    'unde',
    'omnis',
    'iste',
    'natus',
    'error',
    'accusantium',
    'doloremque',
    'laudantium',
    'totam',
    'rem',
    'aperiam',
    'eaque',
    'quae',
    'ab',
    'illo',
    'inventore',
    'veritatis',
    'quasi',
    'architecto',
    'beatae',
    'vitae',
    'dicta',
    'explicabo',
    'nemo',
    'ipsam',
    'sapiente',
    'delectus',
    'reiciendis',
    'voluptatibus',
    'facilis',
    'expedita',
    'distinctio',
    'nam',
    'libero',
    'cumque',
    'impedit',
    'minus',
    'quod',
    'maxime',
    'placeat',
    'facere',
    'possimus',
    'assumenda',
    'repellendus',
    'temporibus',
    'quibusdam',
    'officiis',
    'debitis',
    'rerum',
    'necessitatibus',
    'saepe',
    'eveniet',
    'voluptates',
    'repudiandae',
    'recusandae',
    'itaque',
    'earum',
    'hic',
    'tenetur',
    'harum',
    'optio',
    'consequuntur',
    'provident',
    'tempore',
  ];

  /// Generates placeholder text for [count] units of [unit].
  ///
  /// When [startWithLorem] is true the text opens with [openingSentence] (or
  /// its words, for the word and letter units), the way lipsum.com does.
  LoremModel generate({
    required LoremUnit unit,
    required int count,
    bool startWithLorem = true,
  }) {
    final amount = unit.clampCount(count);

    final text = switch (unit) {
      LoremUnit.paragraphs => _paragraphs(amount, startWithLorem),
      LoremUnit.words => _words(amount, startWithLorem),
      LoremUnit.letters => _letters(amount, startWithLorem),
      LoremUnit.lists => _lists(amount, startWithLorem),
    };

    return LoremModel(text: text, unit: unit, count: amount);
  }

  /// [count] paragraphs of 3 to 6 sentences, separated by a blank line.
  String _paragraphs(int count, bool startWithLorem) {
    final paragraphs = <String>[];

    for (var i = 0; i < count; i++) {
      final sentences = List.generate(_between(3, 6), (_) => _sentence());
      if (i == 0 && startWithLorem) {
        sentences[0] = openingSentence;
      }
      paragraphs.add(sentences.join(' '));
    }

    return paragraphs.join('\n\n');
  }

  /// Exactly [count] words, rendered as a single sentence.
  String _words(int count, bool startWithLorem) {
    final words = <String>[if (startWithLorem) ..._openingWords];
    while (words.length < count) {
      words.add(_randomWord());
    }

    final selected = words.take(count).toList();
    final sentence = [
      _capitalize(selected.first),
      ...selected.skip(1),
    ].join(' ');

    // A word may carry the opening comma; drop it when it lands at the end.
    return '${sentence.replaceFirst(RegExp(r',$'), '')}.';
  }

  /// Exactly [count] characters, cut from a stream of sentences.
  String _letters(int count, bool startWithLorem) {
    final buffer = StringBuffer(startWithLorem ? openingSentence : '');
    while (buffer.length < count) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(_sentence());
    }

    final text = buffer.toString().substring(0, count);

    // Never end on a dangling space: spend that last character on a period.
    return text.endsWith(' ') ? '${text.substring(0, count - 1)}.' : text;
  }

  /// [count] bulleted list items, one per line.
  String _lists(int count, bool startWithLorem) {
    final items = <String>[];

    for (var i = 0; i < count; i++) {
      final words = _randomWords(_between(3, 8));
      final item = (i == 0 && startWithLorem)
          ? 'Lorem ipsum dolor sit amet'
          : [_capitalize(words.first), ...words.skip(1)].join(' ');
      items.add('$_bullet $item');
    }

    return items.join('\n');
  }

  /// A capitalized sentence of 6 to 14 words, sometimes with a comma.
  String _sentence() {
    final words = _randomWords(_between(6, 14));

    if (words.length > 8 && _random.nextBool()) {
      final comma = _between(3, words.length - 3);
      words[comma] = '${words[comma]},';
    }

    return '${[_capitalize(words.first), ...words.skip(1)].join(' ')}.';
  }

  List<String> _randomWords(int count) =>
      List<String>.generate(count, (_) => _randomWord());

  String _randomWord() => _vocabulary[_random.nextInt(_vocabulary.length)];

  /// A random integer in `[min, max]`.
  int _between(int min, int max) => min + _random.nextInt(max - min + 1);

  String _capitalize(String word) => word[0].toUpperCase() + word.substring(1);
}
