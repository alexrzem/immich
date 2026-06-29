import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/collection/collection.model.dart';
import 'package:immich_mobile/providers/api.provider.dart';
import 'package:immich_mobile/repositories/api.repository.dart';
// ignore: import_rule_openapi
import 'package:openapi/api.dart';

final driftCollectionApiRepositoryProvider = Provider(
  (ref) => DriftCollectionApiRepository(ref.watch(apiServiceProvider).collectionsApi),
);

/// Result of a bulk album add/remove against a collection.
class CollectionBulkResult {
  final List<String> succeeded;
  final List<String> failed;

  const CollectionBulkResult({required this.succeeded, required this.failed});
}

class DriftCollectionApiRepository extends ApiRepository {
  final CollectionsApi _api;

  DriftCollectionApiRepository(this._api);

  /// Fetches the user's collections. Without [parentId] the full flat list is
  /// returned so the tree can be assembled client-side; pass [parentId] to list
  /// only the direct children of a collection.
  Future<List<RemoteCollection>> getAll({String? parentId}) async {
    final dtos = await checkNull(_api.getAllCollections(parentId: parentId));
    return dtos.map((dto) => dto.toRemoteCollection()).toList();
  }

  Future<RemoteCollection> get(String id) async {
    final dto = await checkNull(_api.getCollection(id));
    return dto.toRemoteCollection();
  }

  Future<RemoteCollection> create({required String name, String? description, String? parentId}) async {
    final dto = await checkNull(
      _api.createCollection(
        CreateCollectionDto(
          name: name,
          description: description == null ? const Optional.absent() : Optional.present(description),
          parentId: parentId == null ? const Optional.absent() : Optional.present(parentId),
        ),
      ),
    );
    return dto.toRemoteCollection();
  }

  /// Updates the editable metadata of a collection. Only non-null arguments are
  /// sent. To move a collection (change its parent), use [move] instead so a
  /// `null` parent can be sent explicitly to mean "move to root".
  Future<RemoteCollection> update(
    String id, {
    String? name,
    String? description,
    String? thumbnailAssetId,
    int? order,
  }) async {
    final dto = await checkNull(
      _api.updateCollection(
        id,
        UpdateCollectionDto(
          name: name == null ? const Optional.absent() : Optional.present(name),
          description: description == null ? const Optional.absent() : Optional.present(description),
          thumbnailAssetId: thumbnailAssetId == null ? const Optional.absent() : Optional.present(thumbnailAssetId),
          order: order == null ? const Optional.absent() : Optional.present(order),
        ),
      ),
    );
    return dto.toRemoteCollection();
  }

  /// Moves a collection under [parentId], or to the root when [parentId] is
  /// null (the null is sent explicitly so the server applies the move).
  Future<RemoteCollection> move(String id, {required String? parentId}) async {
    final dto = await checkNull(
      _api.updateCollection(id, UpdateCollectionDto(parentId: Optional.present(parentId))),
    );
    return dto.toRemoteCollection();
  }

  Future<void> delete(String id) {
    return _api.deleteCollection(id);
  }

  Future<CollectionBulkResult> addAlbums(String id, Iterable<String> albumIds) async {
    final response = await checkNull(_api.addAlbumsToCollection(id, BulkIdsDto(ids: albumIds.toList())));
    return _splitBulkResponse(response);
  }

  Future<CollectionBulkResult> removeAlbums(String id, Iterable<String> albumIds) async {
    final response = await checkNull(_api.removeAlbumsFromCollection(id, BulkIdsDto(ids: albumIds.toList())));
    return _splitBulkResponse(response);
  }

  CollectionBulkResult _splitBulkResponse(List<BulkIdResponseDto> response) {
    final List<String> succeeded = [], failed = [];
    for (final dto in response) {
      if (dto.success) {
        succeeded.add(dto.id);
      } else {
        failed.add(dto.id);
      }
    }
    return CollectionBulkResult(succeeded: succeeded, failed: failed);
  }
}

extension on CollectionResponseDto {
  RemoteCollection toRemoteCollection() {
    return RemoteCollection(
      id: id,
      ownerId: ownerId,
      parentId: parentId,
      name: name,
      description: description,
      thumbnailAssetId: thumbnailAssetId,
      order: order,
      createdAt: createdAt,
      updatedAt: updatedAt,
      albumCount: albumCount,
      childCount: childCount,
      albumIds: albumIds,
    );
  }
}
