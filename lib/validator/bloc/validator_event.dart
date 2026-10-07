part of 'validator_bloc.dart';

/// Events accepted by [ValidatorBloc].
sealed class ValidatorEvent {
  const ValidatorEvent();
}

/// The text with the values to check was edited (typed or pasted).
class ValidatorTextChanged extends ValidatorEvent {
  const ValidatorTextChanged(this.text);

  final String text;
}

/// Fills in [ValidatorRepository.example], one value for each verdict.
class ValidatorExampleRequested extends ValidatorEvent {
  const ValidatorExampleRequested();
}

/// Clears the text and the results.
class ValidatorCleared extends ValidatorEvent {
  const ValidatorCleared();
}
