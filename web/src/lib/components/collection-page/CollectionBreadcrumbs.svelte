<script lang="ts">
  import { Route } from '$lib/route';
  import { type CollectionResponseDto } from '@immich/sdk';
  import { Icon, IconButton } from '@immich/ui';
  import { mdiArrowUpLeft, mdiChevronRight, mdiFolderMultiple } from '@mdi/js';
  import { t } from 'svelte-i18n';

  interface Props {
    collection: CollectionResponseDto | null;
    ancestors: CollectionResponseDto[];
  }

  const { collection, ancestors }: Props = $props();

  const rootLink = Route.collections();
  const isRoot = $derived(collection === null);
  const parentLink = $derived.by(() => {
    if (!collection) {
      return undefined;
    }
    const parent = ancestors.at(-1);
    return parent ? Route.viewCollection({ id: parent.id }) : rootLink;
  });
</script>

<nav class="flex items-center py-2">
  {#if parentLink}
    <div>
      <IconButton
        shape="round"
        color="secondary"
        variant="ghost"
        icon={mdiArrowUpLeft}
        aria-label={$t('to_parent')}
        href={parentLink}
        class="me-2"
      />
    </div>
  {/if}

  <div
    class="w-full immich-scrollbar overflow-y-auto rounded-2xl border border-gray-100 bg-gray-50 p-2 dark:border-gray-900 dark:bg-immich-dark-gray/50"
  >
    <ol class="flex items-center gap-2">
      <li>
        <IconButton
          shape="round"
          color="secondary"
          variant="ghost"
          icon={mdiFolderMultiple}
          href={rootLink}
          aria-label={$t('collections')}
          size="medium"
          aria-current={isRoot ? 'page' : undefined}
        />
      </li>
      {#each ancestors as ancestor (ancestor.id)}
        <li class="flex items-center gap-2 text-sm text-nowrap text-primary">
          <Icon icon={mdiChevronRight} class="text-gray-500 dark:text-gray-300" size="16" aria-hidden />
          <a class="whitespace-pre-wrap underline hover:font-semibold" href={Route.viewCollection({ id: ancestor.id })}>
            {ancestor.name}
          </a>
        </li>
      {/each}

      {#if collection}
        <li class="flex items-center gap-2 text-sm text-nowrap text-primary">
          <Icon icon={mdiChevronRight} class="text-gray-500 dark:text-gray-300" size="16" aria-hidden />
          <p class="cursor-default whitespace-pre-wrap">{collection.name}</p>
        </li>
      {/if}
    </ol>
  </div>
</nav>
