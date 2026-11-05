import 'package:equatable/equatable.dart';

// part 'navigation_stack.g.dart';
class NavStackEntry extends Equatable {
  NavStackEntry(
    this.path,
    this.args
  );
  String path;
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