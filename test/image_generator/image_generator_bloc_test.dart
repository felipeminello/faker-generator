import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/image_generator/bloc/image_generator_bloc.dart';
import 'package:fake_generator/image_generator/data/generated_image_model.dart';
import 'package:fake_generator/image_generator/data/image_download_repository.dart';
import 'package:fake_generator/image_generator/data/image_generator_repository.dart';
import 'package:fake_generator/image_generator/data/image_size.dart';
import 'package:fake_generator/shared/data/list_export_repository.dart';

import '../shared/png_decoder.dart';

/// The real renderer, with a "random" seed the tests know in advance.
class _FakeImageGeneratorRepository extends ImageGeneratorRepository {
  @override
  GeneratedImageModel generate(int width, int height) =>
      GeneratedImageModel(width: width, height: height, seed: 123);
}

/// A save dialog the test answers: [saves] holds what was asked to be saved,
/// and each save completes with what [answer] returns.
class _FakeSaveDialog {
  final saves = <({String fileName, Uint8List bytes, String mimeType})>[];
  Future<Uri?> Function() answer = () async => Uri.file('/tmp/imagem.png');

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
  group('ImageGeneratorBloc', () {
    final repository = _FakeImageGeneratorRepository();
    late _FakeSaveDialog dialog;

    setUp(() => dialog = _FakeSaveDialog());

    // The default renderer: the PNG is drawn in another isolate.
    ImageGeneratorBloc build() => ImageGeneratorBloc(
      repository,
      ImageDownloadRepository(saveFile: dialog.call),
    );

    ImageGeneratorState withImage(int width, int height) => ImageGeneratorState(
      width: width,
      height: height,
      image: GeneratedImageModel(width: width, height: height, seed: 123),
    );

    test('starts empty, at 1024×768', () {
      final bloc = build();

      expect(bloc.state, const ImageGeneratorState());
      expect([bloc.state.width, bloc.state.height], [1024, 768]);
      expect(bloc.state.hasImage, isFalse);
      expect(bloc.state.canDownload, isFalse);
    });

    blocTest<ImageGeneratorBloc, ImageGeneratorState>(
      'generates an image at the chosen size, with its preview',
      build: build,
      act: (bloc) => bloc.add(const ImageRequested()),
      expect: () => [withImage(1024, 768)],
      verify: (bloc) {
        final preview = decodePng(bloc.state.preview!);
        expect([preview.width, preview.height], [480, 360]);
      },
    );

    blocTest<ImageGeneratorBloc, ImageGeneratorState>(
      'resizing keeps the picture and redraws the preview',
      build: build,
      seed: () => withImage(1024, 768),
      act: (bloc) => bloc
        ..add(const ImageWidthChanged(300))
        ..add(const ImageHeightChanged(600)),
      expect: () => [withImage(300, 768), withImage(300, 600)],
      verify: (bloc) {
        final preview = decodePng(bloc.state.preview!);
        expect([preview.width, preview.height], [240, 480]);
      },
    );

    blocTest<ImageGeneratorBloc, ImageGeneratorState>(
      'only changes the size when there is no image',
      build: build,
      act: (bloc) => bloc.add(const ImageSizeSelected(1920, 1080)),
      expect: () => const [ImageGeneratorState(width: 1920, height: 1080)],
      verify: (bloc) => expect(bloc.state.preview, isNull),
    );

    blocTest<ImageGeneratorBloc, ImageGeneratorState>(
      'clamps the size to 1..4096',
      build: build,
      act: (bloc) => bloc
        ..add(const ImageWidthChanged(0))
        ..add(const ImageHeightChanged(99999)),
      expect: () => const [
        ImageGeneratorState(width: ImageSize.min, height: 768),
        ImageGeneratorState(width: ImageSize.min, height: ImageSize.max),
      ],
    );

    blocTest<ImageGeneratorBloc, ImageGeneratorState>(
      'ignores a change that does not change the size',
      build: build,
      act: (bloc) => bloc
        ..add(const ImageWidthChanged(1024))
        ..add(const ImageSizeSelected(1024, 768)),
      expect: () => const <ImageGeneratorState>[],
    );

    blocTest<ImageGeneratorBloc, ImageGeneratorState>(
      'clearing drops the image, keeping the size',
      build: build,
      seed: () => withImage(640, 480),
      act: (bloc) => bloc.add(const ImageCleared()),
      expect: () => const [ImageGeneratorState(width: 640, height: 480)],
    );

    group('download', () {
      blocTest<ImageGeneratorBloc, ImageGeneratorState>(
        'saves the image as a PNG at its full size',
        build: build,
        seed: () => withImage(64, 48),
        act: (bloc) => bloc.add(const ImageDownloadRequested()),
        wait: const Duration(milliseconds: 500),
        expect: () => [
          withImage(64, 48).withDownload(ExportStatus.saving),
          withImage(64, 48).withDownload(
            ExportStatus.saved,
            savedTo: Uri.file('/tmp/imagem.png'),
          ),
        ],
        verify: (_) {
          final save = dialog.saves.single;
          expect(save.fileName, 'imagem-64x48.png');
          expect(save.mimeType, 'image/png');
          final png = decodePng(save.bytes);
          expect([png.width, png.height, png.channels], [64, 48, 3]);
        },
      );

      blocTest<ImageGeneratorBloc, ImageGeneratorState>(
        'a closed dialog is a cancelled download',
        build: build,
        setUp: () => dialog.answer = () async => null,
        seed: () => withImage(8, 8),
        act: (bloc) => bloc.add(const ImageDownloadRequested()),
        wait: const Duration(milliseconds: 500),
        skip: 1,
        expect: () => [withImage(8, 8).withDownload(ExportStatus.cancelled)],
      );

      blocTest<ImageGeneratorBloc, ImageGeneratorState>(
        'a write error is a failed download',
        build: build,
        setUp: () =>
            dialog.answer = () async => throw const FileSystemException(),
        seed: () => withImage(8, 8),
        act: (bloc) => bloc.add(const ImageDownloadRequested()),
        wait: const Duration(milliseconds: 500),
        skip: 1,
        expect: () => [withImage(8, 8).withDownload(ExportStatus.failed)],
      );

      blocTest<ImageGeneratorBloc, ImageGeneratorState>(
        'there is nothing to save without an image',
        build: build,
        act: (bloc) => bloc.add(const ImageDownloadRequested()),
        expect: () => const <ImageGeneratorState>[],
        verify: (_) => expect(dialog.saves, isEmpty),
      );

      blocTest<ImageGeneratorBloc, ImageGeneratorState>(
        'opens a single dialog however often the button is pressed',
        build: build,
        setUp: () {
          final pending = Completer<Uri?>();
          dialog.answer = () => pending.future;
        },
        seed: () => withImage(8, 8),
        act: (bloc) => bloc
          ..add(const ImageDownloadRequested())
          ..add(const ImageDownloadRequested()),
        wait: const Duration(milliseconds: 500),
        verify: (bloc) {
          expect(dialog.saves, hasLength(1));
          expect(bloc.state.canDownload, isFalse);
        },
      );

      blocTest<ImageGeneratorBloc, ImageGeneratorState>(
        'saves the size asked for, even if it changes meanwhile',
        build: build,
        seed: () => withImage(16, 16),
        act: (bloc) => bloc
          ..add(const ImageDownloadRequested())
          ..add(const ImageWidthChanged(32)),
        wait: const Duration(milliseconds: 500),
        verify: (bloc) {
          expect(dialog.saves.single.fileName, 'imagem-16x16.png');
          expect(bloc.state.width, 32);
          expect(bloc.state.download, ExportStatus.saved);
        },
      );
    });
  });
}
