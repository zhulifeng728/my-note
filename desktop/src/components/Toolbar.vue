<template>
  <div class="h-12 bg-white border-b border-gray-200 flex items-center justify-between app-drag"
       :class="isMac ? 'pl-20 pr-4' : 'px-4'">
    <div class="flex items-center gap-2 app-no-drag">
      <button
        @click="handleNewNote"
        class="px-3 py-1.5 bg-blue-500 text-white rounded hover:bg-blue-600 text-sm"
      >
        新建笔记
      </button>
      <button
        v-if="store.currentNote"
        @click="handleExport"
        class="px-3 py-1.5 bg-gray-100 text-gray-700 rounded hover:bg-gray-200 text-sm"
      >
        导出
      </button>
    </div>
    <div class="text-sm text-gray-500 app-no-drag">
      笔记应用
    </div>
  </div>
</template>

<script setup lang="ts">
import { useNotesStore } from '../stores/notes'

const store = useNotesStore()
const isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0

async function handleNewNote() {
  await store.createNote('新笔记', '')
}

async function handleExport() {
  if (!store.currentNote) return
  const result = await window.notesAPI.export({
    id: store.currentNote.id,
    format: 'md',
  })
  if (result.success) {
    console.log('导出成功:', result.path)
  }
}
</script>

<style scoped>
.app-drag {
  -webkit-app-region: drag;
}

.app-no-drag {
  -webkit-app-region: no-drag;
}
</style>
