/// Immutable representation of a generated password.
class PasswordModel {
  const PasswordModel({required this.value, required this.createdAt});

  /// Restores a password saved with [toJson].
  factory PasswordModel.fromJson(Map<String, Object?> json) => PasswordModel(
    value: json['value']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']! as int),
  );

  /// The password itself.
  final String value;

  /// When it was generated, shown in the recent passwords list.
  final DateTime createdAt;

  int get length => value.length;

  Map<String, Object?> toJson() => {
    'value': value,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PasswordModel &&
          other.value == value &&
          other.createdAt == createdAt);

  @override
  int get hashCode => Object.hash(value, createdAt);

  // The value is left out on purpose, so passwords do not end up in logs.
  @override
  String toString() => 'PasswordModel($length chars, $createdAt)';
}
