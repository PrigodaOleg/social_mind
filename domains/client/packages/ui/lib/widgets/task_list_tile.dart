import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class TaskListTile extends StatelessWidget {
  const TaskListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onValueChanged,
    this.onTitleSubmitted,
    this.onTitleChanged,
    this.onTitleEditingComplete,
    this.onTitleTap,
    this.onTitleTapOutside,
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onValueChanged;
  final ValueChanged<String>? onTitleSubmitted;
  final ValueChanged<String>? onTitleChanged;
  final VoidCallback? onTitleEditingComplete;
  final VoidCallback? onTitleTap;
  final VoidCallback? onTitleTapOutside;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: <Widget>[
          Checkbox(
            value: value,
            onChanged: (bool? newValue) {
              onValueChanged?.call(newValue!);
            },
          ),
          Expanded(
            child: TextFormField(
              initialValue: title,
              autofocus: true,
              maxLines: null,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              ),
              onChanged: (value) => onTitleChanged?.call(value),
              onFieldSubmitted:  (value) => onTitleSubmitted?.call(value),
              onTap: () => onTitleTap?.call(),
              onTapOutside:  (event) => onTitleTapOutside?.call(),
              // onEditingComplete: () => onTitleEditingComplete?.call(),
            )
          ),
        ],
      ),
    );
  }
}