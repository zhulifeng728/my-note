<template>
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div class="bg-white rounded-lg p-6 max-w-2xl w-full mx-4">
      <h2 class="text-xl font-bold mb-4">同步冲突</h2>
      <p class="text-gray-600 mb-4">检测到笔记冲突，请选择保留哪个版本：</p>

      <div class="grid grid-cols-2 gap-4 mb-6">
        <div class="border border-gray-200 rounded p-4">
          <h3 class="font-medium mb-2">本地版本</h3>
          <div class="text-sm text-gray-600">{{ store.pendingConflict?.local.content.slice(0, 200) }}</div>
        </div>
        <div class="border border-gray-200 rounded p-4">
          <h3 class="font-medium mb-2">远程版本</h3>
          <div class="text-sm text-gray-600">{{ store.pendingConflict?.remote.content.slice(0, 200) }}</div>
        </div>
      </div>

      <div class="flex gap-3 justify-end">
        <button
          @click="handleResolve('local')"
          class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
        >
          保留本地
        </button>
        <button
          @click="handleResolve('remote')"
          class="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
        >
          保留远程
        </button>
        <button
          @click="handleResolve('both')"
          class="px-4 py-2 bg-purple-500 text-white rounded hover:bg-purple-600"
        >
          保留两者
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useNotesStore } from '../stores/notes'

const store = useNotesStore()

async function handleResolve(keep: 'local' | 'remote' | 'both') {
  await store.resolveConflict(keep)
}
</script>
