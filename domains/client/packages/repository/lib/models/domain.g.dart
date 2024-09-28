// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DomainAdapter extends TypeAdapter<Domain> {
  @override
  final int typeId = 0;

  @override
  Domain read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Domain(
      title: fields[1] as String,
      id: fields[0] as String?,
      description: fields[2] as String,
      isPersonal: fields[3] as bool,
      originatorId: fields[4] as String,
      participantsIds: (fields[5] as List).cast<String>(),
      observersIds: (fields[6] as List).cast<String>(),
      tasksIds: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Domain obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isPersonal)
      ..writeByte(4)
      ..write(obj.originatorId)
      ..writeByte(5)
      ..write(obj.participantsIds)
      ..writeByte(6)
      ..write(obj.observersIds)
      ..writeByte(7)
      ..write(obj.tasksIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
