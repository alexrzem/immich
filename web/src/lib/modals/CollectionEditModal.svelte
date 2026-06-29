<script lang="ts">
  import { handleCreateCollection, handleUpdateCollection } from '$lib/services/collection.service';
  import { type CollectionResponseDto } from '@immich/sdk';
  import { Field, FormModal, Input, Textarea } from '@immich/ui';
  import { mdiFolderPlusOutline, mdiRenameOutline } from '@mdi/js';
  import { t } from 'svelte-i18n';

  type Props = {
    collection?: CollectionResponseDto;
    parentId?: string | null;
    onClose: (collection?: CollectionResponseDto) => void;
  };

  let { collection, parentId = null, onClose }: Props = $props();

  const isEdit = $derived(!!collection);

  let name = $state(collection?.name ?? '');
  let description = $state(collection?.description ?? '');

  const onSubmit = async () => {
    const result = collection
      ? await handleUpdateCollection(collection.id, { name, description })
      : await handleCreateCollection({ name, description, parentId });

    if (result) {
      onClose(result);
    }
  };
</script>

<FormModal
  icon={isEdit ? mdiRenameOutline : mdiFolderPlusOutline}
  title={isEdit ? $t('edit_collection') : $t('create_collection')}
  size="small"
  disabled={name.length === 0}
  {onClose}
  {onSubmit}
>
  <div class="flex flex-col gap-4">
    <Field label={$t('collection_name')}>
      <Input bind:value={name} />
    </Field>

    <Field label={$t('description')}>
      <Textarea bind:value={description} />
    </Field>
  </div>
</FormModal>
