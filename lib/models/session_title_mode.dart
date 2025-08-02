import 'package:hive/hive.dart';

part 'session_title_mode.g.dart';

@HiveType(typeId: 2)
enum SessionTitleMode {
  @HiveField(0)
  auto,

  @HiveField(1)
  userDefined,

  @HiveField(2)
  locked,
}
