import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/providers/infrastructure/collection.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/widgets/common/immich_toast.dart';

@RoutePage()
class DriftCreateCollectionPage extends ConsumerStatefulWidget {
  /// When set, the new collection is created as a child of this collection.
  final String? parentId;

  const DriftCreateCollectionPage({super.key, this.parentId});

  @override
  ConsumerState<DriftCreateCollectionPage> createState() => _DriftCreateCollectionPageState();
}

class _DriftCreateCollectionPageState extends ConsumerState<DriftCreateCollectionPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_onChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canCreate => _nameController.text.trim().isNotEmpty && !_isSubmitting;

  Future<void> _createCollection() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final description = _descriptionController.text.trim();

    setState(() => _isSubmitting = true);
    try {
      final collection = await ref
          .read(remoteCollectionProvider.notifier)
          .createCollection(
            name: name,
            description: description.isEmpty ? null : description,
            parentId: widget.parentId,
          );

      if (collection != null && mounted) {
        // Replace so the back button returns to the originating list rather
        // than the (now stale) create form.
        unawaited(context.replaceRoute(DriftCollectionRoute(collection: collection)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ImmichToast.show(
          context: context,
          toastType: ToastType.error,
          msg: 'Failed to create collection',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: context.scaffoldBackgroundColor,
        leading: IconButton(onPressed: () => context.maybePop(), icon: const Icon(Icons.close_rounded)),
        title: const Text('New collection'),
        actions: [
          TextButton(
            onPressed: _canCreate ? _createCollection : null,
            child: Text(
              'Create',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _canCreate ? context.primaryColor : context.themeData.disabledColor,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              style: context.textTheme.titleLarge,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Collection name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
