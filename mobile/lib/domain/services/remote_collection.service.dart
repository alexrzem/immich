import 'package:immich_mobile/domain/models/collection/collection.model.dart';
import 'package:immich_mobile/repositories/drift_collection_api_repository.dart';

/// Service for the server-backed collections feature.
///
/// Unlike albums, collections are fetched directly from the API and assembled
/// into a tree client-side (see [assembleCollectionTree]); there is no
/// delta-sync / Drift layer involved.
class RemoteCollectionService {
  final DriftCollectionApiRepository _repository;

  const RemoteCollectionService(this._repository);

  /// Returns the full flat list of the user's collections.
  Future<List<RemoteCollection>> getAll() {
    return _repository.getAll();
  }

  Future<RemoteCollection> get(String id) {
    return _repository.get(id);
  }

  Future<RemoteCollection> create({required String name, String? description, String? parentId}) {
    return _repository.create(name: name, description: description, parentId: parentId);
  }

  Future<RemoteCollection> update(
    String id, {
    String? name,
    String? description,
    String? thumbnailAssetId,
    int? order,
  }) {
    return _repository.update(
      id,
      name: name,
      description: description,
      thumbnailAssetId: thumbnailAssetId,
      order: order,
    );
  }

  /// Moves [id] under [parentId], or to the root when [parentId] is null.
  Future<RemoteCollection> move(String id, {required String? parentId}) {
    return _repository.move(id, parentId: parentId);
  }

  Future<void> delete(String id) {
    return _repository.delete(id);
  }

  Future<CollectionBulkResult> addAlbums(String id, Iterable<String> albumIds) {
    return _repository.addAlbums(id, albumIds);
  }

  Future<CollectionBulkResult> removeAlbums(String id, Iterable<String> albumIds) {
    return _repository.removeAlbums(id, albumIds);
  }

  /// Assembles the tree of root nodes from a flat collection list.
  List<CollectionTreeNode> buildTree(List<RemoteCollection> collections) {
    return assembleCollectionTree(collections);
  }
}
