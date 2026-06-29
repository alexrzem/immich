<script lang="ts">
  import { scrollMemory } from '$lib/actions/scroll-memory';
  import CollectionViewer from '$lib/components/collection-page/CollectionViewer.svelte';
  import UserPageLayout from '$lib/components/layouts/UserPageLayout.svelte';
  import { Route } from '$lib/route';
  import type { PageData } from './$types';

  interface Props {
    data: PageData;
  }

  let { data }: Props = $props();
</script>

<UserPageLayout title={data.meta.title} use={[[scrollMemory, { routeStartsWith: Route.collections() }]]}>
  <CollectionViewer collection={null} collections={data.collections} albums={data.albums} />
</UserPageLayout>
