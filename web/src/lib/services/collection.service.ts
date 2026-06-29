import {
  addAlbumsToCollection,
  createCollection,
  deleteCollection,
  removeAlbumsFromCollection,
  updateCollection,
  type AlbumResponseDto,
  type CollectionResponseDto,
  type CreateCollectionDto,
  type UpdateCollectionDto,
} from '@immich/sdk';
import { modalManager, toastManager } from '@immich/ui';
import { goto } from '$app/navigation';
import { eventManager } from '$lib/managers/event-manager.svelte';
import CollectionPickerModal from '$lib/modals/CollectionPickerModal.svelte';
import { Route } from '$lib/route';
import { handleError } from '$lib/utils/handle-error';
import { getFormatter } from '$lib/utils/i18n';

export const handleCreateCollection = async (dto: CreateCollectionDto) => {
  const $t = await getFormatter();

  try {
    const collection = await createCollection({ createCollectionDto: dto });
    eventManager.emit('CollectionCreate', collection);
    return collection;
  } catch (error) {
    handleError(error, $t('errors.unable_to_create_collection'));
  }
};

export const handleCreateCollectionAndRedirect = async (dto: CreateCollectionDto) => {
  const collection = await handleCreateCollection(dto);
  if (collection) {
    await goto(Route.viewCollection({ id: collection.id }));
  }
  return collection;
};

export const handleUpdateCollection = async (id: string, dto: UpdateCollectionDto) => {
  const $t = await getFormatter();

  try {
    const collection = await updateCollection({ id, updateCollectionDto: dto });
    eventManager.emit('CollectionUpdate', collection);
    return collection;
  } catch (error) {
    handleError(error, $t('errors.unable_to_update_collection'));
  }
};

export const handleMoveCollection = async (collection: CollectionResponseDto, parentId: string | null) => {
  return handleUpdateCollection(collection.id, { parentId });
};

export const handleDeleteCollection = async (collection: CollectionResponseDto) => {
  const $t = await getFormatter();

  const confirmed = await modalManager.showDialog({
    title: $t('delete_collection'),
    prompt: $t('collection_delete_confirmation', { values: { name: collection.name } }),
    confirmText: $t('delete'),
  });

  if (!confirmed) {
    return false;
  }

  try {
    await deleteCollection({ id: collection.id });
    eventManager.emit('CollectionDelete', collection);
    toastManager.primary($t('collection_deleted'));
    return true;
  } catch (error) {
    handleError(error, $t('errors.unable_to_delete_collection'));
    return false;
  }
};

export const handleAddAlbumsToCollection = async (collectionId: string, albumIds: string[]) => {
  const $t = await getFormatter();

  try {
    await addAlbumsToCollection({ id: collectionId, bulkIdsDto: { ids: albumIds } });
    eventManager.emit('CollectionAlbumsChange', { collectionId });
    toastManager.primary($t('albums_added_to_collection_count', { values: { count: albumIds.length } }));
    return true;
  } catch (error) {
    handleError(error, $t('errors.unable_to_add_albums_to_collection'));
    return false;
  }
};

export const handleAddAlbumToCollection = async (album: AlbumResponseDto) => {
  const $t = await getFormatter();

  const collectionId = await modalManager.show(CollectionPickerModal, { title: $t('add_to_collection') });
  if (!collectionId) {
    return false;
  }

  return handleAddAlbumsToCollection(collectionId, [album.id]);
};

export const handleRemoveAlbumFromCollection = async (collectionId: string, album: AlbumResponseDto) => {
  const $t = await getFormatter();

  const confirmed = await modalManager.showDialog({
    title: $t('remove_from_collection'),
    prompt: $t('album_remove_from_collection_confirmation', { values: { album: album.albumName } }),
    confirmText: $t('remove'),
  });

  if (!confirmed) {
    return false;
  }

  try {
    await removeAlbumsFromCollection({ id: collectionId, bulkIdsDto: { ids: [album.id] } });
    eventManager.emit('CollectionAlbumsChange', { collectionId });
    return true;
  } catch (error) {
    handleError(error, $t('errors.unable_to_remove_album_from_collection'));
    return false;
  }
};
