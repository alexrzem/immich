<script lang="ts">
  import CollectionCover from '$lib/components/collection-page/CollectionCover.svelte';
  import { getContextMenuPositionFromEvent, type ContextMenuPosition } from '$lib/utils/context-menu';
  import { type CollectionResponseDto } from '@immich/sdk';
  import { IconButton } from '@immich/ui';
  import { mdiDotsVertical } from '@mdi/js';
  import { t } from 'svelte-i18n';

  interface Props {
    collection: CollectionResponseDto;
    preload?: boolean;
    onShowContextMenu?: ((position: ContextMenuPosition) => unknown) | undefined;
  }

  let { collection, preload = false, onShowContextMenu }: Props = $props();

  const showContextMenu = (e: MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    onShowContextMenu?.(getContextMenuPositionFromEvent(e));
  };
</script>

<div
  class="group relative rounded-2xl border border-transparent p-5 hover:border-gray-200 hover:bg-gray-100 dark:hover:border-gray-800 dark:hover:bg-gray-900"
  data-testid="collection-card"
>
  {#if onShowContextMenu}
    <div
      id="icon-{collection.id}"
      class="absolute inset-e-6 top-6 opacity-0 group-hover:opacity-100 focus-within:opacity-100"
      data-testid="context-button-parent"
    >
      <IconButton
        color="secondary"
        aria-label={$t('show_collection_options')}
        icon={mdiDotsVertical}
        shape="round"
        variant="filled"
        size="medium"
        class="icon-white-drop-shadow"
        onclick={showContextMenu}
      />
    </div>
  {/if}

  <CollectionCover {collection} {preload} class="transition-all duration-300 hover:shadow-lg" />

  <div class="mt-4">
    <p
      class="line-clamp-2 w-full text-lg/6 font-semibold text-black group-hover:text-primary dark:text-white"
      data-testid="collection-name"
      title={collection.name}
    >
      {collection.name}
    </p>

    <span class="flex gap-2 text-sm dark:text-immich-dark-fg" data-testid="collection-details">
      {#if collection.childCount > 0}
        <p>{$t('collections_count', { values: { count: collection.childCount } })}</p>
      {/if}
      {#if collection.childCount > 0 && collection.albumCount > 0}
        <p>•</p>
      {/if}
      {#if collection.albumCount > 0}
        <p>{$t('albums_count', { values: { count: collection.albumCount } })}</p>
      {/if}
    </span>
  </div>
</div>
