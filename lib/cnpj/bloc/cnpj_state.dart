part of 'cnpj_bloc.dart';

/// State of the CNPJ generator: the options and the CNPJs they made.
///
/// Like `CpfState`, a single class carries the options; the empty state is
/// [cnpjs] being empty.
class CnpjState {
  const CnpjState({
    this.count = 1,
    this.kind = CnpjKind.numeric,
    this.headOffice = true,
    this.masked = true,
    this.cnpjs = const [],
    this.export = ExportStatus.idle,
    this.savedTo,
  });

  /// How many CNPJs each generation makes.
  final int count;

  /// Numeric or alphanumeric.
  final CnpjKind kind;

  /// Whether the CNPJs are head offices (`0001`) rather than branches.
  final bool headOffice;

  /// Whether the CNPJs are shown (and copied, and exported) with punctuation.
  final bool masked;

  /// The CNPJs on screen; empty before the first generation / after clearing.
  final List<CnpjModel> cnpjs;

  /// Where the last export stands. It survives regenerations, so a second
  /// export cannot start while the save dialog is still open.
  final ExportStatus export;

  /// Where the last export was saved, once it is [ExportStatus.saved].
  final Uri? savedTo;

  /// Whether there are CNPJs to copy, export or clear.
  bool get hasValues => cnpjs.isNotEmpty;

  /// The CNPJs as shown, honoring [masked].
  List<String> get values => [
    for (final cnpj in cnpjs) masked ? cnpj.formatted : cnpj.raw,
  ];

  /// Whether the list can be exported now.
  bool get canExport => hasValues && export != ExportStatus.saving;

  CnpjState copyWith({
    int? count,
    CnpjKind? kind,
    bool? headOffice,
    bool? masked,
    List<CnpjModel>? cnpjs,
  }) {
    return CnpjState(
      count: count ?? this.count,
      kind: kind ?? this.kind,
      headOffice: headOffice ?? this.headOffice,
      masked: masked ?? this.masked,
      cnpjs: cnpjs ?? this.cnpjs,
      export: export,
      savedTo: savedTo,
    );
  }

  /// This state with the export at [status] (and saved to [savedTo]).
  CnpjState withExport(ExportStatus status, {Uri? savedTo}) => CnpjState(
    count: count,
    kind: kind,
    headOffice: headOffice,
    masked: masked,
    cnpjs: cnpjs,
    export: status,
    savedTo: savedTo,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CnpjState &&
          other.count == count &&
          other.kind == kind &&
          other.headOffice == headOffice &&
          other.masked == masked &&
          listEquals(other.cnpjs, cnpjs) &&
          other.export == export &&
          other.savedTo == savedTo);

  @override
  int get hashCode => Object.hash(
    count,
    kind,
    headOffice,
    masked,
    Object.hashAll(cnpjs),
    export,
    savedTo,
  );

  @override
  String toString() =>
      'CnpjState($count, ${kind.name}, headOffice: $headOffice, '
      'masked: $masked, cnpjs: $cnpjs, export: ${export.name})';
}
