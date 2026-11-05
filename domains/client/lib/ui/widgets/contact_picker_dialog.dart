// Reusable modal dialog for picking one or several contacts.
// Can be used from anywhere in the app:
//
//   final contact = await showContactPickerDialog(context, contacts: contacts);
//   final picked = await showContactPickerDialog(context, contacts: contacts, multiSelect: true);
import 'package:flutter/material.dart';
import 'package:closers/repository/repository.dart';
import '../ui.dart';

AppLocalizations _l10n(BuildContext context) => AppLocalizations.of(context);

/// Shows a modal window with the list of [contacts].
/// - If [multiSelect] is false (default), tapping a contact immediately
///   returns it.
/// - If [multiSelect] is true, checkboxes are shown and the OK button
///   returns the set of selected contacts.
/// Returns null if the dialog was dismissed.
Future<Object?>? showContactPickerDialog(
  BuildContext context, {
  required Map<String, Contact> contacts,
  bool multiSelect = false,
}) {
  return showDialog<Object?>(
    context: context,
    builder: (_) => ContactPickerDialog(
      contacts: contacts,
      multiSelect: multiSelect,
    ),
  );
}

class ContactPickerDialog extends StatefulWidget {
  const ContactPickerDialog({
    super.key,
    required this.contacts,
    this.multiSelect = false,
  });

  final Map<String, Contact> contacts;
  final bool multiSelect;

  @override
  State<ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<ContactPickerDialog> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = _l10n(context);
    final contacts = widget.contacts.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return AlertDialog(
      title: Text(l.contactPickerTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: contacts.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
child: Text(AppLocalizations.of(context).contactListEmpty, textAlign: TextAlign.center),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  if (widget.multiSelect) {
                    return CheckboxListTile(
                      value: _selected.contains(contact.id),
                      title: Text(contact.name),
                      subtitle: contact.userId.isEmpty ? null : Text(contact.userId),
                      onChanged: (checked) => setState(() {
                        checked == true
                            ? _selected.add(contact.id)
                            : _selected.remove(contact.id);
                      }),
                    );
                  }
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(contact.name),
                    subtitle:
                        contact.userId.isEmpty ? null : Text(contact.userId),
                    onTap: () => Navigator.of(context).pop(contact),
                  );
                },
              ),
      ),
      actions: [
        if (widget.multiSelect)
          TextButton(
            onPressed: () {
              final result = <Contact>{
                for (final id in _selected)
                  if (widget.contacts[id] != null) widget.contacts[id]!,
              };
              Navigator.of(context).pop(result);
            },
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}
