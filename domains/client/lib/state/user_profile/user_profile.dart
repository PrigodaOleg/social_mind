import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:closers/repository/repository.dart';

class ProfilePageBloc extends Bloc<ProfileEvent, ProfilePageState> {
  ProfilePageBloc({required this.repository, required this.userId})
      : super(ProfilePageState()) {
    on<ProfilePageStateInitRequested>(_onStateInit);
    on<ProfileRecordChangingRequested>(_onChanged);
  }

  final Repository repository;
  final String userId;

  Future<void> _onStateInit(
    ProfilePageStateInitRequested event,
    Emitter<ProfilePageState> emit,
  ) async {
    UserProfile? userProfile = repository.getModel(repository.myId);
    Map<String, Map<String, dynamic>> profileRecords = {};
    if (userProfile != null) {
      profileRecords = userProfile.getRecords();
    }
    emit(state.copyWith(userProfileRecords: () => profileRecords));
  }

  Future<void> _onChanged(
    ProfileRecordChangingRequested event,
    Emitter<ProfilePageState> emit,
  ) async {
    final recordKey = event.recordKey;
    var stateRecords = state.userProfileRecords;
    stateRecords.update(recordKey, (inerRecords) {
      inerRecords['text'] = event.changedText;
      return inerRecords;
    });
    print(stateRecords.toString());
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
