<script lang="ts">
  import { Route } from '$lib/route';
  import { userInteraction } from '$lib/stores/user.svelte';
  import { getAssetMediaUrl } from '$lib/utils';
  import { handleError } from '$lib/utils/handle-error';
  import { getAllCollections } from '@immich/sdk';
  import { t } from 'svelte-i18n';

  let collections = $state(userInteraction.recentCollections);

  const refreshCollections = async () => {
    try {
      const allCollections = await getAllCollections({});
      collections = allCollections.sort((a, b) => (a.updatedAt > b.updatedAt ? -1 : 1)).slice(0, 3);
      userInteraction.recentCollections = collections;
    } catch (error) {
      handleError(error, $t('failed_to_load_assets'));
    }
  };

  $effect(() => {
    if (!userInteraction.recentCollections) {
      void refreshCollections();
    }
  });
</script>

{#each collections as collection (collection.id)}
  <a
    href={Route.viewCollection(collection)}
    title={collection.name}
    class="flex w-full place-items-center justify-between gap-4 rounded-e-full py-3 ps-10 transition-[padding] delay-100 duration-100 hover:cursor-pointer hover:bg-subtle hover:text-immich-primary group-hover:sm:px-10 md:px-10 dark:text-immich-dark-fg dark:hover:bg-immich-dark-gray dark:hover:text-immich-dark-primary"
  >
    <div>
      <div
        class="size-6 rounded-sm bg-gray-200 bg-cover dark:bg-gray-600"
        style={collection.thumbnailAssetId
          ? `background-image:url('${getAssetMediaUrl({ id: collection.thumbnailAssetId })}')`
          : ''}
      ></div>
    </div>
    <div class="grow truncate text-sm font-medium">
      {collection.name}
    </div>
  </a>
{/each}
