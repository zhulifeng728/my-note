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

    <!-- 右键菜单 -->
    <div
      v-if="showContextMenu"
      class="fixed z-50"
      :style="{ left: menuPosition.x + 'px', top: menuPosition.y + 'px' }"
    >
      <div class="bg-white rounded-lg shadow-lg border border-gray-200 py-1 min-w-[160px]">
        <button
          @click="handleCreateSubfolder"
          class="w-full text-left px-3 py-2 hover:bg-gray-100 text-sm"
        >
          新建子文件夹
        </button>
        <button
          @click="handleRename"
          class="w-full text-left px-3 py-2 hover:bg-gray-100 text-sm"
        >
          重命名
        </button>
        <button
          @click="handleDelete"
          class="w-full text-left px-3 py-2 hover:bg-red-50 text-red-600 text-sm"
        >
          删除
        </button>
      </div>
    </div>

    <!-- 点击其他地方关闭菜单 -->
    <div
      v-if="showContextMenu"
      class="fixed inset-0 z-40"
      @click="showContextMenu = false"
    ></div>

    <!-- 新建子文件夹对话框 -->
    <div v-if="showSubfolderDialog" class="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50" @click="showSubfolderDialog = false">
      <div class="bg-white rounded-lg shadow-xl p-6 min-w-[300px]" @click.stop>
        <h3 class="text-lg font-semibold mb-4">新建子文件夹</h3>
        <input
          v-model="subfolderName"
          @keyup.enter="confirmCreateSubfolder"
          type="text"
          placeholder="文件夹名称"
          class="w-full px-3 py-2 border border-gray-300 rounded mb-4 focus:outline-none focus:ring-2 focus:ring-blue-400"
          autofocus
        />
        <div class="flex gap-2 justify-end">
          <button
            @click="showSubfolderDialog = false"
            class="px-4 py-2 bg-gray-100 rounded hover:bg-gray-200"
          >
            取消
          </button>
          <button
            @click="confirmCreateSubfolder"
            class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          >
            创建
          </button>
        </div>
      </div>
    </div>

    <!-- 重命名对话框 -->
    <div v-if="showRenameDialog" class="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50" @click="showRenameDialog = false">
      <div class="bg-white rounded-lg shadow-xl p-6 min-w-[300px]" @click.stop>
        <h3 class="text-lg font-semibold mb-4">重命名文件夹</h3>
        <input
          v-model="newName"
          @keyup.enter="confirmRename"
          type="text"
          placeholder="新名称"
          class="w-full px-3 py-2 border border-gray-300 rounded mb-4 focus:outline-none focus:ring-2 focus:ring-blue-400"
          autofocus
        />
        <div class="flex gap-2 justify-end">
          <button
            @click="showRenameDialog = false"
            class="px-4 py-2 bg-gray-100 rounded hover:bg-gray-200"
          >
            取消
          </button>
          <button
            @click="confirmRename"
            class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          >
            确定
          </button>
        </div>
      </div>
    </div>

    <!-- 删除确认对话框 -->
    <div v-if="showDeleteDialog" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" @click="showDeleteDialog = false">
      <div class="bg-white rounded-xl shadow-2xl p-6 min-w-[420px] max-w-[500px]" @click.stop>
        <div class="flex items-start gap-3 mb-4">
          <div class="flex-shrink-0 w-10 h-10 rounded-full bg-red-100 flex items-center justify-center">
            <svg class="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
            </svg>
          </div>
          <div class="flex-1">
            <h3 class="text-lg font-semibold text-gray-900 mb-1">删除文件夹</h3>
            <p class="text-sm text-gray-600">
              <span v-if="deleteInfo?.hasSubfolders">
                此文件夹包含 <span class="font-medium text-gray-900">{{ deleteInfo.subfoldersCount }}</span> 个子文件夹和 <span class="font-medium text-gray-900">{{ deleteInfo.noteCount }}</span> 条笔记
              </span>
              <span v-else-if="deleteInfo?.noteCount">
                此文件夹包含 <span class="font-medium text-gray-900">{{ deleteInfo.noteCount }}</span> 条笔记
              </span>
              <span v-else>
                确定要删除这个空文件夹吗？
              </span>
            </p>
          </div>
        </div>

        <div class="space-y-2">
          <button
            v-if="deleteInfo && (deleteInfo.noteCount > 0 || deleteInfo.hasSubfolders)"
            @click="confirmDelete('all')"
            class="w-full px-4 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors text-sm font-medium flex items-center justify-center gap-2"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/>
            </svg>
            保留笔记并删除文件夹
          </button>
          <button
            v-if="deleteInfo && (deleteInfo.noteCount > 0 || deleteInfo.hasSubfolders)"
            @click="confirmDelete(null)"
            class="w-full px-4 py-3 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm font-medium flex items-center justify-center gap-2"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
            </svg>
            永久删除文件夹和所有笔记
          </button>
          <button
            v-if="deleteInfo && deleteInfo.noteCount === 0 && !deleteInfo.hasSubfolders"
            @click="confirmDelete(null)"
            class="w-full px-4 py-3 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm font-medium"
          >
            确认删除
          </button>
          <button
            @click="showDeleteDialog = false"
            class="w-full px-4 py-3 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors text-sm font-medium"
          >
            取消
          </button>
        </div>
      </div>
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
const showContextMenu = ref(false)
const showSubfolderDialog = ref(false)
const showRenameDialog = ref(false)
const showDeleteDialog = ref(false)
const subfolderName = ref('')
const newName = ref('')
const menuPosition = ref({ x: 0, y: 0 })
const deleteInfo = ref<{ noteCount: number; hasSubfolders: boolean; subfoldersCount: number } | null>(null)

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

  // 切换文件夹后，自动选中第一条笔记，如果没有笔记则设为 null
  const firstNote = store.filteredNotes[0]
  store.currentNoteId = firstNote ? firstNote.id : null
}

function toggleExpand() {
  store.toggleFolder(props.folder.id)
}

function handleContextMenu(event: MouseEvent) {
  if (props.folder.id === 'all') return // 不能操作"所有笔记"
  menuPosition.value = { x: event.clientX, y: event.clientY }
  showContextMenu.value = true
}

function handleCreateSubfolder() {
  showContextMenu.value = false
  subfolderName.value = ''
  showSubfolderDialog.value = true
}

function confirmCreateSubfolder() {
  if (subfolderName.value.trim()) {
    store.addFolder(subfolderName.value.trim(), props.folder.id)
    showSubfolderDialog.value = false
  }
}

function handleRename() {
  showContextMenu.value = false
  newName.value = props.folder.name
  showRenameDialog.value = true
}

function confirmRename() {
  if (newName.value.trim() && newName.value !== props.folder.name) {
    store.renameFolder(props.folder.id, newName.value.trim())
    showRenameDialog.value = false
  }
}

async function handleDelete() {
  showContextMenu.value = false
  try {
    const info = await store.deleteFolder(props.folder.id)
    if (info) {
      deleteInfo.value = info
      showDeleteDialog.value = true
    }
  } catch (error) {
    console.error('Failed to check folder:', error)
  }
}

async function confirmDelete(moveToFolderId: string | null) {
  try {
    await store.deleteFolderConfirm(props.folder.id, moveToFolderId)
    showDeleteDialog.value = false
    deleteInfo.value = null
  } catch (error) {
    console.error('Failed to delete folder:', error)
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
