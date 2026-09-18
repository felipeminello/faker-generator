part of 'cnpj_bloc.dart';

/// Events accepted by [CnpjBloc].
sealed class CnpjEvent {
  const CnpjEvent();
}

/// Requests a new CNPJ to be generated.
class CnpjRequested extends CnpjEvent {
  const CnpjRequested();
}

/// Clears the currently displayed CNPJ, returning to the empty state.
class CnpjCleared extends CnpjEvent {
  const CnpjCleared();
}
