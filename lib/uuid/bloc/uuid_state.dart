part of 'uuid_bloc.dart';

/// States emitted by [UuidBloc].
sealed class UuidState {
  const UuidState();
}

/// No UUID has been generated yet (or it was cleared).
class UuidInitial extends UuidState {
  const UuidInitial();
}

/// A UUID has been generated and is ready to display.
class UuidGenerated extends UuidState {
  const UuidGenerated(this.uuid);

  final UuidModel uuid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UuidGenerated && other.uuid == uuid);

  @override
  int get hashCode => uuid.hashCode;
}
