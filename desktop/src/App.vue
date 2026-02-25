<template>
  <div class="flex h-screen bg-gray-100">
    <!-- 左侧边栏：文件夹 -->
    <div :style="{ width: sidebarWidth + 'px' }" class="bg-gray-50 border-r border-gray-200 flex flex-col relative">
      <!-- 标题栏 - 为 macOS 流量灯按钮留空间 -->
      <div class="h-12 flex items-center border-b border-gray-200 app-drag flex-shrink-0"
           :class="isFullscreen ? 'pl-3' : (isMac ? 'pl-20' : 'pl-3')">
        <span class="text-sm font-semibold text-gray-700 flex-1">文件夹</span>
        <button
          @click="showNewFolderDialog = true"
          class="app-no-drag p-1 hover:bg-gray-200 rounded mr-3"
          title="新建文件夹"
        >
          <svg class="w-4 h-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
        </button>
      </div>

      <div class="flex-1 overflow-y-auto py-2">
        <div class="px-2 space-y-1">
          <FolderTreeItem
            v-for="folder in store.folders"
            :key="folder.id"
            :folder="folder"
            :level="0"
          />
        </div>
      </div>

      <!-- 同步状态 - 左下角 -->
      <div class="border-t border-gray-200 p-2 flex-shrink-0">
        <button
          @click="showPairingCode"
          class="w-full flex items-center gap-2 px-2 py-1.5 hover:bg-gray-100 rounded text-xs text-gray-600 transition-colors"
        >
          <div :class="[
            'w-1.5 h-1.5 rounded-full flex-shrink-0',
            store.syncStatus.connection === 'connected' ? 'bg-green-500' : 'bg-gray-400'
          ]"></div>
          <span class="flex-1 text-left truncate">
            {{ store.syncStatus.connectedDevice || '未连接' }}
          </span>
          <svg v-if="!store.syncStatus.connectedDevice" class="w-3 h-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
        </button>
      </div>

      <!-- 可拖拽分隔线 -->
      <div
        @mousedown="startResize('sidebar', $event)"
        class="absolute top-0 right-0 w-1 h-full cursor-col-resize hover:bg-blue-400 transition-colors group"
      >
        <div class="absolute inset-y-0 -left-1 -right-1"></div>
      </div>
    </div>

    <!-- 中间：笔记列表 -->
    <div :style="{ width: noteListWidth + 'px' }" class="bg-white border-r border-gray-200 flex flex-col relative">
      <div class="h-12 flex items-center justify-between px-4 border-b border-gray-200 app-drag">
        <span class="text-sm font-semibold text-gray-700">笔记</span>
        <button
          @click="handleNewNote"
          class="app-no-drag p-1.5 hover:bg-gray-100 rounded"
          title="新建笔记"
        >
          <svg class="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
        </button>
      </div>

      <!-- 搜索框 -->
      <div class="px-3 py-2 border-b border-gray-200">
        <input
          v-model="searchQuery"
          @input="handleSearch"
          type="text"
          placeholder="搜索"
          class="w-full px-3 py-1.5 text-sm bg-gray-100 border-none rounded-md focus:outline-none focus:ring-2 focus:ring-blue-400"
        />
      </div>

      <!-- 笔记列表 -->
      <div class="flex-1 overflow-y-auto">
        <div
          v-for="note in store.filteredNotes"
          :key="note.id"
          draggable="true"
          @dragstart="handleNoteDragStart(note.id, $event)"
          @dragend="handleNoteDragEnd"
          @click="store.currentNoteId = note.id"
          :class="[
            'px-4 py-3 border-b border-gray-100 cursor-pointer',
            store.currentNoteId === note.id
              ? 'bg-blue-50'
              : 'hover:bg-gray-50'
          ]"
        >
          <div class="flex items-start justify-between gap-2">
            <div class="flex-1 min-w-0">
              <div class="font-semibold text-sm text-gray-900 truncate">
                {{ note.title || '新笔记' }}
              </div>
              <div class="text-xs text-gray-500 mt-1 flex items-center gap-2">
                <span>{{ formatDate(note.updated_at) }}</span>
                <span class="text-gray-400">{{ getPreviewText(note.content) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 空状态 -->
        <div v-if="store.notes.length === 0" class="flex flex-col items-center justify-center h-full text-gray-400 px-8 text-center">
          <svg class="w-16 h-16 mb-4 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1"
              d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
          </svg>
          <p class="text-sm">没有笔记</p>
          <p class="text-xs mt-1">点击右上角 + 创建新笔记</p>
        </div>
      </div>

      <!-- 可拖拽分隔线 -->
      <div
        @mousedown="startResize('noteList', $event)"
        class="absolute top-0 right-0 w-1 h-full cursor-col-resize hover:bg-blue-400 transition-colors group"
      >
        <div class="absolute inset-y-0 -left-1 -right-1"></div>
      </div>
    </div>

    <!-- 右侧：编辑器 -->
    <div class="flex-1 flex flex-col bg-white">
      <!-- 空状态 -->
      <div v-if="!store.currentNote" class="flex flex-col items-center justify-center h-full text-gray-400">
        <svg class="w-20 h-20 mb-4 text-gray-200" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1"
            d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
        </svg>
        <p class="text-sm">选择一个笔记或创建新笔记</p>
      </div>

      <!-- 编辑器 -->
      <template v-else>
        <!-- 工具栏 -->
        <div class="h-12 flex items-center justify-between px-6 border-b border-gray-200 app-drag">
          <div class="flex items-center gap-1 app-no-drag">
            <ToolBtn @click="editor?.chain().focus().toggleBold().run()"
              :active="editor?.isActive('bold')" title="粗体">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path d="M6 4v12h4.5c2.5 0 4.5-1.5 4.5-4 0-1.5-.8-2.8-2-3.5.7-.7 1-1.6 1-2.5 0-2-1.5-3-4-3H6zm2 2h2c1 0 1.5.5 1.5 1.5S11 9 10 9H8V6zm0 5h2.5c1.2 0 2 .8 2 2s-.8 2-2 2H8v-4z"/>
              </svg>
            </ToolBtn>
            <ToolBtn @click="editor?.chain().focus().toggleItalic().run()"
              :active="editor?.isActive('italic')" title="斜体">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path d="M10 4h4v2h-1.5l-2 8H12v2H8v-2h1.5l2-8H10V4z"/>
              </svg>
            </ToolBtn>
            <ToolBtn @click="editor?.chain().focus().toggleUnderline().run()"
              :active="editor?.isActive('underline')" title="下划线">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path d="M6 3v7c0 2.2 1.8 4 4 4s4-1.8 4-4V3h-2v7c0 1.1-.9 2-2 2s-2-.9-2-2V3H6zm-2 14h12v2H4v-2z"/>
              </svg>
            </ToolBtn>

            <div class="w-px h-5 bg-gray-300 mx-1"></div>

            <ToolBtn @click="editor?.chain().focus().toggleHeading({ level: 1 }).run()"
              :active="editor?.isActive('heading', { level: 1 })" title="标题">
              <span class="text-sm font-bold">T</span>
            </ToolBtn>

            <ToolBtn @click="editor?.chain().focus().toggleBulletList().run()"
              :active="editor?.isActive('bulletList')" title="列表">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path d="M3 5h2v2H3V5zm4 0h10v2H7V5zM3 9h2v2H3V9zm4 0h10v2H7V9zm-4 4h2v2H3v-2zm4 0h10v2H7v-2z"/>
              </svg>
            </ToolBtn>

            <ToolBtn @click="editor?.chain().focus().toggleTaskList().run()"
              :active="editor?.isActive('taskList')" title="待办">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
              </svg>
            </ToolBtn>

            <div class="w-px h-5 bg-gray-300 mx-1"></div>

            <ToolBtn @click="handleInsertImage" title="插入图片">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
              </svg>
            </ToolBtn>
          </div>

          <div class="flex items-center gap-2 app-no-drag">
            <button
              @click="handleDelete"
              class="p-1.5 hover:bg-gray-100 rounded text-gray-600"
              title="删除笔记"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
              </svg>
            </button>
            <button
              @click="handleExport"
              class="p-1.5 hover:bg-gray-100 rounded text-gray-600"
              title="导出"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
              </svg>
            </button>
          </div>
        </div>

        <!-- 编辑区域 -->
        <div class="flex-1 overflow-y-auto">
          <div class="max-w-4xl mx-auto px-12 py-8">
            <!-- 标题 -->
            <input
              v-model="titleInput"
              @input="handleTitleChange"
              placeholder="标题"
              class="w-full text-3xl font-bold text-gray-900 placeholder-gray-300 border-none outline-none bg-transparent mb-4"
            />

            <!-- 日期和状态 -->
            <div class="flex items-center gap-3 text-xs text-gray-400 mb-6">
              <span>{{ formatFullDate(store.currentNote.updated_at) }}</span>
              <span v-if="isSaving" class="text-yellow-600">保存中…</span>
              <span v-else-if="savedRecently" class="text-green-600">已保存</span>
            </div>

            <!-- Tiptap 编辑器 -->
            <EditorContent :editor="editor" class="prose prose-sm max-w-none" />
          </div>
        </div>
      </template>
    </div>

    <!-- 配对码弹窗 -->
    <div v-if="showPairing" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" @click="showPairing = false">
      <div class="bg-white rounded-lg p-8 max-w-md w-full mx-4 shadow-2xl" @click.stop>
        <h2 class="text-xl font-bold text-gray-900 mb-4">连接移动设备</h2>
        <p class="text-sm text-gray-600 mb-6">在移动端 APP 中扫描或输入以下配对码</p>

        <!-- 配对码显示 -->
        <div class="bg-blue-50 border-2 border-blue-400 rounded-lg p-8 mb-6 text-center">
          <div class="text-5xl font-bold text-blue-900 tracking-widest mb-2">
            {{ pairingCode }}
          </div>
          <div class="text-xs text-gray-500">配对码将在 {{ pairingExpiry }} 秒后过期</div>
        </div>

        <div class="text-xs text-gray-500 mb-4">
          <p class="mb-2">连接步骤：</p>
          <ol class="list-decimal list-inside space-y-1">
            <li>打开移动端笔记 APP</li>
            <li>点击"连接桌面端"</li>
            <li>输入上方配对码</li>
          </ol>
        </div>

        <button
          @click="showPairing = false"
          class="w-full px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200"
        >
          关闭
        </button>
      </div>
    </div>

    <!-- 新建文件夹弹窗 -->
    <div v-if="showNewFolderDialog" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" @click="showNewFolderDialog = false">
      <div class="bg-white rounded-lg p-6 max-w-sm w-full mx-4 shadow-2xl" @click.stop>
        <h2 class="text-lg font-bold text-gray-900 mb-4">新建文件夹</h2>
        <input
          v-model="newFolderName"
          @keyup.enter="handleNewFolder"
          type="text"
          placeholder="文件夹名称"
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-400 mb-4"
          autofocus
        />
        <div class="flex gap-2 justify-end">
          <button
            @click="showNewFolderDialog = false"
            class="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200"
          >
            取消
          </button>
          <button
            @click="handleNewFolder"
            class="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600"
          >
            创建
          </button>
        </div>
      </div>
    </div>
  </div>

  <!-- 通用弹窗 -->
  <Dialog
    v-model="dialogState.show"
    :type="dialogState.type"
    :title="dialogState.title"
    :message="dialogState.message"
    @confirm="dialogState.onConfirm"
  />
</template>

<script setup lang="ts">
import { ref, watch, onBeforeUnmount, defineComponent, h } from 'vue'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Underline from '@tiptap/extension-underline'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'
import Image from '@tiptap/extension-image'
import { useNotesStore } from './stores/notes'
import FolderTreeItem from './components/FolderTreeItem.vue'
import Dialog from './components/Dialog.vue'

const store = useNotesStore()
const searchQuery = ref('')
const titleInput = ref('')
const isSaving = ref(false)
const savedRecently = ref(false)
const showPairing = ref(false)
const pairingCode = ref('')
const pairingExpiry = ref(60)
const isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0
const showNewFolderDialog = ref(false)
const newFolderName = ref('')
const isFullscreen = ref(false)

// Dialog 状态
const dialogState = ref({
  show: false,
  type: 'info' as 'info' | 'success' | 'warning' | 'confirm',
  title: '',
  message: '',
  onConfirm: () => {}
})

// 可调整宽度
const sidebarWidth = ref(224) // 默认 56 * 4 = 224px
const noteListWidth = ref(320) // 默认 80 * 4 = 320px
let resizingPanel: 'sidebar' | 'noteList' | null = null
let startX = 0
let startWidth = 0

let saveTimer: ReturnType<typeof setTimeout> | null = null
let savedTimer: ReturnType<typeof setTimeout> | null = null
let pairingTimer: ReturnType<typeof setInterval> | null = null

// 加载笔记和同步状态
store.loadNotes()
window.syncAPI.getStatus().then(status => {
  store.updateSyncStatus(status)
})

// 订阅同步状态变化
window.syncAPI.onStatusChange((status) => {
  store.updateSyncStatus(status)
})

// 从 localStorage 加载宽度
const savedSidebarWidth = localStorage.getItem('sidebarWidth')
const savedNoteListWidth = localStorage.getItem('noteListWidth')
if (savedSidebarWidth) sidebarWidth.value = parseInt(savedSidebarWidth)
if (savedNoteListWidth) noteListWidth.value = parseInt(savedNoteListWidth)

// 监听全屏状态变化
function updateFullscreenStatus() {
  isFullscreen.value = window.innerHeight === screen.height
}

window.addEventListener('resize', updateFullscreenStatus)
updateFullscreenStatus()

// 拖拽调整宽度
function startResize(panel: 'sidebar' | 'noteList', event: MouseEvent) {
  resizingPanel = panel
  startX = event.clientX
  startWidth = panel === 'sidebar' ? sidebarWidth.value : noteListWidth.value

  document.body.classList.add('resizing')
  document.addEventListener('mousemove', handleResize)
  document.addEventListener('mouseup', stopResize)
  event.preventDefault()
}

function handleResize(event: MouseEvent) {
  if (!resizingPanel) return

  const delta = event.clientX - startX
  const newWidth = Math.max(180, Math.min(600, startWidth + delta))

  if (resizingPanel === 'sidebar') {
    sidebarWidth.value = newWidth
  } else {
    noteListWidth.value = newWidth
  }
}

function stopResize() {
  document.body.classList.remove('resizing')

  if (resizingPanel) {
    // 保存到 localStorage
    if (resizingPanel === 'sidebar') {
      localStorage.setItem('sidebarWidth', sidebarWidth.value.toString())
    } else {
      localStorage.setItem('noteListWidth', noteListWidth.value.toString())
    }
  }

  resizingPanel = null
  document.removeEventListener('mousemove', handleResize)
  document.removeEventListener('mouseup', stopResize)
}


// Tiptap 编辑器
const editor = useEditor({
  extensions: [
    StarterKit,
    Underline,
    TaskList,
    TaskItem.configure({ nested: true }),
    Image.configure({
      inline: true,
      allowBase64: true,
    }),
  ],
  content: '',
  editorProps: {
    attributes: {
      class: 'focus:outline-none min-h-[400px]',
    },
    handlePaste: (view, event) => {
      // 处理粘贴图片
      const items = event.clipboardData?.items
      if (!items) return false

      for (const item of Array.from(items)) {
        if (item.type.indexOf('image') === 0) {
          event.preventDefault()
          const file = item.getAsFile()
          if (file) {
            handleImageFile(file)
          }
          return true
        }
      }
      return false
    },
    handleDrop: (view, event, slice, moved) => {
      // 处理拖拽图片
      if (!event.dataTransfer) return false

      const files = Array.from(event.dataTransfer.files)
      const imageFiles = files.filter(file => file.type.indexOf('image') === 0)

      if (imageFiles.length > 0) {
        event.preventDefault()
        imageFiles.forEach(file => handleImageFile(file))
        return true
      }

      return false
    },
  },
  onUpdate: ({ editor }) => {
    handleContentChange(JSON.stringify(editor.getJSON()))
  },
})

// 同步当前笔记到编辑器
watch(() => store.currentNote, (note) => {
  if (!note) return
  titleInput.value = note.title

  try {
    const json = JSON.parse(note.content)
    if (editor.value && JSON.stringify(editor.value.getJSON()) !== JSON.stringify(json)) {
      editor.value.commands.setContent(json, false)
    }
  } catch {
    editor.value?.commands.setContent(note.content || '', false)
  }
}, { immediate: true })

// 保存逻辑
function scheduleSave(changes: { title?: string; content?: string }) {
  if (!store.currentNote) return
  isSaving.value = true
  if (saveTimer) clearTimeout(saveTimer)
  saveTimer = setTimeout(async () => {
    await store.updateNote(store.currentNote!.id, changes)
    isSaving.value = false
    savedRecently.value = true
    if (savedTimer) clearTimeout(savedTimer)
    savedTimer = setTimeout(() => { savedRecently.value = false }, 2000)
  }, 500)
}

function handleTitleChange() {
  scheduleSave({ title: titleInput.value })
}

function handleContentChange(content: string) {
  scheduleSave({ content })
}

async function handleNewNote() {
  await store.createNote('新笔记', '')
}

async function handleDelete() {
  if (!store.currentNote) return
  dialogState.value = {
    show: true,
    type: 'confirm',
    title: '删除笔记',
    message: '确定要删除这条笔记吗？删除后无法恢复。',
    onConfirm: async () => {
      await store.deleteNote(store.currentNote!.id)
    }
  }
}

async function handleExport() {
  if (!store.currentNote) return
  const result = await window.notesAPI.export({
    id: store.currentNote.id,
    format: 'md',
  })
  if (result.success) {
    dialogState.value = {
      show: true,
      type: 'success',
      title: '导出成功',
      message: '笔记已成功导出到指定位置。',
      onConfirm: () => {}
    }
  }
}

function handleSearch() {
  store.searchNotes(searchQuery.value)
}

// 图片处理
async function handleImageFile(file: File) {
  // 检查文件类型
  if (!file.type.startsWith('image/')) {
    dialogState.value = {
      show: true,
      type: 'warning',
      title: '文件类型错误',
      message: '只支持图片文件，请选择 JPG、PNG 或其他图片格式。',
      onConfirm: () => {}
    }
    return
  }

  // 检查文件大小 (10MB)
  if (file.size > 10 * 1024 * 1024) {
    dialogState.value = {
      show: true,
      type: 'warning',
      title: '文件过大',
      message: '图片过大，最大支持 10MB。请压缩后重试。',
      onConfirm: () => {}
    }
    return
  }

  try {
    // 读取文件为 Data URL
    const reader = new FileReader()
    reader.onload = async (e) => {
      const dataURL = e.target?.result as string
      if (!dataURL) return

      // 压缩图片
      const compressedDataURL = await window.imageAPI.compress(dataURL)

      // 插入到编辑器
      editor.value?.chain().focus().setImage({ src: compressedDataURL }).run()
    }
    reader.readAsDataURL(file)
  } catch (error) {
    console.error('Failed to process image:', error)
    dialogState.value = {
      show: true,
      type: 'warning',
      title: '处理失败',
      message: '图片处理失败，请重试或选择其他图片。',
      onConfirm: () => {}
    }
  }
}

async function handleInsertImage() {
  // 创建文件选择器
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/*'
  input.onchange = async (e) => {
    const file = (e.target as HTMLInputElement).files?.[0]
    if (file) {
      await handleImageFile(file)
    }
  }
  input.click()
}

// 显示配对码
async function showPairingCode() {
  try {
    const response = await fetch('http://localhost:45678/api/pairing-code')
    const data = await response.json()
    pairingCode.value = data.code
    pairingExpiry.value = 60
    showPairing.value = true

    // 倒计时
    if (pairingTimer) clearInterval(pairingTimer)
    pairingTimer = setInterval(() => {
      pairingExpiry.value--
      if (pairingExpiry.value <= 0) {
        if (pairingTimer) clearInterval(pairingTimer)
        showPairing.value = false
      }
    }, 1000)
  } catch (error) {
    dialogState.value = {
      show: true,
      type: 'warning',
      title: '连接失败',
      message: '获取配对码失败，请确保同步服务已启动。',
      onConfirm: () => {}
    }
  }
}

// 新建文件夹
function handleNewFolder() {
  if (newFolderName.value.trim()) {
    store.addFolder(newFolderName.value.trim())
    newFolderName.value = ''
    showNewFolderDialog.value = false
  }
}

// 笔记拖拽
function handleNoteDragStart(noteId: string, event: DragEvent) {
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('noteId', noteId)

    // 创建拖拽图标
    const dragIcon = document.createElement('div')
    dragIcon.className = 'drag-icon'
    dragIcon.innerHTML = `
      <div style="
        background: white;
        border: 1px solid #e5e7eb;
        border-radius: 8px;
        padding: 8px 12px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 14px;
        color: #374151;
      ">
        <svg width="16" height="16" fill="currentColor" viewBox="0 0 20 20">
          <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z"/>
          <path fill-rule="evenodd" d="M4 5a2 2 0 012-2 3 3 0 003 3h2a3 3 0 003-3 2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3zm-3 4a1 1 0 100 2h.01a1 1 0 100-2H7zm3 0a1 1 0 100 2h3a1 1 0 100-2h-3z" clip-rule="evenodd"/>
        </svg>
        <span>移动笔记</span>
      </div>
    `
    dragIcon.style.position = 'absolute'
    dragIcon.style.top = '-1000px'
    document.body.appendChild(dragIcon)
    event.dataTransfer.setDragImage(dragIcon, 0, 0)

    // 清理
    setTimeout(() => {
      document.body.removeChild(dragIcon)
    }, 0)
  }
}

function handleNoteDragEnd() {
  // 清理拖拽状态
}

function formatDate(ts: number): string {
  const date = new Date(ts)
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))

  if (days === 0) return '今天'
  if (days === 1) return '昨天'
  if (days < 7) return `${days}天前`
  return date.toLocaleDateString('zh-CN', { month: 'numeric', day: 'numeric' })
}

function formatFullDate(ts: number): string {
  return new Date(ts).toLocaleString('zh-CN', {
    year: 'numeric', month: 'long', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

function formatSyncTime(ts: number): string {
  const date = new Date(ts)
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)

  if (seconds < 60) return '刚刚'
  if (minutes < 60) return `${minutes} 分钟前`
  if (hours < 24) return `${hours} 小时前`
  return date.toLocaleDateString('zh-CN')
}

function getPreviewText(content: string): string {
  if (!content) return ''
  try {
    const json = JSON.parse(content)
    return extractTextFromTiptap(json).slice(0, 30)
  } catch {
    return content.slice(0, 30)
  }
}

function extractTextFromTiptap(node: any): string {
  if (!node) return ''
  if (node.type === 'text') return node.text || ''
  if (node.content && Array.isArray(node.content)) {
    return node.content.map((child: any) => extractTextFromTiptap(child)).join(' ')
  }
  return ''
}

onBeforeUnmount(() => {
  editor.value?.destroy()
  if (pairingTimer) clearInterval(pairingTimer)
  document.removeEventListener('mousemove', handleResize)
  document.removeEventListener('mouseup', stopResize)
  window.removeEventListener('resize', updateFullscreenStatus)
})

// 工具栏按钮
const ToolBtn = defineComponent({
  props: { active: Boolean, title: String },
  emits: ['click'],
  setup(props, { slots, emit }) {
    return () => h(
      'button',
      {
        title: props.title,
        onClick: () => emit('click'),
        class: [
          'p-1.5 rounded transition-colors',
          props.active
            ? 'bg-blue-100 text-blue-900'
            : 'text-gray-600 hover:bg-gray-100',
        ],
      },
      slots.default?.()
    )
  },
})
</script>

<style scoped>
.app-drag {
  -webkit-app-region: drag;
}

.app-no-drag {
  -webkit-app-region: no-drag;
}

/* 防止拖拽时选中文本 */
body.resizing {
  user-select: none;
  cursor: col-resize !important;
}

/* Prose 样式 */
.prose :deep(p) {
  margin: 0.75em 0;
  line-height: 1.6;
}

.prose :deep(h1) {
  font-size: 1.5em;
  font-weight: 700;
  margin: 1em 0 0.5em;
}

.prose :deep(h2) {
  font-size: 1.25em;
  font-weight: 600;
  margin: 0.8em 0 0.4em;
}

.prose :deep(ul),
.prose :deep(ol) {
  padding-left: 1.5em;
  margin: 0.75em 0;
}

.prose :deep(ul[data-type="taskList"]) {
  list-style: none;
  padding-left: 0;
}

.prose :deep(ul[data-type="taskList"] li) {
  display: flex;
  align-items: flex-start;
  gap: 0.5em;
}

.prose :deep(ul[data-type="taskList"] li > label) {
  flex-shrink: 0;
  margin-top: 0.2em;
}

.prose :deep(ul[data-type="taskList"] li > div) {
  flex: 1;
}

.prose :deep(strong) {
  font-weight: 600;
}

.prose :deep(em) {
  font-style: italic;
}

.prose :deep(u) {
  text-decoration: underline;
}

.prose :deep(code) {
  background-color: #f3f4f6;
  padding: 0.2em 0.4em;
  border-radius: 0.25em;
  font-family: 'SF Mono', Monaco, 'Cascadia Code', monospace;
  font-size: 0.9em;
}

.prose :deep(img) {
  max-width: 100%;
  height: auto;
  border-radius: 0.5em;
  margin: 1em 0;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.prose :deep(img:hover) {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.prose :deep(img.ProseMirror-selectednode) {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}
</style>
