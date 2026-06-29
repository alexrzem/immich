<script lang="ts">
  import { initInput } from '$lib/actions/focus';
  import { getChildCollections } from '$lib/utils/collection-utils';
  import { normalizeSearchString } from '$lib/utils/string-utils';
  import { getAllCollections, type CollectionResponseDto } from '@immich/sdk';
  import { Icon, ListButton, LoadingSpinner, Modal, ModalBody, Text } from '@immich/ui';
  import { mdiFolderHomeOutline, mdiFolderMultipleOutline } from '@mdi/js';
  import { onMount } from 'svelte';
  import { t } from 'svelte-i18n';

  type Props = {
    title: string;
    excludeIds?: Set<string>;
    allowRoot?: boolean;
    // Resolves with the picked collection id, `null` for the root, or `undefined` when cancelled.
    onClose: (result?: string | null) => void;
  };

  let { title, excludeIds = new Set(), allowRoot = false, onClose }: Props = $props();

  let collections: CollectionResponseDto[] = $state([]);
  let loading = $state(true);
  let search = $state('');

  // Flatten the tree in pre-order so nested collections render indented under their parent.
  const flattened = $derived.by(() => {
    const result: { collection: CollectionResponseDto; depth: number }[] = [];
    const visit = (parentId: string | null, depth: number) => {
      for (const collection of getChildCollections(collections, parentId)) {
        result.push({ collection, depth });
        visit(collection.id, depth + 1);
      }
    };
    visit(null, 0);
    return result;
  });

  const normalizedSearch = $derived(normalizeSearchString(search));
  const visibleRows = $derived(
    normalizedSearch
      ? flattened.filter(({ collection }) => normalizeSearchString(collection.name).includes(normalizedSearch))
      : flattened,
  );

  onMount(async () => {
    collections = await getAllCollections({});
    loading = false;
  });
</script>

<Modal {title} {onClose} size="small">
  <ModalBody>
    {#if loading}
      <div class="flex w-full place-content-center place-items-center py-6">
        <LoadingSpinner />
      </div>
    {:else}
      <div class="flex max-h-100 flex-col gap-2">
        <input
          class="border-b-4 border-immich-bg px-6 py-2 text-2xl focus:border-immich-primary dark:border-immich-dark-gray dark:focus:border-immich-dark-primary"
          placeholder={$t('search')}
          bind:value={search}
          use:initInput
        />

        <div class="flex immich-scrollbar flex-col gap-1 overflow-y-auto">
          {#if allowRoot && !normalizedSearch}
            <ListButton onclick={() => onClose(null)}>
              <Icon icon={mdiFolderHomeOutline} size="1.5em" />
              <div class="grow text-start">
                <Text fontWeight="medium">{$t('collections')}</Text>
              </div>
            </ListButton>
          {/if}

          {#each visibleRows as { collection, depth } (collection.id)}
            <ListButton disabled={excludeIds.has(collection.id)} onclick={() => onClose(collection.id)}>
              <span style="width: {depth}rem" aria-hidden="true"></span>
              <Icon icon={mdiFolderMultipleOutline} size="1.5em" />
              <div class="grow text-start">
                <Text fontWeight="medium">{collection.name}</Text>
              </div>
            </ListButton>
          {:else}
            <Text class="py-6">{$t('no_collections_message')}</Text>
          {/each}
        </div>
      </div>
    {/if}
  </ModalBody>
</Modal>
