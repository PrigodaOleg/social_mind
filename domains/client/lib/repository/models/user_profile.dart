part of 'models.dart';
//todo make UserProfile model

class UserProfile extends Model {
  UserProfile({
    super.id,
    this.firstName = '',
    this.lastName = '',
    required this.originatorId,
  });

  @override
  // ignore: overridden_fields
  final String type = 'UserProfile';

  final String originatorId;

  final String firstName;
  final String lastName;

  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? originatorId,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      originatorId: originatorId ?? this.originatorId,
    );
  }

  Map<String, Map<String, dynamic>> getRecords() {
    return {
      'firstName': {
        'text': 'artem',
        'isRedactable': true,
        'hint': 'first name',
      },
      'lastName': {
        'text': 'prigoda',
        'isRedactable': false,
        'hint': 'last name',
      },
    };
  }

  @override
  List<Object> get props => super.props + [ originatorId,firstName, lastName];
}
