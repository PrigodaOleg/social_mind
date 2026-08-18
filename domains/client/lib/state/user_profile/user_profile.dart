import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:closers/repository/repository.dart';

class ProfilePageBloc extends Bloc<ProfileEvent, ProfilePageState> {
  ProfilePageBloc({required this.repository, required this.parentId})
      : super(ProfilePageState()) {
    on<ProfilePageStateInitRequested>(_onStateInit);
    on<ProfileRecordChangingRequested>(_onChanged);
    //todo submit requested event
  }

  final Repository repository;
  // final String userId;
  final String parentId;

  Future<void> _onStateInit(
    ProfilePageStateInitRequested event,
    Emitter<ProfilePageState> emit,
  ) async {
    final parent = repository.getModel<Model>(parentId);
    if (parent != null) {
      UserProfile? userProfile = repository
          .getModels<UserProfile>(parent.ids<UserProfile>())
          .values
          .first;
      Map<String, Map<String, dynamic>> profileRecords = {};
      profileRecords = userProfile.getRecords();
      emit(state.copyWith(userProfileRecords: () => profileRecords));
    }
  }

  Future<void> _onChanged(
    ProfileRecordChangingRequested event,
    Emitter<ProfilePageState> emit,
  ) async {
    final recordKey = event.recordKey;
    var stateRecords = state.userProfileRecords;
    stateRecords.update(recordKey, (innerRecords) {
      innerRecords['text'] = event.changedText;
      return innerRecords;
    });
    emit(state.copyWith(userProfileRecords: () => stateRecords));
  }
}

class ProfilePageState {
  const ProfilePageState({this.userProfileRecords = const {}});

  final Map<String, Map<String, dynamic>> userProfileRecords;

  ProfilePageState copyWith({
    Map<String, Map<String, dynamic>> Function()? userProfileRecords,
  }) {
    return ProfilePageState(
      userProfileRecords: userProfileRecords != null
          ? userProfileRecords()
          : this.userProfileRecords,
    );
  }
}

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

final class ProfilePageStateInitRequested extends ProfileEvent {
  const ProfilePageStateInitRequested();
}

final class ProfileRecordChangingRequested extends ProfileEvent {
  const ProfileRecordChangingRequested({
    required this.recordKey,
    required this.changedText,
  });

  final String recordKey;
  final String changedText;
}
final class ProfileRecordSubmitRequested extends ProfileEvent{
const ProfileRecordSubmitRequested({
    required this.recordKey,
    required this.changedText,
    });
  final String recordKey;
  final String changedText;
}
