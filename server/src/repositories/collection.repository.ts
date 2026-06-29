import { Injectable } from '@nestjs/common';
import { Insertable, Kysely, Updateable } from 'kysely';
import { InjectKysely } from 'nestjs-kysely';
import { columns } from 'src/database';
import { ChunkedArray, DummyValue, GenerateSql } from 'src/decorators';
import { AlbumUserRole } from 'src/enum';
import { LoggingRepository } from 'src/repositories/logging.repository';
import { DB } from 'src/schema';
import { CollectionTable } from 'src/schema/tables/collection.table';

@Injectable()
export class CollectionRepository {
  constructor(
    @InjectKysely() private db: Kysely<DB>,
    private logger: LoggingRepository,
  ) {
    this.logger.setContext(CollectionRepository.name);
  }

  @GenerateSql({ params: [DummyValue.UUID] })
  get(id: string) {
    return this.db.selectFrom('collection').select(columns.collection).where('id', '=', id).executeTakeFirst();
  }

  @GenerateSql({ params: [DummyValue.UUID] })
  getAll(ownerId: string) {
    return this.db
      .selectFrom('collection')
      .select(columns.collection)
      .where('ownerId', '=', ownerId)
      .orderBy('order', 'asc')
      .orderBy('name', 'asc')
      .execute();
  }

  @GenerateSql({ params: [{ ownerId: DummyValue.UUID, name: DummyValue.STRING }] })
  create(collection: Insertable<CollectionTable>) {
    return this.db.insertInto('collection').values(collection).returning(columns.collection).executeTakeFirstOrThrow();
  }

  @GenerateSql({ params: [DummyValue.UUID, { name: DummyValue.STRING }] })
  update(id: string, collection: Updateable<CollectionTable>) {
    return this.db
      .updateTable('collection')
      .set(collection)
      .where('id', '=', id)
      .returning(columns.collection)
      .executeTakeFirstOrThrow();
  }

  @GenerateSql({ params: [DummyValue.UUID] })
  async delete(id: string): Promise<void> {
    // Child collections cascade (FK onDelete: CASCADE); contained albums are orphaned to
    // the root (album.collectionId FK onDelete: SET NULL). Albums are never deleted here.
    await this.db.deleteFrom('collection').where('id', '=', id).execute();
  }

  @GenerateSql({ params: [DummyValue.UUID] })
  async getAlbumIds(collectionId: string): Promise<string[]> {
    const results = await this.db
      .selectFrom('album')
      .select('album.id')
      .where('album.collectionId', '=', collectionId)
      .where('album.deletedAt', 'is', null)
      .execute();
    return results.map(({ id }) => id);
  }

  @GenerateSql({ params: [DummyValue.UUID] })
  async getOwnedAlbumPairs(ownerId: string): Promise<{ id: string; collectionId: string }[]> {
    const results = await this.db
      .selectFrom('album')
      .innerJoin('album_user', 'album_user.albumId', 'album.id')
      .select(['album.id as id', 'album.collectionId as collectionId'])
      .where('album_user.userId', '=', ownerId)
      .where('album_user.role', '=', AlbumUserRole.Owner)
      .where('album.collectionId', 'is not', null)
      .where('album.deletedAt', 'is', null)
      .execute();
    return results.map(({ id, collectionId }) => ({ id, collectionId: collectionId as string }));
  }

  @GenerateSql({ params: [[DummyValue.UUID], DummyValue.UUID, DummyValue.UUID] })
  @ChunkedArray({ paramIndex: 0 })
  async setAlbumCollection(albumIds: string[], collectionId: string | null, ownerId: string): Promise<string[]> {
    if (albumIds.length === 0) {
      return [];
    }

    const results = await this.db
      .updateTable('album')
      .set({ collectionId })
      .from('album_user')
      .whereRef('album_user.albumId', '=', 'album.id')
      .where('album_user.userId', '=', ownerId)
      .where('album_user.role', '=', AlbumUserRole.Owner)
      .where('album.id', 'in', albumIds)
      .where('album.deletedAt', 'is', null)
      .returning('album.id')
      .execute();

    return results.map(({ id }) => id);
  }
}
