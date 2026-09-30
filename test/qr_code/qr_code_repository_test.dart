import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/qr_code/data/qr_code_level.dart';
import 'package:fake_generator/qr_code/data/qr_code_model.dart';
import 'package:fake_generator/qr_code/data/qr_code_repository.dart';

void main() {
  group('QrCodeRepository.encode', () {
    final repository = QrCodeRepository();

    test('uses the smallest version the text fits in', () {
      final qrCode = repository.encode('HELLO WORLD', QrCodeLevel.medium);

      expect(qrCode.version, 1);
      expect(qrCode.size, 21);
      expect(qrCode.modules, hasLength(21 * 21));
      expect(qrCode.text, 'HELLO WORLD');
      expect(qrCode.level, QrCodeLevel.medium);
    });

    test('draws the three finder patterns in the corners', () {
      final qrCode = repository.encode(
        'https://exemplo.com.br',
        QrCodeLevel.low,
      );
      final last = qrCode.size - 1;

      for (final (row, column) in [(0, 0), (0, last - 6), (last - 6, 0)]) {
        // Outer ring dark, inner ring light, 3×3 dark centre.
        expect(qrCode.isDark(row, column), isTrue);
        expect(qrCode.isDark(row + 6, column + 6), isTrue);
        expect(qrCode.isDark(row + 1, column + 1), isFalse);
        expect(qrCode.isDark(row + 3, column + 3), isTrue);
      }
      // The corner without a finder pattern.
      expect(qrCode.isDark(last - 3, last - 3), isFalse);
    });

    test('a higher level makes a bigger code for the same text', () {
      const text = 'https://exemplo.com.br/uma-pagina-com-um-caminho-longo';

      final low = repository.encode(text, QrCodeLevel.low);
      final high = repository.encode(text, QrCodeLevel.high);

      expect(high.version, greaterThan(low.version));
    });

    test('encodes accented text', () {
      final ascii = repository.encode('Promocao', QrCodeLevel.medium);
      final accented = repository.encode('Promoção', QrCodeLevel.medium);

      expect(accented.byteCount, 10);
      expect(accented.modules, isNot(ascii.modules));
    });

    test('fits up to the byte limit of the level, and no more', () {
      for (final level in QrCodeLevel.values) {
        final fits = repository.encode('a' * level.maxBytes, level);
        expect(fits.version, 40, reason: level.label);

        expect(
          () => repository.encode('a' * (level.maxBytes + 1), level),
          throwsA(QrCodeTooLongException(level)),
          reason: level.label,
        );
      }
    });

    test('explains the limit when the text does not fit', () {
      expect(
        const QrCodeTooLongException(QrCodeLevel.low).message,
        'Texto longo demais para um QR Code (até 2.953 bytes no nível L).',
      );
      expect(
        const QrCodeTooLongException(QrCodeLevel.high).message,
        startsWith(
          'Texto longo demais para um QR Code (até 1.273 bytes no '
          'nível H). Encurte',
        ),
      );
    });
  });

  group('QrCodeRepository.random', () {
    test('makes up the usual kinds of QR Code contents', () {
      final repository = QrCodeRepository(random: Random(1));
      final samples = [for (var i = 0; i < 200; i++) repository.random()];

      expect(samples, contains(startsWith('https://exemplo.com.br/')));
      expect(
        samples,
        contains(matches(r'^WIFI:T:WPA;S:Rede-\d{4};P:\w{12};;$')),
      );
      expect(
        samples,
        contains(matches(r'^mailto:usuario\d{3}@exemplo\.com\.br$')),
      );
      expect(samples, contains(matches(r'^tel:\+55119\d{8}$')));
      expect(samples, contains(startsWith('Pedido nº ')));
    });

    test('every sample fits even at the highest level', () {
      final repository = QrCodeRepository(random: Random(2));

      for (var i = 0; i < 50; i++) {
        final text = repository.random();
        expect(repository.encode(text, QrCodeLevel.high).text, text);
      }
    });
  });
}
