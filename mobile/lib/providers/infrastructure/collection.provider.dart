import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/collection/collection.model.dart';
import 'package:immich_mobile/domain/services/remote_collection.service.dart';
import 'package:immich_mobile/repositories/drift_collection_api_repository.dart';
import 'package:logging/logging.dart';

final remoteCollectionServiceProvider = Provider<RemoteCollectionService>(
  (ref) => RemoteCollectionService(ref.watch(driftCollectionApiRepositoryProvider)),
);

class RemoteCollectionState {
  /// Flat list of all of the user's collections, as fetched from the server.
  final List<RemoteCollection> collections;
  final bool isLoading;

  const RemoteCollectionState({required this.collections, this.isLoading = false});

  /// Root collections (no parent), ordered by manual order then name.
  List<RemoteCollection> get roots => childrenOf(null);

  /// Direct children of [parentId] (or root collections when null), ordered by
  /// manual order then name.
  List<RemoteCollection> childrenOf(String? parentId) {
    final children = collections.where((c) => c.parentId == parentId).toList();
    children.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return children;
  }

  RemoteCollection? collectionById(String id) => collections.firstWhereOrNull((c) => c.id == id);

  RemoteCollectionState copyWith({List<RemoteCollection>? collections, bool? isLoading}) {
    return RemoteCollectionState(
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() => 'RemoteCollectionState(collections: ${collections.length}, isLoading: $isLoading)';

  @override
  bool operator ==(covariant RemoteCollectionState other) {
    if (identical(this, other)) {
      return true;
    }
    final listEquals = const DeepCollectionEquality().equals;
    return listEquals(other.collections, collections) && other.isLoading == isLoading;
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(collections) ^ isLoading.hashCode;
}

class RemoteCollectionNotifier extends Notifier<RemoteCollectionState> {
  late RemoteCollectionService _service;
  final _logger = Logger('RemoteCollectionNotifier');

  @override
  RemoteCollectionState build() {
    _service = ref.read(remoteCollectionServiceProvider);
    return const RemoteCollectionState(collections: []);
  }

  /// Re-fetches the full collection list from the server. Mutations below call
  /// this so cached album/child counts stay accurate.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final collections = await _service.getAll();
      state = RemoteCollectionState(collections: collections, isLoading: false);
    } catch (error, stack) {
      _logger.severe('Failed to fetch collections', error, stack);
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<RemoteCollection?> createCollection({
    required String name,
    String? description,
    String? parentId,
  }) async {
    try {
      final collection = await _service.create(name: name, description: description, parentId: parentId);
      await refresh();
      return collection;
    } catch (error, stack) {
      _logger.severe('Failed to create collection', error, stack);
      rethrow;
    }
  }

  Future<RemoteCollection?> updateCollection(
    String id, {
    String? name,
    String? description,
    String? thumbnailAssetId,
    int? order,
  }) async {
    try {
      final updated = await _service.update(
        id,
        name: name,
        description: description,
        thumbnailAssetId: thumbnailAssetId,
        order: order,
      );
      _replaceInState(updated);
      return updated;
    } catch (error, stack) {
      _logger.severe('Failed to update collection', error, stack);
      rethrow;
    }
  }

  /// Moves [id] under [parentId] (or to the root when null), then refreshes so
  /// counts on both the old and new parent are correct.
  Future<RemoteCollection?> moveCollection(String id, {required String? parentId}) async {
    try {
      final moved = await _service.move(id, parentId: parentId);
      await refresh();
      return moved;
    } catch (error, stack) {
      _logger.severe('Failed to move collection', error, stack);
      rethrow;
    }
  }

  Future<void> deleteCollection(String id) async {
    try {
      await _service.delete(id);
      await refresh();
    } catch (error, stack) {
      _logger.severe('Failed to delete collection', error, stack);
      rethrow;
    }
  }

  Future<int> addAlbums(String id, List<String> albumIds) async {
    final result = await _service.addAlbums(id, albumIds);
    if (result.succeeded.isNotEmpty) {
      await refresh();
    }
    return result.succeeded.length;
  }

  Future<int> removeAlbums(String id, List<String> albumIds) async {
    final result = await _service.removeAlbums(id, albumIds);
    if (result.succeeded.isNotEmpty) {
      await refresh();
    }
    return result.succeeded.length;
  }

  void _replaceInState(RemoteCollection updated) {
    state = state.copyWith(
      collections: state.collections.map((c) => c.id == updated.id ? updated : c).toList(),
    );
  }
}

final remoteCollectionProvider = NotifierProvider<RemoteCollectionNotifier, RemoteCollectionState>(
  RemoteCollectionNotifier.new,
);
