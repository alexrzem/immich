<script lang="ts">
  import AssetCover from '$lib/components/sharedlinks-page/covers/AssetCover.svelte';
  import { getAssetMediaUrl } from '$lib/utils';
  import { type CollectionResponseDto } from '@immich/sdk';
  import { Icon } from '@immich/ui';
  import { mdiFolderMultipleOutline } from '@mdi/js';

  interface Props {
    collection: CollectionResponseDto;
    preload?: boolean;
    class?: string;
  }

  let { collection, preload = false, class: className }: Props = $props();

  let thumbnailUrl = $derived(
    collection.thumbnailAssetId ? getAssetMediaUrl({ id: collection.thumbnailAssetId }) : null,
  );
</script>

{#if thumbnailUrl}
  <AssetCover alt={collection.name} class={className} src={thumbnailUrl} {preload} />
{:else}
  <div
    class="flex aspect-square size-full place-content-center place-items-center rounded-xl bg-gray-100 text-gray-400 dark:bg-immich-dark-gray dark:text-gray-500 {className}"
  >
    <Icon icon={mdiFolderMultipleOutline} size="33%" />
  </div>
{/if}
