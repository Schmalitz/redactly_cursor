// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_title_mode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionTitleModeAdapter extends TypeAdapter<SessionTitleMode> {
  @override
  final int typeId = 2;

  @override
  SessionTitleMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SessionTitleMode.auto;
      case 1:
        return SessionTitleMode.userDefined;
      case 2:
        return SessionTitleMode.locked;
      default:
        return SessionTitleMode.auto;
    }
  }

  @override
  void write(BinaryWriter writer, SessionTitleMode obj) {
    switch (obj) {
      case SessionTitleMode.auto:
        writer.writeByte(0);
        break;
      case SessionTitleMode.userDefined:
        writer.writeByte(1);
        break;
      case SessionTitleMode.locked:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionTitleModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
