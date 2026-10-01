import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/qr_code/bloc/qr_code_bloc.dart';
import 'package:fake_generator/qr_code/data/qr_code_download_repository.dart';
import 'package:fake_generator/qr_code/data/qr_code_level.dart';
import 'package:fake_generator/qr_code/data/qr_code_model.dart';
import 'package:fake_generator/qr_code/data/qr_code_repository.dart';

/// The real encoder, with a "random" content the tests know in advance.
class _FakeQrCodeRepository extends QrCodeRepository {
  @override
  String random() => 'https://exemplo.com.br/abc';
}

/// A save dialog the test answers: [saves] holds what was asked to be saved,
/// and each save completes with what [answer] returns.
class _FakeSaveDialog {
  final saves = <({String fileName, Uint8List bytes, String mimeType})>[];
  Future<Uri?> Function() answer = () async => Uri.file('/tmp/qrcode.png');

  Future<Uri?> call({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) {
    saves.add((fileName: fileName, bytes: bytes, mimeType: mimeType));
    return answer();
  }
}

void main() {
  group('QrCodeBloc', () {
    final repository = _FakeQrCodeRepository();
    late _FakeSaveDialog dialog;

    setUp(() => dialog = _FakeSaveDialog());

    QrCodeBloc build() =>
        QrCodeBloc(repository, QrCodeDownloadRepository(saveFile: dialog.call));

    QrCodeState withCode(String text) => QrCodeState(
      text: text,
      qrCode: repository.encode(text, QrCodeLevel.medium),
    );

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

    group('download', () {
      blocTest<QrCodeBloc, QrCodeState>(
        'saves the code as a 512×512 PNG named qrcode.png',
        build: build,
        seed: () => withCode('abc'),
        act: (bloc) => bloc.add(const QrCodeDownloadRequested()),
        expect: () => [
          withCode('abc').withDownload(QrCodeDownloadStatus.saving),
          withCode('abc').withDownload(
            QrCodeDownloadStatus.saved,
            savedTo: Uri.file('/tmp/qrcode.png'),
          ),
        ],
        verify: (_) {
          final save = dialog.saves.single;
          expect(save.fileName, 'qrcode.png');
          expect(save.mimeType, 'image/png');
          // Width and height in the IHDR chunk.
          final header = ByteData.sublistView(save.bytes);
          expect([header.getUint32(16), header.getUint32(20)], [512, 512]);
        },
      );

      blocTest<QrCodeBloc, QrCodeState>(
        'a closed dialog is a cancelled download',
        build: build,
        setUp: () => dialog.answer = () async => null,
        seed: () => withCode('abc'),
        act: (bloc) => bloc.add(const QrCodeDownloadRequested()),
        skip: 1,
        expect: () => [
          withCode('abc').withDownload(QrCodeDownloadStatus.cancelled),
        ],
      );

      blocTest<QrCodeBloc, QrCodeState>(
        'a write error is a failed download',
        build: build,
        setUp: () =>
            dialog.answer = () async => throw const FileSystemException(),
        seed: () => withCode('abc'),
        act: (bloc) => bloc.add(const QrCodeDownloadRequested()),
        skip: 1,
        expect: () => [
          withCode('abc').withDownload(QrCodeDownloadStatus.failed),
        ],
      );

      blocTest<QrCodeBloc, QrCodeState>(
        'there is nothing to save without a code',
        build: build,
        seed: () => QrCodeState(
          text: 'a' * 3000,
          error: const QrCodeTooLongException(QrCodeLevel.medium),
        ),
        act: (bloc) => bloc.add(const QrCodeDownloadRequested()),
        expect: () => const <QrCodeState>[],
        verify: (_) => expect(dialog.saves, isEmpty),
      );

      blocTest<QrCodeBloc, QrCodeState>(
        'opens a single dialog however often the button is pressed',
        build: build,
        setUp: () {
          final pending = Completer<Uri?>();
          dialog.answer = () => pending.future;
        },
        seed: () => withCode('abc'),
        act: (bloc) => bloc
          ..add(const QrCodeDownloadRequested())
          ..add(const QrCodeDownloadRequested()),
        verify: (bloc) {
          expect(dialog.saves, hasLength(1));
          expect(bloc.state.canDownload, isFalse);
        },
      );

      blocTest<QrCodeBloc, QrCodeState>(
        'editing the text while saving keeps the download going',
        build: build,
        setUp: () {
          final pending = Completer<Uri?>();
          dialog.answer = () => pending.future;
        },
        seed: () => withCode('abc'),
        act: (bloc) => bloc
          ..add(const QrCodeDownloadRequested())
          ..add(const QrCodeTextChanged('abcd')),
        verify: (bloc) {
          expect(bloc.state.text, 'abcd');
          expect(bloc.state.download, QrCodeDownloadStatus.saving);
        },
      );
    });
  });
}
