import 'package:flutter_test/flutter_test.dart';
import 'package:fake_generator/shared/data/export_format.dart';
import 'package:fake_generator/shared/data/list_export_repository.dart';

import 'fake_save_dialog.dart';

void main() {
  const values = ['111.444.777-35', '123.456.789-09'];

  group('ExportFormat.encode', () {
    test('CSV has a header and one value per row', () {
      expect(
        ExportFormat.csv.encode('cpf', values),
        'cpf\n111.444.777-35\n123.456.789-09\n',
      );
    });

    test('CSV quotes values with separators or quotes', () {
      expect(
        ExportFormat.csv.encode('nome', ['a,b', 'diz "oi"']),
        'nome\n"a,b"\n"diz ""oi"""\n',
      );
    });

    test('JSON is an indented array of strings', () {
      expect(
        ExportFormat.json.encode('cpf', values),
        '[\n  "111.444.777-35",\n  "123.456.789-09"\n]\n',
      );
    });

    test('TXT has one value per line and no header', () {
      expect(
        ExportFormat.txt.encode('cpf', values),
        '111.444.777-35\n123.456.789-09\n',
      );
    });
  });

  group('ListExportRepository', () {
    test('names the file after the list and the format', () async {
      final dialog = FakeSaveDialog(Uri.file('/tmp/cpfs.txt'));
      final repository = ListExportRepository(saveFile: dialog.call);

      final savedTo = await repository.save(
        fileName: 'cpfs',
        column: 'cpf',
        values: values,
        format: ExportFormat.txt,
      );

      expect(savedTo, Uri.file('/tmp/cpfs.txt'));
      expect(dialog.saved.single.fileName, 'cpfs.txt');
      expect(dialog.saved.single.mimeType, 'text/plain');
      expect(dialog.saved.single.text, '111.444.777-35\n123.456.789-09\n');
    });

    test('resolves to null when the dialog is cancelled', () async {
      final repository = ListExportRepository(saveFile: FakeSaveDialog().call);

      expect(
        await repository.save(
          fileName: 'cnpjs',
          column: 'cnpj',
          values: values,
          format: ExportFormat.csv,
        ),
        isNull,
      );
    });
  });
}
