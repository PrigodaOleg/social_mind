part of 'models.dart';

// ignore: must_be_immutable
class Contact extends Model {
  Contact({
    super.title,
    super.id,
    required this.userId,
    this.name = '',
  });

  Contact.fromJson(super.json)
      : userId = (json['userId'] ?? '') as String,
        name = (json['name'] ?? '') as String,
        super.fromJson();

  @override
  // ignore: overridden_fields
  final String type = "Contact";

  /// ID of the [User] (a person who uses the same app) this contact refers to.
  final String userId;

  /// Display name of this contact as given by the owner of the contact list.
  String name;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "userId": userId,
      "name": name,
    });

  Contact copyWith({
    String? id,
    String? title,
    String? userId,
    String? name,
  }) {
    return Contact(
      id: id ?? this.id,
      title: title ?? this.title,
      userId: userId ?? this.userId,
      name: name ?? this.name,
    );
  }

  @override
  List<Object> get props => super.props + [userId, name];
}
