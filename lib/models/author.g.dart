// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'author.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuthorAdapter extends TypeAdapter<Author> {
  @override
  final int typeId = 11;

  @override
  Author read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Author(
      type: fields[0] as AuthorType,
      nickname: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Author obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.nickname);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AuthorTypeAdapter extends TypeAdapter<AuthorType> {
  @override
  final int typeId = 10;

  @override
  AuthorType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AuthorType.anonymous;
      case 1:
        return AuthorType.nickname;
      default:
        return AuthorType.anonymous;
    }
  }

  @override
  void write(BinaryWriter writer, AuthorType obj) {
    switch (obj) {
      case AuthorType.anonymous:
        writer.writeByte(0);
        break;
      case AuthorType.nickname:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
