import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:closers/repository/repository.dart';

class ProfilePageBloc extends Bloc<ProfileEvent, ProfilePageState> {
  ProfilePageBloc({required this.repository, required this.userId})
      : super(ProfilePageState()) {
    on<ProfilePageStateInitRequested>(_onStateInit);
    on<ProfileRecordChangingRequested>(_onChanged);
    on<ProfileRecordSubmitRequested>(_onRecordSubmit);
  }

  final Repository repository;
  final String userId;

  Future<void> _onStateInit(
    ProfilePageStateInitRequested event,
    Emitter<ProfilePageState> emit,
  ) async {
    final user = repository.getModel<User>(userId);
    if (user != null) {
      List<Map<String, dynamic>> userProfileRecords = user.propsList();
      emit(state.copyWith(userProfileRecords: () => userProfileRecords ));
    }
  }

  Future<void> _onChanged(
    ProfileRecordChangingRequested event,
    Emitter<ProfilePageState> emit,
  ) async {
    final recordIndex = event.recordIndex;
    var stateRecords = state.userProfileRecords;
    final record = stateRecords[recordIndex];
    record['value'] = event.changedText;
    emit(state.copyWith(userProfileRecords: () => stateRecords ));
  }

  Future<void> _onRecordSubmit(
  ProfileRecordSubmitRequested event,
  Emitter<ProfilePageState> emit,
  )async {
    final recordIndex = event.recordIndex;
    var stateRecords = state.userProfileRecords;
    final record = stateRecords[recordIndex];
    record['value'] = event.changedText;
    final user = repository.getModel<User>(userId);
    if(user != null){
      final updatedUser = user.copyWithList(stateRecords);
      repository.saveModel(updatedUser);
      emit(state.copyWith(userProfileRecords: () => stateRecords ));
    }
  }
}

class ProfilePageState {
  const ProfilePageState({this.userProfileRecords = const []});

  final List<Map<String,dynamic>> userProfileRecords;

  ProfilePageState copyWith({
    List<Map<String,dynamic>> Function()? userProfileRecords,
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
    required this.recordIndex,
    required this.changedText,
  });

  final int recordIndex;
  final String changedText;
}

final class ProfileRecordSubmitRequested extends ProfileEvent {
  const ProfileRecordSubmitRequested({
    required this.recordIndex,
    required this.changedText,
  });
  final int recordIndex;
  final String changedText;
}
