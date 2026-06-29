import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/collection/collection.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/theme_extensions.dart';
import 'package:immich_mobile/presentation/widgets/collection/collection_list_tile.widget.dart';
import 'package:immich_mobile/providers/infrastructure/collection.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/widgets/common/immich_sliver_app_bar.dart';

@RoutePage()
class DriftCollectionsPage extends ConsumerStatefulWidget {
  const DriftCollectionsPage({super.key});

  @override
  ConsumerState<DriftCollectionsPage> createState() => _DriftCollectionsPageState();
}

class _DriftCollectionsPageState extends ConsumerState<DriftCollectionsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch on first open; the tab also refreshes when re-selected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remoteCollectionProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref.read(remoteCollectionProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final roots = ref.watch(remoteCollectionProvider.select((state) => state.roots));
    final isLoading = ref.watch(remoteCollectionProvider.select((state) => state.isLoading));

    return RefreshIndicator(
      onRefresh: _onRefresh,
      edgeOffset: 100,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ImmichSliverAppBar(
            snap: false,
            floating: false,
            pinned: true,
            showUploadButton: false,
            actions: [
              IconButton(
                onPressed: () => context.pushRoute(DriftCreateCollectionRoute()),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (roots.isEmpty && !isLoading)
            const SliverFillRemaining(hasScrollBody: false, child: _EmptyCollections())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final collection = roots[index];
                return CollectionListTile(
                  collection: collection,
                  onTap: () => context.pushRoute(DriftCollectionRoute(collection: collection)),
                );
              }, childCount: roots.length),
            ),
        ],
      ),
    );
  }
}

class _EmptyCollections extends StatelessWidget {
  const _EmptyCollections();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.collections_bookmark_outlined, size: 64, color: context.colorScheme.onSurfaceSecondary),
            const SizedBox(height: 16),
            Text(
              'No collections yet',
              style: context.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a collection to organize your albums into a hierarchy.',
              style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
