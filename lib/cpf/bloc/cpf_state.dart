part of 'cpf_bloc.dart';

/// States emitted by [CpfBloc].
sealed class CpfState {
  const CpfState();
}

/// No CPF has been generated yet (or it was cleared).
class CpfInitial extends CpfState {
  const CpfInitial();
}

/// A CPF has been generated and is ready to display.
class CpfGenerated extends CpfState {
  const CpfGenerated(this.cpf);

  final CpfModel cpf;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CpfGenerated && other.cpf == cpf);

  @override
  int get hashCode => cpf.hashCode;
}
