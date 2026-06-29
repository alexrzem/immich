import { BadRequestException, Injectable } from '@nestjs/common';
import { Collection } from 'src/database';
import { BulkIdErrorReason, BulkIdResponseDto, BulkIdsDto } from 'src/dtos/asset-ids.response.dto';
import { AuthDto } from 'src/dtos/auth.dto';
import {
  CollectionResponseDto,
  CreateCollectionDto,
  GetCollectionsDto,
  UpdateCollectionDto,
  mapCollection,
} from 'src/dtos/collection.dto';
import { Permission } from 'src/enum';
import { BaseService } from 'src/services/base.service';

/** Maximum nesting depth (root collection = depth 0). */
export const COLLECTION_MAX_DEPTH = 32;

@Injectable()
export class CollectionService extends BaseService {
  async getAll(auth: AuthDto, { parentId }: GetCollectionsDto): Promise<CollectionResponseDto[]> {
    const ownerId = auth.user.id;
    const collections = await this.collectionRepository.getAll(ownerId);
    if (collections.length === 0) {
      return [];
    }

    const albumIdsByCollection = await this.getAlbumIdsByCollection(ownerId);
    const childCountByParent = this.getChildCountByParent(collections);

    return collections
      .filter((collection) => (parentId === undefined ? true : collection.parentId === parentId))
      .map((collection) =>
        mapCollection({
          entity: collection,
          albumIds: albumIdsByCollection.get(collection.id) ?? [],
          childCount: childCountByParent.get(collection.id) ?? 0,
        }),
      );
  }

  async get(auth: AuthDto, id: string): Promise<CollectionResponseDto> {
    await this.requireAccess({ auth, permission: Permission.CollectionRead, ids: [id] });
    const collection = await this.findOrFail(id);
    return this.mapWithCounts(auth.user.id, collection);
  }

  async create(auth: AuthDto, dto: CreateCollectionDto): Promise<CollectionResponseDto> {
    const ownerId = auth.user.id;

    if (dto.parentId) {
      await this.requireAccess({ auth, permission: Permission.CollectionRead, ids: [dto.parentId] });
      const parentDepth = await this.getDepth(ownerId, dto.parentId);
      if (parentDepth + 1 >= COLLECTION_MAX_DEPTH) {
        throw new BadRequestException('Maximum collection nesting depth exceeded');
      }
    }

    const collection = await this.collectionRepository.create({
      ownerId,
      parentId: dto.parentId ?? null,
      name: dto.name,
      description: dto.description,
      order: dto.order,
    });

    return mapCollection({ entity: collection, albumIds: [], childCount: 0 });
  }

  async update(auth: AuthDto, id: string, dto: UpdateCollectionDto): Promise<CollectionResponseDto> {
    const ownerId = auth.user.id;
    await this.requireAccess({ auth, permission: Permission.CollectionUpdate, ids: [id] });
    await this.findOrFail(id);

    // `parentId` distinguishes three cases: absent (unchanged), null (move to root), uuid (move).
    if (dto.parentId !== undefined && dto.parentId !== null) {
      if (dto.parentId === id) {
        throw new BadRequestException('A collection cannot be its own parent');
      }
      await this.requireAccess({ auth, permission: Permission.CollectionRead, ids: [dto.parentId] });

      const ancestorIds = await this.getAncestorIds(ownerId, dto.parentId);
      if (ancestorIds.includes(id)) {
        throw new BadRequestException('Cannot move a collection into its own descendant');
      }
      if (ancestorIds.length + 1 >= COLLECTION_MAX_DEPTH) {
        throw new BadRequestException('Maximum collection nesting depth exceeded');
      }
    }

    if (dto.thumbnailAssetId) {
      const allowed = await this.checkAccess({ auth, permission: Permission.AssetView, ids: [dto.thumbnailAssetId] });
      if (allowed.size === 0) {
        throw new BadRequestException('Invalid collection thumbnail');
      }
    }

    const collection = await this.collectionRepository.update(id, {
      name: dto.name,
      description: dto.description,
      parentId: dto.parentId,
      thumbnailAssetId: dto.thumbnailAssetId,
      order: dto.order,
    });

    return this.mapWithCounts(ownerId, collection);
  }

  async delete(auth: AuthDto, id: string): Promise<void> {
    await this.requireAccess({ auth, permission: Permission.CollectionDelete, ids: [id] });
    await this.collectionRepository.delete(id);
  }

  async addAlbums(auth: AuthDto, id: string, dto: BulkIdsDto): Promise<BulkIdResponseDto[]> {
    await this.requireAccess({ auth, permission: Permission.CollectionUpdate, ids: [id] });
    await this.findOrFail(id);

    const updated = new Set(await this.collectionRepository.setAlbumCollection(dto.ids, id, auth.user.id));
    return dto.ids.map((albumId) => this.toBulkResponse(albumId, updated.has(albumId)));
  }

  async removeAlbums(auth: AuthDto, id: string, dto: BulkIdsDto): Promise<BulkIdResponseDto[]> {
    await this.requireAccess({ auth, permission: Permission.CollectionUpdate, ids: [id] });
    await this.findOrFail(id);

    const currentIds = new Set(await this.collectionRepository.getAlbumIds(id));
    const toRemove = dto.ids.filter((albumId) => currentIds.has(albumId));
    const updated = new Set(await this.collectionRepository.setAlbumCollection(toRemove, null, auth.user.id));
    return dto.ids.map((albumId) => this.toBulkResponse(albumId, updated.has(albumId)));
  }

  private toBulkResponse(id: string, success: boolean): BulkIdResponseDto {
    return success ? { id, success: true } : { id, success: false, error: BulkIdErrorReason.NO_PERMISSION };
  }

  private async mapWithCounts(ownerId: string, collection: Collection): Promise<CollectionResponseDto> {
    const [albumIds, all] = await Promise.all([
      this.collectionRepository.getAlbumIds(collection.id),
      this.collectionRepository.getAll(ownerId),
    ]);
    const childCount = all.filter((c) => c.parentId === collection.id).length;
    return mapCollection({ entity: collection, albumIds, childCount });
  }

  private async getAlbumIdsByCollection(ownerId: string): Promise<Map<string, string[]>> {
    const pairs = await this.collectionRepository.getOwnedAlbumPairs(ownerId);
    const map = new Map<string, string[]>();
    for (const { id, collectionId } of pairs) {
      const list = map.get(collectionId) ?? [];
      list.push(id);
      map.set(collectionId, list);
    }
    return map;
  }

  private getChildCountByParent(collections: { parentId: string | null }[]): Map<string, number> {
    const map = new Map<string, number>();
    for (const { parentId } of collections) {
      if (parentId) {
        map.set(parentId, (map.get(parentId) ?? 0) + 1);
      }
    }
    return map;
  }

  /** Walk the parent chain and return the ancestor ids of `id` (excluding `id`). */
  private async getAncestorIds(ownerId: string, id: string): Promise<string[]> {
    const parentById = new Map<string, string | null>(
      (await this.collectionRepository.getAll(ownerId)).map((c) => [c.id, c.parentId]),
    );

    const ancestors: string[] = [];
    let current = parentById.get(id) ?? null;
    while (current && !ancestors.includes(current)) {
      ancestors.push(current);
      current = parentById.get(current) ?? null;
    }
    return ancestors;
  }

  private async getDepth(ownerId: string, id: string): Promise<number> {
    return (await this.getAncestorIds(ownerId, id)).length;
  }

  private async findOrFail(id: string): Promise<Collection> {
    const collection = await this.collectionRepository.get(id);
    if (!collection) {
      throw new BadRequestException('Collection not found');
    }
    return collection;
  }
}
