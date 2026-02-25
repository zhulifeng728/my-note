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
        <div class="text-xs text-gray-500 truncate mt-1">{{ getPreviewText(note.content) }}</div>
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

function getPreviewText(content: string): string {
  if (!content) return '无内容'

  try {
    // 尝试解析 Tiptap JSON 格式
    const json = JSON.parse(content)
    return extractTextFromTiptap(json).slice(0, 50)
  } catch {
    // 如果不是 JSON，直接返回纯文本
    return content.slice(0, 50)
  }
}

function extractTextFromTiptap(node: any): string {
  if (!node) return ''

  if (node.type === 'text') {
    return node.text || ''
  }

  if (node.content && Array.isArray(node.content)) {
    return node.content.map((child: any) => extractTextFromTiptap(child)).join(' ')
  }

  return ''
}
</script>
