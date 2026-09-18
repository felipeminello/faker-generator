part of 'cnpj_bloc.dart';

/// States emitted by [CnpjBloc].
sealed class CnpjState {
  const CnpjState();
}

/// No CNPJ has been generated yet (or it was cleared).
class CnpjInitial extends CnpjState {
  const CnpjInitial();
}

/// A CNPJ has been generated and is ready to display.
class CnpjGenerated extends CnpjState {
  const CnpjGenerated(this.cnpj);

  final CnpjModel cnpj;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CnpjGenerated && other.cnpj == cnpj);

  @override
  int get hashCode => cnpj.hashCode;
}
