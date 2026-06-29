import { createZodDto } from 'nestjs-zod';
import { Collection } from 'src/database';
import { MaybeDehydrated } from 'src/types';
import { asDateTimeString } from 'src/utils/date';
import z from 'zod';

const CreateCollectionSchema = z
  .object({
    name: z.string().describe('Collection name'),
    description: z.string().optional().describe('Collection description'),
    parentId: z.uuidv4().nullish().describe('Parent collection ID (omit or null for a root collection)'),
    order: z.int().optional().describe('Manual sort position within the parent'),
  })
  .meta({ id: 'CreateCollectionDto' });

const UpdateCollectionSchema = z
  .object({
    name: z.string().optional().describe('Collection name'),
    description: z.string().optional().describe('Collection description'),
    parentId: z
      .uuidv4()
      .nullable()
      .optional()
      .describe('New parent collection ID. Pass null to move to the root, omit to leave unchanged.'),
    thumbnailAssetId: z.uuidv4().nullable().optional().describe('Collection thumbnail asset ID'),
    order: z.int().optional().describe('Manual sort position within the parent'),
  })
  .meta({ id: 'UpdateCollectionDto' });

const GetCollectionsSchema = z
  .object({
    parentId: z.uuidv4().optional().describe('Only return the direct children of this collection'),
  })
  .meta({ id: 'GetCollectionsDto' });

export const CollectionResponseSchema = z
  .object({
    id: z.uuidv4().describe('Collection ID'),
    ownerId: z.uuidv4().describe('Owner ID'),
    parentId: z.uuidv4().nullable().describe('Parent collection ID'),
    name: z.string().describe('Collection name'),
    description: z.string().describe('Collection description'),
    thumbnailAssetId: z.uuidv4().nullable().describe('Thumbnail asset ID'),
    order: z.int().describe('Manual sort position within the parent'),
    // TODO: use `isoDatetimeToDate` when using `ZodSerializerDto` on the controllers.
    createdAt: z.string().meta({ format: 'date-time' }).describe('Creation date'),
    // TODO: use `isoDatetimeToDate` when using `ZodSerializerDto` on the controllers.
    updatedAt: z.string().meta({ format: 'date-time' }).describe('Last update date'),
    albumCount: z.int().min(0).describe('Number of albums directly in this collection'),
    childCount: z.int().min(0).describe('Number of direct sub-collections'),
    albumIds: z.array(z.uuidv4()).describe('IDs of albums directly in this collection'),
  })
  .meta({ id: 'CollectionResponseDto' });

export class CreateCollectionDto extends createZodDto(CreateCollectionSchema) {}
export class UpdateCollectionDto extends createZodDto(UpdateCollectionSchema) {}
export class GetCollectionsDto extends createZodDto(GetCollectionsSchema) {}
export class CollectionResponseDto extends createZodDto(CollectionResponseSchema) {}

export type MapCollectionDto = {
  entity: MaybeDehydrated<Collection>;
  albumIds?: string[];
  childCount?: number;
};

export const mapCollection = ({ entity, albumIds = [], childCount = 0 }: MapCollectionDto): CollectionResponseDto => {
  return {
    id: entity.id,
    ownerId: entity.ownerId,
    parentId: entity.parentId ?? null,
    name: entity.name,
    description: entity.description,
    thumbnailAssetId: entity.thumbnailAssetId ?? null,
    order: entity.order,
    createdAt: asDateTimeString(entity.createdAt),
    updatedAt: asDateTimeString(entity.updatedAt),
    albumCount: albumIds.length,
    childCount,
    albumIds,
  };
};
