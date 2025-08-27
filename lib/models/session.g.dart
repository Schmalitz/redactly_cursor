// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final int typeId = 0;

  @override
  Session read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Session(
      id: fields[0] as String,
      title: fields[1] as String,
      originalInput: fields[2] as String,
      placeholderedInput: fields[6] as String,
      mappings: (fields[3] as List).cast<PlaceholderMapping>(),
      createdAt: fields[4] as DateTime,
      props: fields[7] as SessionProps,
      titleMode: fields[5] as SessionTitleMode,
      placeholderedOutputCache: fields[14] as String?,
      editedOutputCache: fields[15] as String?,
      lastOpenedAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      archived: fields[12] as bool,
      schemaVersion: fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.titleMode)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.lastOpenedAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.archived)
      ..writeByte(13)
      ..write(obj.schemaVersion)
      ..writeByte(2)
      ..write(obj.originalInput)
      ..writeByte(6)
      ..write(obj.placeholderedInput)
      ..writeByte(14)
      ..write(obj.placeholderedOutputCache)
      ..writeByte(15)
      ..write(obj.editedOutputCache)
      ..writeByte(3)
      ..write(obj.mappings)
      ..writeByte(7)
      ..write(obj.props);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
