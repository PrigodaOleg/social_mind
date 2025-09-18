// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_stack.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NavStackEntryAdapter extends TypeAdapter<NavStackEntry> {
  @override
  final int typeId = 9;

  @override
  NavStackEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NavStackEntry(
      fields[0] as String,
      (fields[1] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, NavStackEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.path)
      ..writeByte(1)
      ..write(obj.args);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavStackEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
