import 'package:hive_flutter/hive_flutter.dart';
import 'package:equatable/equatable.dart';

// part 'navigation_stack.g.dart';


@HiveType(typeId: 4)
class NavStackEntry extends Equatable {
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
    "args": args
  };

  NavStackEntry.fromJson(Map<String, dynamic> json) :
    path = json['path'] as String,
    args = json['args'] as Map<String, dynamic>;
    
  @override
  List<Object?> get props => [path, args];
}