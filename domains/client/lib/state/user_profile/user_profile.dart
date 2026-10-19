import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:closers/repository/repository.dart';

class ProfilePageBloc extends Bloc<ProfileEvent, ProfilePageState> {
  ProfilePageBloc({required this.repository, required this.userId})
      : super(ProfilePageState()) {
    on<ProfilePageStateInitRequested>(_onStateInit);
    on<ProfileRecordChangingRequested>(_onChanged);
    on<ProfileRecordSubmitRequested>(_onRecordSubmit);
    on<ProfileAvatarUpdateRequested>(_onAvatarUpdate);
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
      List<Map<String, dynamic>> visibleUserProfileRecords = userProfileRecords
          .where((property) => property['propId'] != 'avatarUrl')
          .toList();
      final String avatarDBRecordName = userProfileRecords
          .firstWhere((record) => record['propId'] == 'avatarUrl')['value'];
      final Uint8List? avatarBytes = repository.getImage(avatarDBRecordName);
      emit(state.copyWith(
          userProfileRecords: visibleUserProfileRecords,
          avatarBytes: avatarBytes,
          avatarDBName: avatarDBRecordName));
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
    emit(state.copyWith(userProfileRecords: stateRecords));
  }

  Future<void> _onRecordSubmit(
    ProfileRecordSubmitRequested event,
    Emitter<ProfilePageState> emit,
  ) async {
    final recordIndex = event.recordIndex;
    var stateRecords = state.userProfileRecords;
    final record = stateRecords[recordIndex];
    record['value'] = event.changedText;
    final user = repository.getModel<User>(userId);
    if (user != null) {
      final updatedUser = user.copyWithList(stateRecords);
      repository.saveModel(updatedUser);
      emit(state.copyWith(userProfileRecords: stateRecords));
    }
  }

  Future<void> _onAvatarUpdate(
    ProfileAvatarUpdateRequested event,
    Emitter<ProfilePageState> emit,
  ) async {
    final avatarDBName = event.avatarDBName;
    final Uint8List avatarBytes = event.avatarBytes;
    repository.saveImage(avatarDBName, avatarBytes);
    emit(state.copyWith(avatarBytes: avatarBytes));
  }
}

class ProfilePageState {
  const ProfilePageState(
      {this.userProfileRecords = const [],
      this.avatarBytes,
      this.avatarDBName = ''});

  final List<Map<String, dynamic>> userProfileRecords;
  final Uint8List? avatarBytes;
  final String avatarDBName;

  ProfilePageState copyWith({
    List<Map<String, dynamic>>? userProfileRecords,
    Uint8List? avatarBytes,
    String? avatarDBName,
  }) {
    return ProfilePageState(
      userProfileRecords: userProfileRecords ?? this.userProfileRecords,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      avatarDBName: avatarDBName ?? this.avatarDBName,
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

final class ProfileAvatarUpdateRequested extends ProfileEvent {
  const ProfileAvatarUpdateRequested({
    required this.avatarDBName,
    required this.avatarBytes,
  });
  final String avatarDBName;
  final Uint8List avatarBytes;
}
