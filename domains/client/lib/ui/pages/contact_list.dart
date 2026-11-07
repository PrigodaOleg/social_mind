// Contact list page: shows the contacts of the current user's contact list,
// allows adding, editing and deleting them.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/state/state.dart';
import '../ui.dart';

class ContactListPage extends StatelessWidget {
  static const routeName = '/contacts';

  const ContactListPage(
    this.repository, {
    super.key,
    this.title,
  });

  final String? title;
  final Repository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContactListBloc(repository: repository)
        ..add(const ContactListInitRequested()),
      child: ContactListView(title: title),
    );
  }
}

class ContactListView extends StatelessWidget {
  const ContactListView({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);
    final b = BlocProvider.of<ContactListBloc>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: t.colorScheme.inversePrimary,
        title: Text(title ?? l.contactListPageName),
      ),
      body: BlocBuilder<ContactListBloc, ContactListState>(
        builder: (context, state) {
          if (state.status != ContactListStatus.ready) {
            return const Center(child: CircularProgressIndicator());
          }
          final contacts = state.contacts.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (contacts.isEmpty) {
            return Center(
              child: Text(l.contactListEmpty),
            );
          }
          return ListView(
            children: [
              for (final contact in contacts)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(contact.name),
                  subtitle: Text(contact.userId),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l.contactListDelete,
                    onPressed: () async {
                      final confirmed = await _confirmDelete(context, contact);
                      if (confirmed) {
                        b.add(ContactListContactDeleted(contactId: contact.id));
                      }
                    },
                  ),
                  onTap: () => _showEditDialog(context, contact),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l.contactListAdd,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Contact contact) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(AppLocalizations.of(dialogContext).contactListDelete),
            content: Text(
              AppLocalizations.of(dialogContext)
                  .contactListDeleteConfirm(contact.name),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(MaterialLocalizations.of(dialogContext)
                    .cancelButtonLabel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(AppLocalizations.of(dialogContext).contactListDelete),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final b = BlocProvider.of<ContactListBloc>(context);
    final result = await _showContactFormDialog(context);
    if (result != null && context.mounted) {
      b.add(ContactListContactCreated(
        name: result.$1,
        userId: result.$2,
      ));
    }
  }

  Future<void> _showEditDialog(BuildContext context, Contact contact) async {
    final b = BlocProvider.of<ContactListBloc>(context);
    final result = await _showContactFormDialog(
      context,
      initialName: contact.name,
      initialUserId: contact.userId,
    );
    if (result != null && context.mounted) {
      b.add(ContactListContactEdited(
        contactId: contact.id,
        name: result.$1,
      ));
    }
  }

  /// Returns (name, userId) or null if cancelled.
  Future<(String, String)?> _showContactFormDialog(
    BuildContext context, {
    String initialName = '',
    String initialUserId = '',
  }) async {
    final nameController = TextEditingController(text: initialName);
    final userIdController = TextEditingController(text: initialUserId);
    final formKey = GlobalKey<FormState>();

    return await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          initialName.isEmpty
              ? AppLocalizations.of(dialogContext).contactListAdd
              : AppLocalizations.of(dialogContext).contactListEdit,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(dialogContext).contactListNameLabel,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? AppLocalizations.of(dialogContext).contactListNameRequired
                    : null,
              ),
              TextFormField(
                controller: userIdController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(dialogContext).contactListUserIdLabel,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? AppLocalizations.of(dialogContext).contactListUserIdRequired
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
                MaterialLocalizations.of(dialogContext).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop((
                  nameController.text.trim(),
                  userIdController.text.trim(),
                ));
              }
            },
            child:
                Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );
  }
}
