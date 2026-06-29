import 'package:flutter/material.dart';
import 'package:immich_mobile/domain/models/collection/collection.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/presentation/widgets/images/remote_image_provider.dart';
import 'package:immich_mobile/utils/image_url_builder.dart';

/// A list row representing a single collection: thumbnail, name, and a summary
/// of how many albums and sub-collections it holds. Shared by the root list and
/// the collection detail page.
class CollectionListTile extends StatelessWidget {
  const CollectionListTile({super.key, required this.collection, required this.onTap, this.onLongPress});

  final RemoteCollection collection;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  String _subtitle() {
    final parts = <String>[];
    parts.add(collection.albumCount == 1 ? '1 album' : '${collection.albumCount} albums');
    if (collection.childCount > 0) {
      parts.add(collection.childCount == 1 ? '1 collection' : '${collection.childCount} collections');
    }
    return parts.join('  •  ');
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _CollectionThumbnail(collection: collection),
      title: Text(
        collection.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(_subtitle(), style: context.textTheme.bodyMedium),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _CollectionThumbnail extends StatelessWidget {
  const _CollectionThumbnail({required this.collection});

  final RemoteCollection collection;

  @override
  Widget build(BuildContext context) {
    const double size = 56;
    final thumbnailAssetId = collection.thumbnailAssetId;

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: SizedBox(
        width: size,
        height: size,
        child: thumbnailAssetId != null
            ? Image(
                image: RemoteImageProvider(url: getThumbnailUrlForRemoteId(thumbnailAssetId)),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.colorScheme.surfaceContainerHigh,
      child: Icon(Icons.collections_bookmark_outlined, color: context.primaryColor),
    );
  }
}
