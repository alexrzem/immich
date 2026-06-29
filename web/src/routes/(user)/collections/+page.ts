import { getAllAlbums, getAllCollections } from '@immich/sdk';
import { authenticate } from '$lib/utils/auth';
import { getFormatter } from '$lib/utils/i18n';
import type { PageLoad } from './$types';

export const load = (async ({ url, depends }) => {
  await authenticate(url);

  depends('collection:data');

  const collections = await getAllCollections({});
  const albums = await getAllAlbums({ isOwned: true });
  const $t = await getFormatter();

  return {
    collections,
    albums,
    meta: {
      title: $t('collections'),
    },
  };
}) satisfies PageLoad;
