part of 'cnpj_bloc.dart';

/// Events accepted by [CnpjBloc].
sealed class CnpjEvent {
  const CnpjEvent();
}

/// The user typed another amount. Values outside 1 to
/// [CnpjRepository.maxCount] are clamped.
class CnpjCountChanged extends CnpjEvent {
  const CnpjCountChanged(this.count);

  final int count;
}

/// The user picked the numeric or the alphanumeric format.
class CnpjKindChanged extends CnpjEvent {
  const CnpjKindChanged(this.kind);

  final CnpjKind kind;
}

/// The user chose between head office (`0001`) and random branch numbers.
class CnpjHeadOfficeToggled extends CnpjEvent {
  const CnpjHeadOfficeToggled(this.headOffice);

  final bool headOffice;
}

/// The user toggled the punctuation (`11.222.333/0001-81` or
/// `11222333000181`).
class CnpjMaskToggled extends CnpjEvent {
  const CnpjMaskToggled(this.masked);

  final bool masked;
}

/// Requests new CNPJs using the current options.
class CnpjRequested extends CnpjEvent {
  const CnpjRequested();
}

/// Clears the CNPJs on screen, keeping the options.
class CnpjCleared extends CnpjEvent {
  const CnpjCleared();
}

/// Saves the CNPJs on screen as a file in [format], asking the user where.
class CnpjExportRequested extends CnpjEvent {
  const CnpjExportRequested(this.format);

  final ExportFormat format;
}
