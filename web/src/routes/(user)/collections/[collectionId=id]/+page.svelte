<script lang="ts">
  import CollectionViewer from '$lib/components/collection-page/CollectionViewer.svelte';
  import UserPageLayout from '$lib/components/layouts/UserPageLayout.svelte';
  import type { PageData } from './$types';

  interface Props {
    data: PageData;
  }

  let { data }: Props = $props();
</script>

<UserPageLayout title={data.meta.title}>
  <CollectionViewer collection={data.collection} collections={data.collections} albums={data.albums} />
</UserPageLayout>
