part of 'cpf_bloc.dart';

/// Events accepted by [CpfBloc].
sealed class CpfEvent {
  const CpfEvent();
}

/// The user typed another amount. Values outside 1 to
/// [CpfRepository.maxCount] are clamped.
class CpfCountChanged extends CpfEvent {
  const CpfCountChanged(this.count);

  final int count;
}

/// The user picked the unit of the federation the CPFs should come from, or
/// `null` for any.
class CpfUfChanged extends CpfEvent {
  const CpfUfChanged(this.uf);

  final Uf? uf;
}

/// The user toggled the punctuation (`123.456.789-09` or `12345678909`).
class CpfMaskToggled extends CpfEvent {
  const CpfMaskToggled(this.masked);

  final bool masked;
}

/// Requests new CPFs using the current options.
class CpfRequested extends CpfEvent {
  const CpfRequested();
}

/// Clears the CPFs on screen, keeping the options.
class CpfCleared extends CpfEvent {
  const CpfCleared();
}

/// Saves the CPFs on screen as a file in [format], asking the user where.
class CpfExportRequested extends CpfEvent {
  const CpfExportRequested(this.format);

  final ExportFormat format;
}
