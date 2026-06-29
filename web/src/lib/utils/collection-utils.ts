import type { CollectionResponseDto } from '@immich/sdk';
import { get } from 'svelte/store';
import { locale } from '$lib/stores/preferences.store';

/**
 * Collections are stored on the server as a flat list. These helpers build the
 * hierarchy client-side from that flat list (see Collections feature).
 */

const sortCollections = (collections: CollectionResponseDto[]) =>
  collections.slice().sort((a, b) => a.order - b.order || a.name.localeCompare(b.name, get(locale)));

/** Direct children of the given parent (null for root collections), sorted. */
export const getChildCollections = (collections: CollectionResponseDto[], parentId: string | null) =>
  sortCollections(collections.filter((collection) => collection.parentId === parentId));

/** Ancestor chain from root down to (but not including) the given collection. */
export const getCollectionAncestors = (
  collections: CollectionResponseDto[],
  collection: CollectionResponseDto,
): CollectionResponseDto[] => {
  const byId = new Map(collections.map((item) => [item.id, item]));
  const ancestors: CollectionResponseDto[] = [];

  let parentId = collection.parentId;
  while (parentId) {
    const parent = byId.get(parentId);
    if (!parent) {
      break;
    }
    ancestors.unshift(parent);
    parentId = parent.parentId;
  }

  return ancestors;
};

/** IDs of the given collection plus all of its descendants. */
export const getCollectionSubtreeIds = (collections: CollectionResponseDto[], id: string): Set<string> => {
  const ids = new Set<string>([id]);
  let changed = true;
  while (changed) {
    changed = false;
    for (const collection of collections) {
      if (collection.parentId && ids.has(collection.parentId) && !ids.has(collection.id)) {
        ids.add(collection.id);
        changed = true;
      }
    }
  }
  return ids;
};
