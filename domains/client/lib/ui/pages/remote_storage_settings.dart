import 'package:closers/repository/repository.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Pre-login remote storage picker (Option A).
///
/// Reachable from the login page. Edits a device-local profile
/// ([RemoteStorageConfig]) that is merged into every user's
/// `settings['remote_storages']` when a user is created or logged in
/// on this device (see [Repository.applyRemoteStorageConfig]).
class RemoteStorageSettingsPage extends StatefulWidget {
  static const routeName = '/remote_storage_settings';
  final Repository repository;
  const RemoteStorageSettingsPage(this.repository, {super.key});

  @override
  State<StatefulWidget> createState() => RemoteStorageSettingsPageState();
}

class RemoteStorageSettingsPageState extends State<RemoteStorageSettingsPage> {
  late RemoteStorageConfig config;

  @override
  void initState() {
    super.initState();
    config = widget.repository.getRemoteStorageConfig();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.remoteStoragePageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l.save,
            onPressed: () async {
              await widget.repository.setRemoteStorageConfig(config);
              if (context.mounted) Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.remoteStoragePageHint),
          ),
          for (final storageKey in widget.repository.knownRemoteStorages.keys)
            _StorageCard(
              storageKey: storageKey,
              enabled: config.contains(storageKey),
              instance: config.instanceOf(storageKey) ?? '',
              anonKey: config.anonKeyOf(storageKey) ?? '',
              onChanged: (enabled, instance, anonKey) {
                setState(() {
                  config.set(storageKey, instance: instance, anonKey: anonKey);
                });
              },
              onTest: () => _testConnection(context, storageKey),
            ),
        ],
      ),
    );
  }

  Future<void> _testConnection(BuildContext context, String storageKey) async {
    final l = AppLocalizations.of(context);
    final instance = config.instanceOf(storageKey);
    if (instance == null || instance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.remoteStorageTestNoInstance)),
      );
      return;
    }
    final storage = widget.repository.knownRemoteStorages[storageKey]?.call();
    if (storage == null) return;
    bool ok = false;
    try {
      ok = await (storage as dynamic)
          .init(instance, anonKey: config.anonKeyOf(storageKey));
    } catch (error) {
      print('RemoteStorageSettingsPage: test $storageKey failed: $error');
      ok = false;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? l.remoteStorageTestOk
            : l.remoteStorageTestFail),
      ),
    );
  }
}

class _StorageCard extends StatefulWidget {
  final String storageKey;
  final bool enabled;
  final String instance;
  final String anonKey;
  final void Function(bool enabled, String? instance, String? anonKey) onChanged;
  final VoidCallback onTest;

  const _StorageCard({
    required this.storageKey,
    required this.enabled,
    required this.instance,
    required this.anonKey,
    required this.onChanged,
    required this.onTest,
  });

  @override
  State<StatefulWidget> createState() => _StorageCardState();
}

class _StorageCardState extends State<_StorageCard> {
  late bool enabled;
  late TextEditingController instanceController;
  late TextEditingController anonKeyController;

  @override
  void initState() {
    super.initState();
    enabled = widget.enabled;
    instanceController = TextEditingController(text: widget.instance);
    anonKeyController = TextEditingController(text: widget.anonKey);
  }

  @override
  void dispose() {
    instanceController.dispose();
    anonKeyController.dispose();
    super.dispose();
  }

  /// Mirrors the instance validation of FirebaseStorage.init(): non-empty,
  /// max 64 chars, allowlist of [A-Za-z0-9_-].
  String? _validateInstance(String? value) {
    final l = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return null;
    if (value.length > 64 || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      return l.remoteStorageInvalidInstance;
    }
    return null;
  }

  void _emit() {
    final instance = instanceController.text.trim();
    final anonKey = anonKeyController.text.trim();
    widget.onChanged(
      enabled,
      instance.isEmpty ? null : instance,
      anonKey.isEmpty ? null : anonKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.storageKey,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Switch(
                  value: enabled,
                  onChanged: (value) {
                    setState(() => enabled = value);
                    _emit();
                  },
                ),
              ],
            ),
            if (enabled) ...[
              TextField(
                controller: instanceController,
                decoration: InputDecoration(
                  labelText: l.remoteStorageInstanceLabel,
                  errorText: _validateInstance(instanceController.text),
                ),
                onChanged: (value) {
                  setState(() {}); // re-validate
                  _emit();
                },
              ),
              TextField(
                controller: anonKeyController,
                decoration: InputDecoration(
                  labelText: l.remoteStorageAnonKeyLabel,
                ),
                onChanged: (value) => _emit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.wifi_tethering),
                  label: Text(l.remoteStorageTestConnection),
                  onPressed: widget.onTest,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
