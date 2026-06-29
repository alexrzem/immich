import { getAllAlbums, getAllCollections, getCollection } from '@immich/sdk';
import { authenticate } from '$lib/utils/auth';
import type { PageLoad } from './$types';

export const load = (async ({ params, url, depends }) => {
  await authenticate(url);

  depends('collection:data');

  const collection = await getCollection({ id: params.collectionId });
  const collections = await getAllCollections({});
  const albums = await getAllAlbums({ isOwned: true });

  return {
    collection,
    collections,
    albums,
    meta: {
      title: collection.name,
    },
  };
}) satisfies PageLoad;
