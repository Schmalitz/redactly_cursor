// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_props.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionPropsAdapter extends TypeAdapter<SessionProps> {
  @override
  final int typeId = 5;

  @override
  SessionProps read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionProps(
      isCaseSensitive: fields[0] as bool,
      isWholeWord: fields[1] as bool,
      delimiter: fields[2] as PlaceholderDelimiter,
      nextPlaceholderIndex: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SessionProps obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.isCaseSensitive)
      ..writeByte(1)
      ..write(obj.isWholeWord)
      ..writeByte(2)
      ..write(obj.delimiter)
      ..writeByte(3)
      ..write(obj.nextPlaceholderIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionPropsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
