part of 'models.dart';


class Transaction {
  Transaction(
    this.prevHash
  ) :
  id = const Uuid().v4();

  String id; // Идентификатор изменения
  int prevHash;
}


@HiveType(typeId: 6)
// ignore: must_be_immutable
class Registry extends Equatable {
  Registry({
    String? id,
    required this.parentId,
    List<Transaction>? transactions
  }) : 
  assert(id == null || id.isNotEmpty, 'id must be null or not empty'),
  id = id ?? const Uuid().v4();

  /// The unique identifier of the model.
  ///
  /// Cannot be empty.
  @HiveField(0)
  final String id;

  /// The identifier of container model (domain or user).
  ///
  /// Cannot be empty.
  @HiveField(1)
  final String parentId;

  @override
  List<Object> get props => [id, parentId];
}