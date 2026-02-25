<template>
  <div>
    <div
      @click="handleClick"
      @contextmenu.prevent="handleContextMenu"
      @dragover.prevent="handleDragOver"
      @dragleave="handleDragLeave"
      @drop="handleDrop"
      :class="[
        'px-2 py-2 rounded cursor-pointer group relative flex items-center gap-2',
        isSelected ? 'bg-blue-100 text-blue-900' : 'hover:bg-gray-200 text-gray-700',
        isDragOver ? 'bg-blue-50 ring-2 ring-blue-400' : ''
      ]"
    >
      <!-- 展开/折叠图标 -->
      <button
        v-if="folder.children && folder.children.length > 0"
        @click.stop="toggleExpand"
        class="w-4 h-4 flex items-center justify-center hover:bg-gray-300 rounded"
      >
        <svg
          class="w-3 h-3 transition-transform"
          :class="isExpanded ? 'rotate-90' : ''"
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"/>
        </svg>
      </button>
      <div v-else class="w-4"></div>

      <!-- 文件夹图标 -->
      <svg class="w-4 h-4 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
        <path d="M2 6a2 2 0 012-2h5l2 2h5a2 2 0 012 2v6a2 2 0 01-2 2H4a2 2 0 01-2-2V6z"/>
      </svg>

      <!-- 文件夹名称 -->
      <span class="text-sm flex-1 truncate text-left">{{ folder.name }}</span>

      <!-- 笔记数量 -->
      <span class="text-xs text-gray-500 flex-shrink-0">
        {{ noteCount }}
      </span>
    </div>

    <!-- 子文件夹 -->
    <div v-if="isExpanded && folder.children && folder.children.length > 0" class="ml-4">
      <FolderTreeItem
        v-for="child in folder.children"
        :key="child.id"
        :folder="child"
        :level="level + 1"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useNotesStore } from '../stores/notes'
import type { FolderTree } from '../types'

const props = defineProps<{
  folder: FolderTree
  level?: number
}>()

const store = useNotesStore()
const isDragOver = ref(false)

const isSelected = computed(() => store.currentFolderId === props.folder.id)
const isExpanded = computed(() => store.expandedFolders.has(props.folder.id))

// 计算笔记数量（包括子文件夹）
const noteCount = computed(() => {
  if (props.folder.id === 'all') {
    return store.notes.length
  }

  let count = store.notes.filter(n => n.folder_id === props.folder.id).length

  // 递归计算子文件夹的笔记数
  function countChildren(folder: FolderTree): number {
    let total = store.notes.filter(n => n.folder_id === folder.id).length
    if (folder.children) {
      folder.children.forEach(child => {
        total += countChildren(child)
      })
    }
    return total
  }

  if (props.folder.children) {
    props.folder.children.forEach(child => {
      count += countChildren(child)
    })
  }

  return count
})

function handleClick() {
  store.currentFolderId = props.folder.id
}

function toggleExpand() {
  store.toggleFolder(props.folder.id)
}

function handleContextMenu(event: MouseEvent) {
  if (props.folder.id === 'all') return // 不能操作"所有笔记"

  const options = [
    '新建子文件夹',
    '重命名',
    '删除'
  ]

  const choice = prompt(`选择操作：\n${options.map((o, i) => `${i + 1}. ${o}`).join('\n')}`)

  if (!choice) return

  const index = parseInt(choice) - 1

  switch (index) {
    case 0: // 新建子文件夹
      const name = prompt('输入文件夹名称：')
      if (name) {
        store.addFolder(name, props.folder.id)
      }
      break
    case 1: // 重命名
      const newName = prompt('输入新名称：', props.folder.name)
      if (newName && newName !== props.folder.name) {
        store.renameFolder(props.folder.id, newName)
      }
      break
    case 2: // 删除
      store.deleteFolder(props.folder.id)
      break
  }
}

// 拖拽处理
function handleDragOver(event: DragEvent) {
  event.preventDefault()
  isDragOver.value = true
}

function handleDragLeave() {
  isDragOver.value = false
}

async function handleDrop(event: DragEvent) {
  event.preventDefault()
  isDragOver.value = false

  const noteId = event.dataTransfer?.getData('noteId')
  if (noteId) {
    await store.moveNoteToFolder(noteId, props.folder.id)
  }
}
</script>
