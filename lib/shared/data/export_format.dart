import 'dart:convert';

/// File formats a generated list (of CPFs, CNPJs...) can be exported to.
enum ExportFormat {
  csv('CSV', 'para planilhas e importação', 'csv', 'text/csv'),
  json('JSON', 'para fixtures e mocks', 'json', 'application/json'),
  txt('TXT', 'um por linha', 'txt', 'text/plain');

  const ExportFormat(this.label, this.hint, this.extension, this.mimeType);

  /// Name shown in the export menu.
  final String label;

  /// What the format is good for, shown under [label].
  final String hint;

  /// File extension, without the dot.
  final String extension;

  final String mimeType;

  /// [values] as the contents of a file in this format. [column] heads the
  /// CSV's only column; the other formats have no header.
  String encode(String column, List<String> values) => switch (this) {
    csv => [column, ...values].map((value) => '${_csvField(value)}\n').join(),
    json => '${const JsonEncoder.withIndent('  ').convert(values)}\n',
    txt => values.map((value) => '$value\n').join(),
  };

  /// [value] quoted when it holds a separator, a quote or a line break.
  static String _csvField(String value) => value.contains(RegExp('[,"\r\n]'))
      ? '"${value.replaceAll('"', '""')}"'
      : value;
}
