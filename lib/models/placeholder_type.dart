import 'package:hive/hive.dart';

part 'placeholder_type.g.dart';

@HiveType(typeId: 4)
enum PlaceholderType {
  @HiveField(0)
  custom,
  @HiveField(1)
  person,
  @HiveField(2)
  organization,
  @HiveField(3)
  location,
  @HiveField(4)
  date,
  @HiveField(5)
  email,
  @HiveField(6)
  phone,
}
