import 'package:flutter/material.dart';

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
    this.backgroundColor
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onValueChanged;
  final ValueChanged<String>? onTitleSubmitted;
  final ValueChanged<String>? onTitleChanged;
  final VoidCallback? onTitleEditingComplete;
  final VoidCallback? onTitleTap;
  final VoidCallback? onTitleTapOutside;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    // return SizedBox(
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      color: backgroundColor,
      child: Row(
        children: <Widget>[
          SizedBox(
            height: Theme.of(context).textTheme.bodyMedium!.height! * Theme.of(context).textTheme.bodyMedium!.fontSize!,
            child: Checkbox(
              value: value,
              onChanged: (bool? newValue) {
                onValueChanged?.call(newValue!);
              },
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: title,
              autofocus: true,
              maxLines: null,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.all(0.0),
                filled: true,
                fillColor: backgroundColor
              ),
              onChanged: (value) => onTitleChanged?.call(value),
              onFieldSubmitted:  (value) => onTitleSubmitted?.call(value),
              onTap: () => onTitleTap?.call(),
              onTapOutside:  (event) => onTitleTapOutside?.call(),
              // on
              // onEditingComplete: () => onTitleEditingComplete?.call(),
            )
          ),
        ],
      ),
    );
  }
}