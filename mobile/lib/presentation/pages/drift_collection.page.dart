import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/domain/models/collection/collection.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/theme_extensions.dart';
import 'package:immich_mobile/presentation/widgets/collection/collection_list_tile.widget.dart';
import 'package:immich_mobile/presentation/widgets/images/remote_image_provider.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/collection.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/utils/image_url_builder.dart';
import 'package:immich_mobile/widgets/common/immich_toast.dart';

@RoutePage()
class DriftCollectionPage extends ConsumerStatefulWidget {
  final RemoteCollection collection;

  const DriftCollectionPage({super.key, required this.collection});

  @override
  ConsumerState<DriftCollectionPage> createState() => _DriftCollectionPageState();
}

class _DriftCollectionPageState extends ConsumerState<DriftCollectionPage> {
  @override
  void initState() {
    super.initState();
    // Albums are needed to resolve this collection's albumIds into rows, and
    // a collection refresh keeps child/album counts current.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remoteCollectionProvider.notifier).refresh();
      ref.read(remoteAlbumProvider.notifier).refresh();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(remoteCollectionProvider.notifier).refresh();
    await ref.read(remoteAlbumProvider.notifier).refresh();
  }

  Future<void> _rename(RemoteCollection collection) async {
    final controller = TextEditingController(text: collection.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == collection.name) {
      return;
    }
    await ref.read(remoteCollectionProvider.notifier).updateCollection(collection.id, name: newName);
  }

  Future<void> _delete(RemoteCollection collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete collection'),
        content: const Text(
          'This deletes the collection and its sub-collections. Albums inside are moved back to the root, never deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: context.colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    await ref.read(remoteCollectionProvider.notifier).deleteCollection(collection.id);
    if (mounted) {
      context.maybePop();
    }
  }

  Future<void> _move(RemoteCollection collection) async {
    final all = ref.read(remoteCollectionProvider).collections;
    final descendantIds = _descendantIds(all, collection.id);
    // Valid targets: anything that is not the collection itself or a descendant
    // (which would create a cycle), and not its current parent.
    final candidates = all
        .where((c) => c.id != collection.id && !descendantIds.contains(c.id) && c.id != collection.parentId)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final target = await showDialog<_MoveTarget>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Move to'),
        children: [
          if (collection.parentId != null)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(const _MoveTarget.root()),
              child: const Text('Root (no parent)'),
            ),
          for (final candidate in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(_MoveTarget.collection(candidate.id)),
              child: Text(candidate.name),
            ),
          if (candidates.isEmpty && collection.parentId == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No other collections to move into.'),
            ),
        ],
      ),
    );

    if (target == null) {
      return;
    }
    await ref.read(remoteCollectionProvider.notifier).moveCollection(collection.id, parentId: target.parentId);
  }

  Future<void> _addAlbums(RemoteCollection collection) async {
    final albums = ref.read(remoteAlbumProvider).albums;
    final allCollections = ref.read(remoteCollectionProvider).collections;
    // An album can belong to only one collection, so only offer albums that are
    // not already assigned to any collection.
    final assignedAlbumIds = <String>{for (final c in allCollections) ...c.albumIds};
    final available = albums.where((album) => !assignedAlbumIds.contains(album.id)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (available.isEmpty) {
      ImmichToast.show(context: context, msg: 'No unassigned albums available', toastType: ToastType.info);
      return;
    }

    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => _AlbumPickerDialog(albums: available),
    );

    if (selected == null || selected.isEmpty) {
      return;
    }
    final added = await ref.read(remoteCollectionProvider.notifier).addAlbums(collection.id, selected.toList());
    if (added > 0 && mounted) {
      ImmichToast.show(context: context, msg: 'Added $added album(s)', toastType: ToastType.success);
    }
  }

  Future<void> _removeAlbum(RemoteCollection collection, RemoteAlbum album) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove album'),
        content: Text('Remove "${album.name}" from this collection? It will be moved back to the root.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    await ref.read(remoteCollectionProvider.notifier).removeAlbums(collection.id, [album.id]);
  }

  @override
  Widget build(BuildContext context) {
    // Prefer the live copy from state (reflects renames / count changes); fall
    // back to the route argument until the first refresh lands.
    final collection =
        ref.watch(remoteCollectionProvider.select((s) => s.collectionById(widget.collection.id))) ?? widget.collection;
    final subCollections = ref.watch(remoteCollectionProvider.select((s) => s.childrenOf(collection.id)));

    final albumIds = collection.albumIds.toSet();
    final albums = ref.watch(
      remoteAlbumProvider.select((s) => s.albums.where((a) => albumIds.contains(a.id)).toList()),
    );

    final hasContent = subCollections.isNotEmpty || albums.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        actions: [
          IconButton(
            tooltip: 'Add albums',
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () => _addAlbums(collection),
          ),
          IconButton(
            tooltip: 'New sub-collection',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => context.pushRoute(DriftCreateCollectionRoute(parentId: collection.id)),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _rename(collection);
                  break;
                case 'move':
                  _move(collection);
                  break;
                case 'delete':
                  _delete(collection);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'move', child: Text('Move')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (collection.description.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(collection.description, style: context.textTheme.bodyMedium),
                ),
              ),
            if (subCollections.isNotEmpty) ...[
              const _SectionHeader(title: 'Collections'),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final child = subCollections[index];
                  return CollectionListTile(
                    collection: child,
                    onTap: () => context.pushRoute(DriftCollectionRoute(collection: child)),
                  );
                }, childCount: subCollections.length),
              ),
            ],
            if (albums.isNotEmpty) ...[
              const _SectionHeader(title: 'Albums'),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final album = albums[index];
                  return _AlbumListTile(
                    album: album,
                    onTap: () => context.pushRoute(RemoteAlbumRoute(album: album)),
                    onRemove: () => _removeAlbum(collection, album),
                  );
                }, childCount: albums.length),
              ),
            ],
            if (!hasContent)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('This collection is empty.'))),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  /// Collects the IDs of all collections nested anywhere beneath [rootId].
  Set<String> _descendantIds(List<RemoteCollection> all, String rootId) {
    final childrenByParent = <String?, List<RemoteCollection>>{};
    for (final c in all) {
      childrenByParent.putIfAbsent(c.parentId, () => []).add(c);
    }
    final result = <String>{};
    final stack = <String>[rootId];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      for (final child in childrenByParent[current] ?? const []) {
        if (result.add(child.id)) {
          stack.add(child.id);
        }
      }
    }
    return result;
  }
}

class _MoveTarget {
  final String? parentId;

  const _MoveTarget.root() : parentId = null;
  const _MoveTarget.collection(String id) : parentId = id;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            color: context.colorScheme.onSurfaceSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AlbumListTile extends StatelessWidget {
  const _AlbumListTile({required this.album, required this.onTap, required this.onRemove});

  final RemoteAlbum album;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final thumbnailAssetId = album.thumbnailAssetId;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: SizedBox(
          width: 56,
          height: 56,
          child: thumbnailAssetId != null
              ? Image(
                  image: RemoteImageProvider(url: getThumbnailUrlForRemoteId(thumbnailAssetId)),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(context),
                )
              : _placeholder(context),
        ),
      ),
      title: Text(
        album.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        album.assetCount == 1 ? '1 item' : '${album.assetCount} items',
        style: context.textTheme.bodyMedium,
      ),
      trailing: IconButton(
        tooltip: 'Remove from collection',
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: onRemove,
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.colorScheme.surfaceContainerHigh,
      child: Icon(Icons.photo_album_outlined, color: context.primaryColor),
    );
  }
}

/// Multi-select dialog used to pick albums to add to a collection. Returns the
/// set of selected album IDs, or null when cancelled.
class _AlbumPickerDialog extends StatefulWidget {
  const _AlbumPickerDialog({required this.albums});

  final List<RemoteAlbum> albums;

  @override
  State<_AlbumPickerDialog> createState() => _AlbumPickerDialogState();
}

class _AlbumPickerDialogState extends State<_AlbumPickerDialog> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add albums'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.albums.length,
          itemBuilder: (context, index) {
            final album = widget.albums[index];
            final isSelected = _selected.contains(album.id);
            return CheckboxListTile(
              value: isSelected,
              title: Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selected.add(album.id);
                  } else {
                    _selected.remove(album.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
