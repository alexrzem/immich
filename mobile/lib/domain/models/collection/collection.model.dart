// Model for a collection stored on the server.
//
// A collection is a user-owned, hierarchical container that holds albums and
// nested sub-collections (no loose assets). This is distinct from the
// read-only filesystem "folder" concept in `lib/models/folder/`.
class RemoteCollection {
  final String id;
  final String ownerId;
  final String? parentId;
  final String name;
  final String description;
  final String? thumbnailAssetId;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Number of albums directly in this collection.
  final int albumCount;

  /// Number of direct sub-collections.
  final int childCount;

  /// IDs of the albums directly in this collection.
  final List<String> albumIds;

  const RemoteCollection({
    required this.id,
    required this.ownerId,
    this.parentId,
    required this.name,
    required this.description,
    this.thumbnailAssetId,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    required this.albumCount,
    required this.childCount,
    this.albumIds = const [],
  });

  @override
  String toString() {
    return '''Collection {
    id: $id,
    ownerId: $ownerId,
    parentId: ${parentId ?? "<root>"},
    name: $name,
    description: $description,
    thumbnailAssetId: ${thumbnailAssetId ?? "<NA>"},
    order: $order,
    createdAt: $createdAt,
    updatedAt: $updatedAt,
    albumCount: $albumCount,
    childCount: $childCount,
    albumIds: $albumIds
 }''';
  }

  @override
  bool operator ==(Object other) {
    if (other is! RemoteCollection) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return id == other.id &&
        ownerId == other.ownerId &&
        parentId == other.parentId &&
        name == other.name &&
        description == other.description &&
        thumbnailAssetId == other.thumbnailAssetId &&
        order == other.order &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        albumCount == other.albumCount &&
        childCount == other.childCount &&
        _listEquals(albumIds, other.albumIds);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ownerId.hashCode ^
        parentId.hashCode ^
        name.hashCode ^
        description.hashCode ^
        thumbnailAssetId.hashCode ^
        order.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        albumCount.hashCode ^
        childCount.hashCode ^
        Object.hashAll(albumIds);
  }

  RemoteCollection copyWith({
    String? id,
    String? ownerId,
    String? parentId,
    String? name,
    String? description,
    String? thumbnailAssetId,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? albumCount,
    int? childCount,
    List<String>? albumIds,
  }) {
    return RemoteCollection(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      description: description ?? this.description,
      thumbnailAssetId: thumbnailAssetId ?? this.thumbnailAssetId,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      albumCount: albumCount ?? this.albumCount,
      childCount: childCount ?? this.childCount,
      albumIds: albumIds ?? this.albumIds,
    );
  }
}

/// A node in the assembled collection tree: a collection together with its
/// direct sub-collection nodes (recursively built).
class CollectionTreeNode {
  final RemoteCollection collection;
  final List<CollectionTreeNode> children;

  const CollectionTreeNode({required this.collection, this.children = const []});
}

/// Assembles a tree (list of root nodes) from a flat list of collections.
///
/// Children are ordered by their manual [RemoteCollection.order] and then by
/// name as a stable tie-breaker. Collections whose parent is missing from the
/// list are treated as roots so nothing is silently dropped.
List<CollectionTreeNode> assembleCollectionTree(List<RemoteCollection> collections) {
  final childrenByParent = <String?, List<RemoteCollection>>{};
  final knownIds = collections.map((c) => c.id).toSet();

  for (final collection in collections) {
    final parentKey = (collection.parentId != null && knownIds.contains(collection.parentId))
        ? collection.parentId
        : null;
    childrenByParent.putIfAbsent(parentKey, () => []).add(collection);
  }

  List<CollectionTreeNode> buildLevel(String? parentId) {
    final level = childrenByParent[parentId] ?? const [];
    final sorted = [...level]..sort(_compareCollections);
    return [
      for (final collection in sorted)
        CollectionTreeNode(collection: collection, children: buildLevel(collection.id)),
    ];
  }

  return buildLevel(null);
}

int _compareCollections(RemoteCollection a, RemoteCollection b) {
  final byOrder = a.order.compareTo(b.order);
  if (byOrder != 0) {
    return byOrder;
  }
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
