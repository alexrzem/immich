<script lang="ts">
  import { goto, invalidate } from '$app/navigation';
  import AlbumCard from '$lib/components/album-page/AlbumCard.svelte';
  import CollectionBreadcrumbs from '$lib/components/collection-page/CollectionBreadcrumbs.svelte';
  import CollectionCard from '$lib/components/collection-page/CollectionCard.svelte';
  import OnEvents from '$lib/components/OnEvents.svelte';
  import EmptyPlaceholder from '$lib/components/shared-components/EmptyPlaceholder.svelte';
  import MenuOption from '$lib/components/shared-components/context-menu/MenuOption.svelte';
  import RightClickContextMenu from '$lib/components/shared-components/context-menu/RightClickContextMenu.svelte';
  import AlbumPickerModal from '$lib/modals/AlbumPickerModal.svelte';
  import CollectionEditModal from '$lib/modals/CollectionEditModal.svelte';
  import CollectionPickerModal from '$lib/modals/CollectionPickerModal.svelte';
  import { Route } from '$lib/route';
  import {
    handleAddAlbumsToCollection,
    handleDeleteCollection,
    handleMoveCollection,
    handleRemoveAlbumFromCollection,
    handleUpdateCollection,
  } from '$lib/services/collection.service';
  import { getCollectionAncestors, getChildCollections, getCollectionSubtreeIds } from '$lib/utils/collection-utils';
  import type { ContextMenuPosition } from '$lib/utils/context-menu';
  import { type AlbumResponseDto, type CollectionResponseDto } from '@immich/sdk';
  import { Button, modalManager } from '@immich/ui';
  import {
    mdiCog,
    mdiDeleteOutline,
    mdiFolderMoveOutline,
    mdiFolderPlusOutline,
    mdiImageEditOutline,
    mdiImagePlusOutline,
    mdiRenameOutline,
  } from '@mdi/js';
  import { t } from 'svelte-i18n';

  interface Props {
    collection: CollectionResponseDto | null;
    collections: CollectionResponseDto[];
    albums: AlbumResponseDto[];
  }

  let { collection, collections, albums }: Props = $props();

  const currentId = $derived(collection?.id ?? null);
  const ancestors = $derived(collection ? getCollectionAncestors(collections, collection) : []);
  const childCollections = $derived(getChildCollections(collections, currentId));
  const collectionAlbums = $derived(
    collection
      ? albums
          .filter((album) => album.collectionId === collection.id)
          .sort((a, b) => a.albumName.localeCompare(b.albumName))
      : [],
  );

  const reload = () => invalidate('collection:data');

  // Collection context menu
  let collectionMenuOpen = $state(false);
  let collectionMenuPosition: ContextMenuPosition = $state({ x: 0, y: 0 });
  let selectedCollection: CollectionResponseDto | undefined = $state();

  // Album context menu
  let albumMenuOpen = $state(false);
  let albumMenuPosition: ContextMenuPosition = $state({ x: 0, y: 0 });
  let selectedAlbum: AlbumResponseDto | undefined = $state();

  const showCollectionMenu = (position: ContextMenuPosition, target: CollectionResponseDto) => {
    selectedCollection = target;
    collectionMenuPosition = position;
    collectionMenuOpen = true;
  };

  const showAlbumMenu = (position: ContextMenuPosition, album: AlbumResponseDto) => {
    selectedAlbum = album;
    albumMenuPosition = position;
    albumMenuOpen = true;
  };

  const handleCreate = () => modalManager.show(CollectionEditModal, { parentId: currentId });

  const handleRename = (target: CollectionResponseDto) =>
    modalManager.show(CollectionEditModal, { collection: target });

  const handleMove = async (target: CollectionResponseDto) => {
    const destinationId = await modalManager.show(CollectionPickerModal, {
      title: $t('move_to_collection'),
      excludeIds: getCollectionSubtreeIds(collections, target.id),
      allowRoot: true,
    });

    if (destinationId !== undefined && destinationId !== target.parentId) {
      await handleMoveCollection(target, destinationId);
    }
  };

  const handleDelete = (target: CollectionResponseDto) => handleDeleteCollection(target);

  const handleAddAlbums = async () => {
    if (!collection) {
      return;
    }

    const selectedAlbums = await modalManager.show(AlbumPickerModal);
    if (selectedAlbums && selectedAlbums.length > 0) {
      await handleAddAlbumsToCollection(
        collection.id,
        selectedAlbums.map(({ id }) => id),
      );
    }
  };

  const handleRemoveAlbum = (album: AlbumResponseDto) => {
    if (collection) {
      void handleRemoveAlbumFromCollection(collection.id, album);
    }
  };

  const handleSetCover = (album: AlbumResponseDto) => {
    if (collection && album.albumThumbnailAssetId) {
      void handleUpdateCollection(collection.id, { thumbnailAssetId: album.albumThumbnailAssetId });
    }
  };

  const onCollectionDelete = async (deleted: CollectionResponseDto) => {
    if (deleted.id === currentId) {
      const parent = ancestors.at(-1);
      await goto(parent ? Route.viewCollection({ id: parent.id }) : Route.collections());
      return;
    }
    await reload();
  };

  const isEmpty = $derived(childCollections.length === 0 && collectionAlbums.length === 0);
</script>

<OnEvents
  onCollectionCreate={reload}
  onCollectionUpdate={reload}
  {onCollectionDelete}
  onCollectionAlbumsChange={reload}
/>

<div class="flex items-center justify-between gap-2">
  <CollectionBreadcrumbs {collection} {ancestors} />

  <div class="flex shrink-0 place-items-center gap-2">
    {#if collection}
      <Button
        size="small"
        variant="ghost"
        color="secondary"
        leadingIcon={mdiImagePlusOutline}
        onclick={handleAddAlbums}
      >
        {$t('add_to_collection')}
      </Button>
      <Button
        size="small"
        variant="ghost"
        color="secondary"
        leadingIcon={mdiCog}
        onclick={() => handleRename(collection)}
      >
        {$t('edit_collection')}
      </Button>
    {/if}
    <Button size="small" leadingIcon={mdiFolderPlusOutline} onclick={handleCreate}>
      {$t('create_collection')}
    </Button>
  </div>
</div>

{#if isEmpty}
  <EmptyPlaceholder text={$t('no_collections_message')} onClick={handleCreate} class="mx-auto mt-10" />
{:else}
  {#if childCollections.length > 0}
    <div class="mt-4 grid grid-auto-fill-56 gap-y-4">
      {#each childCollections as child, index (child.id)}
        <a
          href={Route.viewCollection({ id: child.id })}
          class="h-fit"
          oncontextmenu={(event) => {
            event.preventDefault();
            showCollectionMenu({ x: event.x, y: event.y }, child);
          }}
        >
          <CollectionCard
            collection={child}
            preload={index < 20}
            onShowContextMenu={(position) => showCollectionMenu(position, child)}
          />
        </a>
      {/each}
    </div>
  {/if}

  {#if collectionAlbums.length > 0}
    <h2 class="mt-6 mb-2 px-5 text-sm font-medium text-gray-500 dark:text-immich-dark-fg">{$t('albums')}</h2>
    <div class="grid grid-auto-fill-56 gap-y-4">
      {#each collectionAlbums as album, index (album.id)}
        <a
          href={Route.viewAlbum(album)}
          class="h-fit"
          oncontextmenu={(event) => {
            event.preventDefault();
            showAlbumMenu({ x: event.x, y: event.y }, album);
          }}
        >
          <AlbumCard
            {album}
            showItemCount
            showDateRange
            preload={index < 20}
            onShowContextMenu={(position) => showAlbumMenu(position, album)}
          />
        </a>
      {/each}
    </div>
  {/if}
{/if}

<RightClickContextMenu
  title={$t('collection_options')}
  {...collectionMenuPosition}
  isOpen={collectionMenuOpen}
  onClose={() => (collectionMenuOpen = false)}
>
  {#if selectedCollection}
    {@const target = selectedCollection}
    <MenuOption icon={mdiRenameOutline} text={$t('edit_collection')} onClick={() => handleRename(target)} />
    <MenuOption icon={mdiFolderMoveOutline} text={$t('move_collection')} onClick={() => handleMove(target)} />
    <MenuOption icon={mdiDeleteOutline} text={$t('delete_collection')} onClick={() => handleDelete(target)} />
  {/if}
</RightClickContextMenu>

<RightClickContextMenu
  title={$t('album_options')}
  {...albumMenuPosition}
  isOpen={albumMenuOpen}
  onClose={() => (albumMenuOpen = false)}
>
  {#if selectedAlbum}
    {@const target = selectedAlbum}
    {#if target.albumThumbnailAssetId}
      <MenuOption
        icon={mdiImageEditOutline}
        text={$t('set_as_collection_cover')}
        onClick={() => handleSetCover(target)}
      />
    {/if}
    <MenuOption icon={mdiDeleteOutline} text={$t('remove_from_collection')} onClick={() => handleRemoveAlbum(target)} />
  {/if}
</RightClickContextMenu>
