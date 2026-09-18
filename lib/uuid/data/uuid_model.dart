/// Immutable representation of a generated UUID.
class UuidModel {
  const UuidModel(this.value);

  /// The canonical 36-character UUID string (8-4-4-4-12, lowercase).
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UuidModel && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'UuidModel($value)';
}
