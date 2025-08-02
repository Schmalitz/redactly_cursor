// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'placeholder_mapping.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaceholderMappingAdapter extends TypeAdapter<PlaceholderMapping> {
  @override
  final int typeId = 1;

  @override
  PlaceholderMapping read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaceholderMapping(
      id: fields[0] as String,
      originalText: fields[1] as String,
      placeholder: fields[2] as String,
      colorValue: fields[3] as int,
      isCaseSensitive: fields[4] as bool,
      isWholeWord: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PlaceholderMapping obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalText)
      ..writeByte(2)
      ..write(obj.placeholder)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.isCaseSensitive)
      ..writeByte(5)
      ..write(obj.isWholeWord);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceholderMappingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
