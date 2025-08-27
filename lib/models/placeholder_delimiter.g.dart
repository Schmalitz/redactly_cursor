// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'placeholder_delimiter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaceholderDelimiterAdapter extends TypeAdapter<PlaceholderDelimiter> {
  @override
  final int typeId = 3;

  @override
  PlaceholderDelimiter read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PlaceholderDelimiter.square;
      case 1:
        return PlaceholderDelimiter.curly;
      case 2:
        return PlaceholderDelimiter.hash;
      case 3:
        return PlaceholderDelimiter.round;
      case 4:
        return PlaceholderDelimiter.angle;
      default:
        return PlaceholderDelimiter.square;
    }
  }

  @override
  void write(BinaryWriter writer, PlaceholderDelimiter obj) {
    switch (obj) {
      case PlaceholderDelimiter.square:
        writer.writeByte(0);
        break;
      case PlaceholderDelimiter.curly:
        writer.writeByte(1);
        break;
      case PlaceholderDelimiter.hash:
        writer.writeByte(2);
        break;
      case PlaceholderDelimiter.round:
        writer.writeByte(3);
        break;
      case PlaceholderDelimiter.angle:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceholderDelimiterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
