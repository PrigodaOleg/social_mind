// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationAdapter extends TypeAdapter<Location> {
  @override
  final int typeId = 3;

  @override
  Location read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Location.local;
      case 1:
        return Location.remote;
      case 2:
        return Location.both;
      default:
        return Location.local;
    }
  }

  @override
  void write(BinaryWriter writer, Location obj) {
    switch (obj) {
      case Location.local:
        writer.writeByte(0);
        break;
      case Location.remote:
        writer.writeByte(1);
        break;
      case Location.both:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 1;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String?,
      name: fields[6] as String,
      domainsIds: (fields[7] as List?)?.cast<String>(),
    )
      ..children = (fields[4] as Map).cast<String, String>()
      ..parents = (fields[5] as Map).cast<String, String>();
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(8)
      ..writeByte(6)
      ..write(obj.name)
      ..writeByte(7)
      ..write(obj.domainsIds)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.children)
      ..writeByte(5)
      ..write(obj.parents);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DomainAdapter extends TypeAdapter<Domain> {
  @override
  final int typeId = 2;

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
      isPersonal: fields[6] as bool,
      originatorId: fields[7] as String,
      participantsIds: (fields[8] as List?)?.cast<String>(),
      observersIds: (fields[9] as List?)?.cast<String>(),
      models: (fields[10] as Map?)?.cast<String, String>(),
    )
      ..children = (fields[4] as Map).cast<String, String>()
      ..parents = (fields[5] as Map).cast<String, String>();
  }

  @override
  void write(BinaryWriter writer, Domain obj) {
    writer
      ..writeByte(11)
      ..writeByte(6)
      ..write(obj.isPersonal)
      ..writeByte(7)
      ..write(obj.originatorId)
      ..writeByte(8)
      ..write(obj.participantsIds)
      ..writeByte(9)
      ..write(obj.observersIds)
      ..writeByte(10)
      ..write(obj.models)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.children)
      ..writeByte(5)
      ..write(obj.parents);
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

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      title: fields[1] as String,
      id: fields[0] as String?,
      description: fields[2] as String,
      isCompleted: fields[6] as bool,
      originatorId: fields[7] as String,
      executorId: fields[8] as String,
    )
      ..children = (fields[4] as Map).cast<String, String>()
      ..parents = (fields[5] as Map).cast<String, String>();
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(9)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.originatorId)
      ..writeByte(8)
      ..write(obj.executorId)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.children)
      ..writeByte(5)
      ..write(obj.parents);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
