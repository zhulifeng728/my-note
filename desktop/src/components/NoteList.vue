<template>
  <div class="bg-white border-r border-gray-200 flex flex-col">
    <div class="p-3 border-b border-gray-200">
      <input
        v-model="searchQuery"
        @input="handleSearch"
        type="text"
        placeholder="搜索笔记..."
        class="w-full px-3 py-2 border border-gray-300 rounded text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
    </div>
    <div class="flex-1 overflow-y-auto">
      <div
        v-for="note in store.filteredNotes"
        :key="note.id"
        @click="store.currentNoteId = note.id"
        :class="[
          'p-3 border-b border-gray-100 cursor-pointer hover:bg-gray-50',
          store.currentNoteId === note.id ? 'bg-blue-50' : ''
        ]"
      >
        <div class="font-medium text-sm truncate">{{ note.title || '未命名' }}</div>
        <div class="text-xs text-gray-500 truncate mt-1">{{ note.content.slice(0, 50) }}</div>
        <div class="text-xs text-gray-400 mt-1">
          {{ new Date(note.updated_at).toLocaleDateString() }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useNotesStore } from '../stores/notes'

const store = useNotesStore()
const searchQuery = ref('')

function handleSearch() {
  store.searchNotes(searchQuery.value)
}
</script>
