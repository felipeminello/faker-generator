part of 'lorem_bloc.dart';

/// Events accepted by [LoremBloc].
sealed class LoremEvent {
  const LoremEvent();
}

/// The user picked another [LoremUnit] (paragraphs, words, letters or lists).
class LoremUnitChanged extends LoremEvent {
  const LoremUnitChanged(this.unit);

  final LoremUnit unit;
}

/// The user typed another amount. Values outside the unit's range are clamped.
class LoremCountChanged extends LoremEvent {
  const LoremCountChanged(this.count);

  final int count;
}

/// The user toggled the classic "Lorem ipsum dolor sit amet..." opening.
class LoremOpeningToggled extends LoremEvent {
  const LoremOpeningToggled(this.startWithLorem);

  final bool startWithLorem;
}

/// Requests a new placeholder text using the current options.
class LoremRequested extends LoremEvent {
  const LoremRequested();
}

/// Clears the currently displayed text, keeping the options.
class LoremCleared extends LoremEvent {
  const LoremCleared();
}
