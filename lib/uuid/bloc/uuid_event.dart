part of 'uuid_bloc.dart';

/// Events accepted by [UuidBloc].
sealed class UuidEvent {
  const UuidEvent();
}

/// Requests a new UUID to be generated.
class UuidRequested extends UuidEvent {
  const UuidRequested();
}

/// Clears the currently displayed UUID, returning to the empty state.
class UuidCleared extends UuidEvent {
  const UuidCleared();
}
