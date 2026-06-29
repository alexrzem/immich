import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { BulkIdResponseDto, BulkIdsDto } from 'src/dtos/asset-ids.response.dto';
import { AuthDto } from 'src/dtos/auth.dto';
import {
  CollectionResponseDto,
  CreateCollectionDto,
  GetCollectionsDto,
  UpdateCollectionDto,
} from 'src/dtos/collection.dto';
import { Endpoint, HistoryBuilder } from 'src/decorators';
import { ApiTag, Permission } from 'src/enum';
import { Auth, Authenticated } from 'src/middleware/auth.guard';
import { CollectionService } from 'src/services/collection.service';
import { UUIDParamDto } from 'src/validation';

@ApiTags(ApiTag.Collections)
@Controller('collections')
export class CollectionController {
  constructor(private service: CollectionService) {}

  @Get()
  @Authenticated({ permission: Permission.CollectionRead })
  @Endpoint({
    summary: 'List collections',
    description: 'Retrieve the collections owned by the authenticated user. Pass `parentId` to list direct children.',
    history: new HistoryBuilder().added('v3'),
  })
  getAllCollections(@Auth() auth: AuthDto, @Query() query: GetCollectionsDto): Promise<CollectionResponseDto[]> {
    return this.service.getAll(auth, query);
  }

  @Post()
  @Authenticated({ permission: Permission.CollectionCreate })
  @Endpoint({
    summary: 'Create a collection',
    description: 'Create a new collection, optionally nested under a parent collection.',
    history: new HistoryBuilder().added('v3'),
  })
  createCollection(@Auth() auth: AuthDto, @Body() dto: CreateCollectionDto): Promise<CollectionResponseDto> {
    return this.service.create(auth, dto);
  }

  @Get(':id')
  @Authenticated({ permission: Permission.CollectionRead })
  @Endpoint({
    summary: 'Retrieve a collection',
    description: 'Retrieve information about a specific collection by its ID.',
    history: new HistoryBuilder().added('v3'),
  })
  getCollection(@Auth() auth: AuthDto, @Param() { id }: UUIDParamDto): Promise<CollectionResponseDto> {
    return this.service.get(auth, id);
  }

  @Patch(':id')
  @Authenticated({ permission: Permission.CollectionUpdate })
  @Endpoint({
    summary: 'Update a collection',
    description:
      'Update a collection: rename, change description, reorder, set a thumbnail, or move it by setting `parentId` (null moves it to the root).',
    history: new HistoryBuilder().added('v3'),
  })
  updateCollection(
    @Auth() auth: AuthDto,
    @Param() { id }: UUIDParamDto,
    @Body() dto: UpdateCollectionDto,
  ): Promise<CollectionResponseDto> {
    return this.service.update(auth, id, dto);
  }

  @Delete(':id')
  @Authenticated({ permission: Permission.CollectionDelete })
  @HttpCode(HttpStatus.NO_CONTENT)
  @Endpoint({
    summary: 'Delete a collection',
    description:
      'Delete a collection and its sub-collections. Albums contained anywhere in the deleted sub-tree are moved back to the root, never deleted.',
    history: new HistoryBuilder().added('v3'),
  })
  deleteCollection(@Auth() auth: AuthDto, @Param() { id }: UUIDParamDto): Promise<void> {
    return this.service.delete(auth, id);
  }

  @Put(':id/albums')
  @Authenticated({ permission: Permission.CollectionUpdate })
  @Endpoint({
    summary: 'Add albums to a collection',
    description: 'Add one or more albums to a collection. An album can only belong to one collection at a time.',
    history: new HistoryBuilder().added('v3'),
  })
  addAlbumsToCollection(
    @Auth() auth: AuthDto,
    @Param() { id }: UUIDParamDto,
    @Body() dto: BulkIdsDto,
  ): Promise<BulkIdResponseDto[]> {
    return this.service.addAlbums(auth, id, dto);
  }

  @Delete(':id/albums')
  @Authenticated({ permission: Permission.CollectionUpdate })
  @Endpoint({
    summary: 'Remove albums from a collection',
    description: 'Remove one or more albums from a collection, moving them back to the root.',
    history: new HistoryBuilder().added('v3'),
  })
  removeAlbumsFromCollection(
    @Auth() auth: AuthDto,
    @Param() { id }: UUIDParamDto,
    @Body() dto: BulkIdsDto,
  ): Promise<BulkIdResponseDto[]> {
    return this.service.removeAlbums(auth, id, dto);
  }
}
