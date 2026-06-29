import {
  AssetMediaResponseDto,
  CollectionResponseDto,
  LoginResponseDto,
  createCollection,
  getAlbumInfo,
  getAllCollections,
  getCollection,
} from '@immich/sdk';
import { createUserDto } from 'src/fixtures';
import { errorDto } from 'src/responses';
import { app, asBearerAuth, utils } from 'src/utils';
import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';

describe('/collections', () => {
  let admin: LoginResponseDto;
  let user1: LoginResponseDto;
  let user2: LoginResponseDto;
  let user1Asset: AssetMediaResponseDto;

  beforeAll(async () => {
    await utils.resetDatabase();
    admin = await utils.adminSetup();
    [user1, user2] = await Promise.all([
      utils.userSetup(admin.accessToken, createUserDto.user1),
      utils.userSetup(admin.accessToken, createUserDto.user2),
    ]);
    user1Asset = await utils.createAsset(user1.accessToken);
  });

  const createCollectionFor = (token: string, dto: { name: string; parentId?: string | null }) =>
    createCollection({ createCollectionDto: dto }, { headers: asBearerAuth(token) });

  describe('authentication', () => {
    it('should require authentication for GET /collections', async () => {
      const { status, body } = await request(app).get('/collections');
      expect(status).toBe(401);
      expect(body).toEqual(errorDto.unauthorized);
    });

    it('should require authentication for POST /collections', async () => {
      const { status, body } = await request(app).post('/collections').send({ name: 'x' });
      expect(status).toBe(401);
      expect(body).toEqual(errorDto.unauthorized);
    });
  });

  describe('CRUD', () => {
    it('creates and retrieves a root collection', async () => {
      const created = await createCollectionFor(user1.accessToken, { name: 'Vacations' });
      expect(created).toMatchObject({
        name: 'Vacations',
        parentId: null,
        ownerId: user1.userId,
        albumCount: 0,
        childCount: 0,
      });

      const fetched = await getCollection({ id: created.id }, { headers: asBearerAuth(user1.accessToken) });
      expect(fetched.id).toBe(created.id);
    });

    it('renames a collection', async () => {
      const created = await createCollectionFor(user1.accessToken, { name: 'Before' });
      const { status, body } = await request(app)
        .patch(`/collections/${created.id}`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({ name: 'After' });
      expect(status).toBe(200);
      expect(body.name).toBe('After');
    });

    it('lists direct children when parentId is provided', async () => {
      const parent = await createCollectionFor(user1.accessToken, { name: 'Parent' });
      const child = await createCollectionFor(user1.accessToken, { name: 'Child', parentId: parent.id });

      const children = await getAllCollections(
        { parentId: parent.id },
        { headers: asBearerAuth(user1.accessToken) },
      );
      expect(children.map((c: CollectionResponseDto) => c.id)).toContain(child.id);
      expect(children.every((c: CollectionResponseDto) => c.parentId === parent.id)).toBe(true);
    });
  });

  describe('tree integrity', () => {
    it('rejects moving a collection into itself', async () => {
      const collection = await createCollectionFor(user1.accessToken, { name: 'Self' });
      const { status } = await request(app)
        .patch(`/collections/${collection.id}`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({ parentId: collection.id });
      expect(status).toBe(400);
    });

    it('rejects moving a collection into its own descendant', async () => {
      const parent = await createCollectionFor(user1.accessToken, { name: 'A' });
      const child = await createCollectionFor(user1.accessToken, { name: 'B', parentId: parent.id });
      const { status } = await request(app)
        .patch(`/collections/${parent.id}`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({ parentId: child.id });
      expect(status).toBe(400);
    });
  });

  describe('albums', () => {
    it('adds and removes albums from a collection', async () => {
      const collection = await createCollectionFor(user1.accessToken, { name: 'WithAlbums' });
      const album = await utils.createAlbum(user1.accessToken, { albumName: 'A1', assetIds: [user1Asset.id] });

      const addRes = await request(app)
        .put(`/collections/${collection.id}/albums`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({ ids: [album.id] });
      expect(addRes.status).toBe(200);
      expect(addRes.body).toEqual([{ id: album.id, success: true }]);

      const albumInfo = await getAlbumInfo({ id: album.id }, { headers: asBearerAuth(user1.accessToken) });
      expect(albumInfo.collectionId).toBe(collection.id);

      const removeRes = await request(app)
        .delete(`/collections/${collection.id}/albums`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({ ids: [album.id] });
      expect(removeRes.status).toBe(200);
      expect(removeRes.body).toEqual([{ id: album.id, success: true }]);

      const afterRemove = await getAlbumInfo({ id: album.id }, { headers: asBearerAuth(user1.accessToken) });
      expect(afterRemove.collectionId).toBeNull();
    });
  });

  describe('delete semantics', () => {
    it('orphans albums to root and removes sub-collections, but never deletes albums', async () => {
      const parent = await createCollectionFor(user1.accessToken, { name: 'Parent' });
      const child = await createCollectionFor(user1.accessToken, { name: 'Child', parentId: parent.id });
      const album = await utils.createAlbum(user1.accessToken, { albumName: 'Kept', assetIds: [user1Asset.id] });

      await request(app)
        .put(`/collections/${child.id}/albums`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({ ids: [album.id] });

      const { status } = await request(app)
        .delete(`/collections/${parent.id}`)
        .set('Authorization', `Bearer ${user1.accessToken}`);
      expect(status).toBe(204);

      // The sub-collection is gone.
      const childRes = await request(app)
        .get(`/collections/${child.id}`)
        .set('Authorization', `Bearer ${user1.accessToken}`);
      expect(childRes.status).toBe(400);

      // The album survives and is back at the root (collectionId === null).
      const albumInfo = await getAlbumInfo({ id: album.id }, { headers: asBearerAuth(user1.accessToken) });
      expect(albumInfo.collectionId).toBeNull();
    });
  });

  describe('cross-user isolation', () => {
    it("prevents a user from reading another user's collection", async () => {
      const collection = await createCollectionFor(user1.accessToken, { name: 'Private' });
      const { status } = await request(app)
        .get(`/collections/${collection.id}`)
        .set('Authorization', `Bearer ${user2.accessToken}`);
      expect(status).toBe(400);
    });

    it("prevents a user from deleting another user's collection", async () => {
      const collection = await createCollectionFor(user1.accessToken, { name: 'Private2' });
      const { status } = await request(app)
        .delete(`/collections/${collection.id}`)
        .set('Authorization', `Bearer ${user2.accessToken}`);
      expect(status).toBe(400);
    });
  });
});
