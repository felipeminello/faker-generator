part of 'cpf_bloc.dart';

/// State of the CPF generator: the options and the CPFs they made.
///
/// Like `LoremState`, a single class carries the options; the empty state is
/// [cpfs] being empty.
class CpfState {
  const CpfState({
    this.count = 1,
    this.uf,
    this.masked = true,
    this.cpfs = const [],
    this.export = ExportStatus.idle,
    this.savedTo,
  });

  /// How many CPFs each generation makes.
  final int count;

  /// Unit of the federation whose fiscal region the CPFs carry, or `null` for
  /// any.
  final Uf? uf;

  /// Whether the CPFs are shown (and copied, and exported) with punctuation.
  final bool masked;

  /// The CPFs on screen; empty before the first generation / after clearing.
  final List<CpfModel> cpfs;

  /// Where the last export stands. It survives regenerations, so a second
  /// export cannot start while the save dialog is still open.
  final ExportStatus export;

  /// Where the last export was saved, once it is [ExportStatus.saved].
  final Uri? savedTo;

  /// Whether there are CPFs to copy, export or clear.
  bool get hasValues => cpfs.isNotEmpty;

  /// The CPFs as shown, honoring [masked].
  List<String> get values => [
    for (final cpf in cpfs) masked ? cpf.formatted : cpf.digits,
  ];

  /// Whether the list can be exported now.
  bool get canExport => hasValues && export != ExportStatus.saving;

  CpfState copyWith({
    int? count,
    Uf? uf,
    bool anyUf = false,
    bool? masked,
    List<CpfModel>? cpfs,
  }) {
    return CpfState(
      count: count ?? this.count,
      uf: anyUf ? null : (uf ?? this.uf),
      masked: masked ?? this.masked,
      cpfs: cpfs ?? this.cpfs,
      export: export,
      savedTo: savedTo,
    );
  }

  /// This state with the export at [status] (and saved to [savedTo]).
  CpfState withExport(ExportStatus status, {Uri? savedTo}) => CpfState(
    count: count,
    uf: uf,
    masked: masked,
    cpfs: cpfs,
    export: status,
    savedTo: savedTo,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CpfState &&
          other.count == count &&
          other.uf == uf &&
          other.masked == masked &&
          listEquals(other.cpfs, cpfs) &&
          other.export == export &&
          other.savedTo == savedTo);

  @override
  int get hashCode =>
      Object.hash(count, uf, masked, Object.hashAll(cpfs), export, savedTo);

  @override
  String toString() =>
      'CpfState($count, uf: ${uf?.code}, masked: $masked, cpfs: $cpfs, '
      'export: ${export.name})';
}
