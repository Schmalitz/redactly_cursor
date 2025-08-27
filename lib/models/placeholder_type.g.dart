// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'placeholder_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaceholderTypeAdapter extends TypeAdapter<PlaceholderType> {
  @override
  final int typeId = 4;

  @override
  PlaceholderType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PlaceholderType.custom;
      case 1:
        return PlaceholderType.person;
      case 2:
        return PlaceholderType.organization;
      case 3:
        return PlaceholderType.location;
      case 4:
        return PlaceholderType.date;
      case 5:
        return PlaceholderType.email;
      case 6:
        return PlaceholderType.phone;
      default:
        return PlaceholderType.custom;
    }
  }

  @override
  void write(BinaryWriter writer, PlaceholderType obj) {
    switch (obj) {
      case PlaceholderType.custom:
        writer.writeByte(0);
        break;
      case PlaceholderType.person:
        writer.writeByte(1);
        break;
      case PlaceholderType.organization:
        writer.writeByte(2);
        break;
      case PlaceholderType.location:
        writer.writeByte(3);
        break;
      case PlaceholderType.date:
        writer.writeByte(4);
        break;
      case PlaceholderType.email:
        writer.writeByte(5);
        break;
      case PlaceholderType.phone:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceholderTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
