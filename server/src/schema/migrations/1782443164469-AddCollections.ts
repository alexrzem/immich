import { Kysely, sql } from 'kysely';

export async function up(db: Kysely<any>): Promise<void> {
  await sql`ALTER TABLE "album" ADD "collectionId" uuid;`.execute(db);
  await sql`COMMENT ON COLUMN "album"."collectionId" IS 'Collection the album belongs to, if any';`.execute(db);
  await sql`CREATE INDEX "album_collectionId_idx" ON "album" ("collectionId");`.execute(db);
  await sql`CREATE TABLE "collection" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
  "ownerId" uuid NOT NULL,
  "parentId" uuid,
  "name" character varying NOT NULL,
  "description" text NOT NULL DEFAULT '',
  "thumbnailAssetId" uuid,
  "order" integer NOT NULL DEFAULT 0,
  "createdAt" timestamp with time zone NOT NULL DEFAULT now(),
  "updatedAt" timestamp with time zone NOT NULL DEFAULT now(),
  "updateId" uuid NOT NULL DEFAULT immich_uuid_v7(),
  CONSTRAINT "collection_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "user" ("id") ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT "collection_thumbnailAssetId_fkey" FOREIGN KEY ("thumbnailAssetId") REFERENCES "asset" ("id") ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT "collection_pkey" PRIMARY KEY ("id")
);`.execute(db);
  await sql`COMMENT ON COLUMN "collection"."thumbnailAssetId" IS 'Asset ID to be used as thumbnail';`.execute(db);
  await sql`ALTER TABLE "album" ADD CONSTRAINT "album_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "collection" ("id") ON UPDATE CASCADE ON DELETE SET NULL;`.execute(db);
  await sql`CREATE INDEX "collection_ownerId_idx" ON "collection" ("ownerId");`.execute(db);
  await sql`CREATE INDEX "collection_parentId_idx" ON "collection" ("parentId");`.execute(db);
  await sql`CREATE INDEX "collection_thumbnailAssetId_idx" ON "collection" ("thumbnailAssetId");`.execute(db);
  await sql`CREATE INDEX "collection_updateId_idx" ON "collection" ("updateId");`.execute(db);
  await sql`CREATE OR REPLACE TRIGGER "collection_updatedAt"
  BEFORE UPDATE ON "collection"
  FOR EACH ROW
  EXECUTE FUNCTION updated_at();`.execute(db);
  await sql`ALTER TABLE "collection" ADD CONSTRAINT "collection_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "collection" ("id") ON UPDATE CASCADE ON DELETE CASCADE;`.execute(db);
  await sql`INSERT INTO "migration_overrides" ("name", "value") VALUES ('trigger_collection_updatedAt', '{"type":"trigger","name":"collection_updatedAt","sql":"CREATE OR REPLACE TRIGGER \\"collection_updatedAt\\"\\n  BEFORE UPDATE ON \\"collection\\"\\n  FOR EACH ROW\\n  EXECUTE FUNCTION updated_at();"}'::jsonb);`.execute(db);
}

export async function down(db: Kysely<any>): Promise<void> {
  await sql`ALTER TABLE "album" DROP COLUMN "collectionId";`.execute(db);
  await sql`DROP INDEX "album_collectionId_idx";`.execute(db);
  await sql`ALTER TABLE "album" DROP CONSTRAINT "album_collectionId_fkey";`.execute(db);
  await sql`ALTER TABLE "collection" DROP CONSTRAINT "collection_parentId_fkey";`.execute(db);
  await sql`DROP TABLE "collection";`.execute(db);
  await sql`DROP TRIGGER "collection_updatedAt" ON "collection";`.execute(db);
  await sql`DELETE FROM "migration_overrides" WHERE "name" = 'trigger_collection_updatedAt';`.execute(db);
}
