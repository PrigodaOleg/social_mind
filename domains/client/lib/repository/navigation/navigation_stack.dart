import 'package:hive_flutter/hive_flutter.dart';
import "dart:convert";

part 'navigation_stack.g.dart';


@HiveType(typeId: 4)
class NavStackEntry {
  NavStackEntry(
    this.path,
    this.args
  );

  @HiveField(0)
  String path;

  @HiveField(1)
  Map<String, dynamic> args;

  Map<String, dynamic> toJson() => {
    "path": path,
    "args": json.encode(args)
  };

  NavStackEntry.fromJson(Map<String, dynamic> json) :
    path = json['path'] as String,
    args = json['args'] as Map<String, dynamic>;
}