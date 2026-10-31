part of 'models.dart';

// ignore: must_be_immutable
class ContactList extends Model {
  ContactList({
    super.id,
    super.title,
    super.description,
    required this.originatorId,
    List<String>? contactList,
  }) : contactList = contactList ?? <String>[];

  ContactList.fromJson(super.json)
      : originatorId = (json['originatorId'] ?? '') as String,
        contactList = List<String>.from(json['contactList'] is List
            ? json['contactList']
            : json['contactList']?.keys ?? []),
        super.fromJson();

  @override
  // ignore: overridden_fields
  final String type = "ContactList";

  /// ID of the model (e.g. User) that originated this contact list.
  final String originatorId;

  /// IDs of Contact models.
  List<String> contactList;

  ContactList copyWith({
    String? id,
    String? title,
    String? description,
    String? originatorId,
    List<String>? contactList,
  }) {
    return ContactList(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      originatorId: originatorId ?? this.originatorId,
      contactList: contactList ?? this.contactList,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "originatorId": originatorId,
      "contactList": contactList,
    });

  @override
  List<Object> get props => super.props + [originatorId, contactList];
}
