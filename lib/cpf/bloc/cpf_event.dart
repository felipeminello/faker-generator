part of 'cpf_bloc.dart';

/// Events accepted by [CpfBloc].
sealed class CpfEvent {
  const CpfEvent();
}

/// Requests a new CPF to be generated.
class CpfRequested extends CpfEvent {
  const CpfRequested();
}

/// Clears the currently displayed CPF, returning to the empty state.
class CpfCleared extends CpfEvent {
  const CpfCleared();
}
