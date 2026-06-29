import { BadRequestException } from '@nestjs/common';
import { Collection } from 'src/database';
import { BulkIdErrorReason } from 'src/dtos/asset-ids.response.dto';
import { COLLECTION_MAX_DEPTH, CollectionService } from 'src/services/collection.service';
import { authStub } from 'test/fixtures/auth.stub';
import { newUuid } from 'test/small.factory';
import { newTestService, ServiceMocks } from 'test/utils';

const ownerId = authStub.admin.user.id;

const collectionStub = (overrides: Partial<Collection> = {}): Collection => ({
  id: newUuid(),
  ownerId,
  parentId: null,
  name: 'My Collection',
  description: '',
  thumbnailAssetId: null,
  order: 0,
  createdAt: new Date(),
  updatedAt: new Date(),
  ...overrides,
});

describe(CollectionService.name, () => {
  let sut: CollectionService;
  let mocks: ServiceMocks;

  beforeEach(() => {
    ({ sut, mocks } = newTestService(CollectionService));
  });

  it('should work', () => {
    expect(sut).toBeDefined();
  });

  describe('getAll', () => {
    it('returns an empty list when the user has no collections', async () => {
      mocks.collection.getAll.mockResolvedValue([]);
      await expect(sut.getAll(authStub.admin, {})).resolves.toEqual([]);
    });

    it('computes albumCount, childCount and albumIds, and assembles a flat list', async () => {
      const root = collectionStub();
      const child = collectionStub({ parentId: root.id });
      mocks.collection.getAll.mockResolvedValue([root, child]);
      mocks.collection.getOwnedAlbumPairs.mockResolvedValue([
        { id: 'album-1', collectionId: root.id },
        { id: 'album-2', collectionId: root.id },
      ]);

      const result = await sut.getAll(authStub.admin, {});

      expect(result).toHaveLength(2);
      const mappedRoot = result.find((c) => c.id === root.id)!;
      expect(mappedRoot.albumCount).toBe(2);
      expect(mappedRoot.albumIds).toEqual(['album-1', 'album-2']);
      expect(mappedRoot.childCount).toBe(1);

      const mappedChild = result.find((c) => c.id === child.id)!;
      expect(mappedChild.albumCount).toBe(0);
      expect(mappedChild.childCount).toBe(0);
    });

    it('filters to direct children when parentId is provided', async () => {
      const root = collectionStub();
      const child = collectionStub({ parentId: root.id });
      mocks.collection.getAll.mockResolvedValue([root, child]);
      mocks.collection.getOwnedAlbumPairs.mockResolvedValue([]);

      const result = await sut.getAll(authStub.admin, { parentId: root.id });

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe(child.id);
    });
  });

  describe('get', () => {
    it('throws when access is not allowed', async () => {
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set());
      await expect(sut.get(authStub.admin, 'collection-1')).rejects.toBeInstanceOf(BadRequestException);
      expect(mocks.collection.get).not.toHaveBeenCalled();
    });

    it('throws when the collection does not exist', async () => {
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set(['collection-1']));
      mocks.collection.get.mockResolvedValue(undefined);
      await expect(sut.get(authStub.admin, 'collection-1')).rejects.toBeInstanceOf(BadRequestException);
    });

    it('returns the mapped collection with counts', async () => {
      const collection = collectionStub();
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set([collection.id]));
      mocks.collection.get.mockResolvedValue(collection);
      mocks.collection.getAlbumIds.mockResolvedValue(['album-1']);
      mocks.collection.getAll.mockResolvedValue([collection]);

      const result = await sut.get(authStub.admin, collection.id);
      expect(result.id).toBe(collection.id);
      expect(result.albumIds).toEqual(['album-1']);
      expect(result.albumCount).toBe(1);
      expect(result.childCount).toBe(0);
    });
  });

  describe('create', () => {
    it('creates a root collection', async () => {
      const created = collectionStub({ name: 'New' });
      mocks.collection.create.mockResolvedValue(created);

      const result = await sut.create(authStub.admin, { name: 'New' });
      expect(result.name).toBe('New');
      expect(mocks.collection.create).toHaveBeenCalledWith(
        expect.objectContaining({ ownerId, parentId: null, name: 'New' }),
      );
    });

    it('creates a nested collection after checking parent access', async () => {
      const parent = collectionStub();
      const created = collectionStub({ parentId: parent.id });
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set([parent.id]));
      mocks.collection.getAll.mockResolvedValue([parent]);
      mocks.collection.create.mockResolvedValue(created);

      const result = await sut.create(authStub.admin, { name: 'Child', parentId: parent.id });
      expect(result.parentId).toBe(parent.id);
      expect(mocks.access.collection.checkOwnerAccess).toHaveBeenCalledWith(ownerId, new Set([parent.id]));
    });

    it('rejects creating beyond the maximum nesting depth', async () => {
      // Build a chain of COLLECTION_MAX_DEPTH ancestors so a new child would exceed the cap.
      const chain: Collection[] = [];
      let parentId: string | null = null;
      for (let i = 0; i < COLLECTION_MAX_DEPTH; i++) {
        const node = collectionStub({ parentId });
        chain.push(node);
        parentId = node.id;
      }
      const deepestParent = chain.at(-1)!;
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set([deepestParent.id]));
      mocks.collection.getAll.mockResolvedValue(chain);

      await expect(
        sut.create(authStub.admin, { name: 'TooDeep', parentId: deepestParent.id }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(mocks.collection.create).not.toHaveBeenCalled();
    });
  });

  describe('update', () => {
    it('renames a collection', async () => {
      const collection = collectionStub();
      const updated = { ...collection, name: 'Renamed' };
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set([collection.id]));
      mocks.collection.get.mockResolvedValue(collection);
      mocks.collection.update.mockResolvedValue(updated);
      mocks.collection.getAlbumIds.mockResolvedValue([]);
      mocks.collection.getAll.mockResolvedValue([updated]);

      const result = await sut.update(authStub.admin, collection.id, { name: 'Renamed' });
      expect(result.name).toBe('Renamed');
    });

    it('rejects moving a collection into itself', async () => {
      const collection = collectionStub();
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set([collection.id]));
      mocks.collection.get.mockResolvedValue(collection);

      await expect(
        sut.update(authStub.admin, collection.id, { parentId: collection.id }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(mocks.collection.update).not.toHaveBeenCalled();
    });

    it('rejects moving a collection into one of its descendants', async () => {
      const root = collectionStub();
      const child = collectionStub({ parentId: root.id });
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set([root.id, child.id]));
      mocks.collection.get.mockResolvedValue(root);
      mocks.collection.getAll.mockResolvedValue([root, child]);

      await expect(
        sut.update(authStub.admin, root.id, { parentId: child.id }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(mocks.collection.update).not.toHaveBeenCalled();
    });

    it('validates the thumbnail asset access', async () => {
      const collection = collectionStub();
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set([collection.id]));
      mocks.collection.get.mockResolvedValue(collection);
      mocks.access.asset.checkOwnerAccess.mockResolvedValue(new Set());

      await expect(
        sut.update(authStub.admin, collection.id, { thumbnailAssetId: newUuid() }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('delete', () => {
    it('throws when access is not allowed', async () => {
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set());
      await expect(sut.delete(authStub.admin, 'collection-1')).rejects.toBeInstanceOf(BadRequestException);
      expect(mocks.collection.delete).not.toHaveBeenCalled();
    });

    it('deletes the collection', async () => {
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set(['collection-1']));
      await sut.delete(authStub.admin, 'collection-1');
      expect(mocks.collection.delete).toHaveBeenCalledWith('collection-1');
    });
  });

  describe('addAlbums', () => {
    it('maps updated albums to success and the rest to no-permission', async () => {
      const collection = collectionStub();
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set([collection.id]));
      mocks.collection.get.mockResolvedValue(collection);
      mocks.collection.setAlbumCollection.mockResolvedValue(['album-1']);

      const result = await sut.addAlbums(authStub.admin, collection.id, { ids: ['album-1', 'album-2'] });
      expect(result).toEqual([
        { id: 'album-1', success: true },
        { id: 'album-2', success: false, error: BulkIdErrorReason.NO_PERMISSION },
      ]);
      expect(mocks.collection.setAlbumCollection).toHaveBeenCalledWith(['album-1', 'album-2'], collection.id, ownerId);
    });
  });

  describe('removeAlbums', () => {
    it('only removes albums currently in the collection', async () => {
      const collection = collectionStub();
      mocks.access.collection.checkOwnerAccess.mockResolvedValue(new Set([collection.id]));
      mocks.collection.get.mockResolvedValue(collection);
      mocks.collection.getAlbumIds.mockResolvedValue(['album-1']);
      mocks.collection.setAlbumCollection.mockResolvedValue(['album-1']);

      const result = await sut.removeAlbums(authStub.admin, collection.id, { ids: ['album-1', 'album-2'] });
      expect(result).toEqual([
        { id: 'album-1', success: true },
        { id: 'album-2', success: false, error: BulkIdErrorReason.NO_PERMISSION },
      ]);
      // album-2 is not in the collection, so only album-1 is passed to the repository.
      expect(mocks.collection.setAlbumCollection).toHaveBeenCalledWith(['album-1'], null, ownerId);
    });
  });
});
