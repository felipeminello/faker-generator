import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/qr_code/bloc/qr_code_bloc.dart';
import 'package:fake_generator/qr_code/data/qr_code_level.dart';
import 'package:fake_generator/qr_code/data/qr_code_model.dart';
import 'package:fake_generator/qr_code/data/qr_code_repository.dart';

/// The real encoder, with a "random" content the tests know in advance.
class _FakeQrCodeRepository extends QrCodeRepository {
  @override
  String random() => 'https://exemplo.com.br/abc';
}

void main() {
  group('QrCodeBloc', () {
    final repository = _FakeQrCodeRepository();

    QrCodeBloc build() => QrCodeBloc(repository);

    test('starts empty, at level M', () {
      final bloc = build();

      expect(bloc.state, const QrCodeState());
      expect(bloc.state.level, QrCodeLevel.medium);
      expect(bloc.state.hasText, isFalse);
    });

    blocTest<QrCodeBloc, QrCodeState>(
      'encodes the text as it is typed',
      build: build,
      act: (bloc) => bloc.add(const QrCodeTextChanged('olá')),
      expect: () => [
        QrCodeState(
          text: 'olá',
          qrCode: repository.encode('olá', QrCodeLevel.medium),
        ),
      ],
    );

    blocTest<QrCodeBloc, QrCodeState>(
      're-encodes the text at the new level',
      build: build,
      seed: () => QrCodeState(
        text: 'abc',
        qrCode: repository.encode('abc', QrCodeLevel.medium),
      ),
      act: (bloc) => bloc.add(const QrCodeLevelChanged(QrCodeLevel.high)),
      expect: () => [
        QrCodeState(
          text: 'abc',
          level: QrCodeLevel.high,
          qrCode: repository.encode('abc', QrCodeLevel.high),
        ),
      ],
    );

    blocTest<QrCodeBloc, QrCodeState>(
      'keeps the level when there is no text',
      build: build,
      act: (bloc) => bloc.add(const QrCodeLevelChanged(QrCodeLevel.low)),
      expect: () => const [QrCodeState(level: QrCodeLevel.low)],
    );

    blocTest<QrCodeBloc, QrCodeState>(
      'reports a text too long for the level instead of a code',
      build: build,
      act: (bloc) => bloc.add(QrCodeTextChanged('a' * 3000)),
      verify: (bloc) {
        expect(bloc.state.qrCode, isNull);
        expect(
          bloc.state.error,
          const QrCodeTooLongException(QrCodeLevel.medium),
        );
        expect(bloc.state.hasText, isTrue);
      },
    );

    blocTest<QrCodeBloc, QrCodeState>(
      'the error goes away once the text fits again',
      build: build,
      act: (bloc) => bloc
        ..add(QrCodeTextChanged('a' * 3000))
        ..add(QrCodeTextChanged('a' * 30)),
      verify: (bloc) {
        expect(bloc.state.error, isNull);
        expect(bloc.state.qrCode?.text, 'a' * 30);
      },
    );

    blocTest<QrCodeBloc, QrCodeState>(
      'ignores a change that does not change the text',
      build: build,
      seed: () => const QrCodeState(text: 'abc'),
      act: (bloc) => bloc.add(const QrCodeTextChanged('abc')),
      expect: () => const <QrCodeState>[],
    );

    blocTest<QrCodeBloc, QrCodeState>(
      'generates a sample content',
      build: build,
      act: (bloc) => bloc.add(const QrCodeRequested()),
      verify: (bloc) {
        expect(bloc.state.text, 'https://exemplo.com.br/abc');
        expect(bloc.state.qrCode?.text, 'https://exemplo.com.br/abc');
      },
    );

    blocTest<QrCodeBloc, QrCodeState>(
      'clearing drops the text and the code, keeping the level',
      build: build,
      seed: () => QrCodeState(
        text: 'abc',
        level: QrCodeLevel.quartile,
        qrCode: repository.encode('abc', QrCodeLevel.quartile),
      ),
      act: (bloc) => bloc.add(const QrCodeCleared()),
      expect: () => const [QrCodeState(level: QrCodeLevel.quartile)],
    );
  });
}
