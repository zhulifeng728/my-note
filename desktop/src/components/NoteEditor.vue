<template>
  <div class="flex flex-col h-full bg-white">
    <!-- 空状态 -->
    <div v-if="!store.currentNote" class="flex flex-col items-center justify-center h-full text-gray-400">
      <svg class="w-16 h-16 mb-4 text-gray-200" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1"
          d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
      </svg>
      <p class="text-sm">选择或新建一条笔记</p>
    </div>

    <template v-else>
      <!-- 标题输入 -->
      <div class="px-8 pt-6 pb-2">
        <input
          v-model="titleInput"
          @input="handleTitleChange"
          placeholder="无标题"
          class="w-full text-2xl font-bold text-gray-900 placeholder-gray-300 border-none outline-none bg-transparent"
        />
        <p class="text-xs text-gray-400 mt-1">
          {{ formatFullDate(store.currentNote.updated_at) }}
          <span v-if="isSaving" class="ml-2 text-blue-400">保存中…</span>
          <span v-else-if="savedRecently" class="ml-2 text-green-500">已保存</span>
        </p>
      </div>

      <!-- 格式工具栏 -->
      <div class="flex items-center gap-1 px-6 py-2 border-y border-gray-100 bg-gray-50">
        <ToolBtn @click="editor?.chain().focus().toggleBold().run()"
          :active="editor?.isActive('bold')" title="加粗 (⌘B)">
          <span class="font-bold text-sm">B</span>
        </ToolBtn>
        <ToolBtn @click="editor?.chain().focus().toggleItalic().run()"
          :active="editor?.isActive('italic')" title="斜体 (⌘I)">
          <span class="italic text-sm">I</span>
        </ToolBtn>
        <ToolBtn @click="editor?.chain().focus().toggleUnderline().run()"
          :active="editor?.isActive('underline')" title="下划线 (⌘U)">
          <span class="underline text-sm">U</span>
        </ToolBtn>

        <div class="w-px h-4 bg-gray-300 mx-1"></div>

        <ToolBtn @click="editor?.chain().focus().toggleHeading({ level: 1 }).run()"
          :active="editor?.isActive('heading', { level: 1 })" title="标题1">
          <span class="text-xs font-semibold">H1</span>
        </ToolBtn>
        <ToolBtn @click="editor?.chain().focus().toggleHeading({ level: 2 }).run()"
          :active="editor?.isActive('heading', { level: 2 })" title="标题2">
          <span class="text-xs font-semibold">H2</span>
        </ToolBtn>

        <div class="w-px h-4 bg-gray-300 mx-1"></div>

        <ToolBtn @click="editor?.chain().focus().toggleBulletList().run()"
          :active="editor?.isActive('bulletList')" title="无序列表">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M4 6h16M4 12h16M4 18h16"/>
          </svg>
        </ToolBtn>
        <ToolBtn @click="editor?.chain().focus().toggleTaskList().run()"
          :active="editor?.isActive('taskList')" title="待办事项">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        </ToolBtn>

        <div class="w-px h-4 bg-gray-300 mx-1"></div>

        <!-- 字体颜色 -->
        <div class="relative">
          <input
            type="color"
            :value="currentColor"
            @input="handleColorChange"
            class="absolute inset-0 opacity-0 w-full h-full cursor-pointer"
            title="字体颜色"
          />
          <ToolBtn :active="false" title="字体颜色">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"/>
            </svg>
            <div class="w-3 h-0.5 mt-0.5 rounded" :style="{ background: currentColor }"></div>
          </ToolBtn>
        </div>
      </div>

      <!-- Tiptap 编辑区 -->
      <div class="flex-1 overflow-y-auto px-8 py-4">
        <EditorContent :editor="editor" class="tiptap-content min-h-full text-gray-800 text-base leading-7" />
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onBeforeUnmount, defineComponent, h } from 'vue'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Underline from '@tiptap/extension-underline'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'
import TextStyle from '@tiptap/extension-text-style'
import Color from '@tiptap/extension-color'
import { useNotesStore } from '../stores/notes'

const store = useNotesStore()

const titleInput = ref('')
const isSaving = ref(false)
const savedRecently = ref(false)
const currentColor = ref('#000000')
let saveTimer: ReturnType<typeof setTimeout> | null = null
let savedTimer: ReturnType<typeof setTimeout> | null = null

// ===== Tiptap 编辑器 =====
const editor = useEditor({
  extensions: [
    StarterKit,
    Underline,
    TaskList,
    TaskItem.configure({ nested: true }),
    TextStyle,
    Color,
  ],
  content: '',
  onUpdate: ({ editor }) => {
    handleContentChange(JSON.stringify(editor.getJSON()))
  },
  onSelectionUpdate: ({ editor }) => {
    const color = editor.getAttributes('textStyle').color
    currentColor.value = color || '#000000'
  },
})

// ===== 同步当前笔记到编辑器 =====
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

// ===== 保存逻辑（防抖 500ms）=====
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

function handleColorChange(e: Event) {
  const color = (e.target as HTMLInputElement).value
  currentColor.value = color
  editor.value?.chain().focus().setColor(color).run()
}

function formatFullDate(ts: number): string {
  return new Date(ts).toLocaleString('zh-CN', {
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit',
  })
}

onBeforeUnmount(() => {
  editor.value?.destroy()
})

// ===== 工具栏按钮子组件 =====
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
          'flex flex-col items-center justify-center w-7 h-7 rounded transition-colors',
          props.active
            ? 'bg-blue-100 text-blue-600'
            : 'text-gray-500 hover:bg-gray-200 hover:text-gray-700',
        ],
      },
      slots.default?.()
    )
  },
})
</script>

<style scoped>
.tiptap-content :deep(.ProseMirror) {
  outline: none;
  min-height: 100%;
}

.tiptap-content :deep(.ProseMirror p) {
  margin: 0.5em 0;
}

.tiptap-content :deep(.ProseMirror h1) {
  font-size: 2em;
  font-weight: bold;
  margin: 1em 0 0.5em;
}

.tiptap-content :deep(.ProseMirror h2) {
  font-size: 1.5em;
  font-weight: bold;
  margin: 0.8em 0 0.4em;
}

.tiptap-content :deep(.ProseMirror ul),
.tiptap-content :deep(.ProseMirror ol) {
  padding-left: 1.5em;
  margin: 0.5em 0;
}

.tiptap-content :deep(.ProseMirror ul[data-type="taskList"]) {
  list-style: none;
  padding-left: 0;
}

.tiptap-content :deep(.ProseMirror ul[data-type="taskList"] li) {
  display: flex;
  align-items: flex-start;
  gap: 0.5em;
}

.tiptap-content :deep(.ProseMirror ul[data-type="taskList"] li > label) {
  flex-shrink: 0;
  margin-top: 0.3em;
}

.tiptap-content :deep(.ProseMirror ul[data-type="taskList"] li > div) {
  flex: 1;
}

.tiptap-content :deep(.ProseMirror strong) {
  font-weight: bold;
}

.tiptap-content :deep(.ProseMirror em) {
  font-style: italic;
}

.tiptap-content :deep(.ProseMirror u) {
  text-decoration: underline;
}

.tiptap-content :deep(.ProseMirror code) {
  background-color: #f3f4f6;
  padding: 0.2em 0.4em;
  border-radius: 0.25em;
  font-family: monospace;
  font-size: 0.9em;
}

.tiptap-content :deep(.ProseMirror pre) {
  background-color: #1f2937;
  color: #f9fafb;
  padding: 1em;
  border-radius: 0.5em;
  overflow-x: auto;
  margin: 1em 0;
}

.tiptap-content :deep(.ProseMirror pre code) {
  background: none;
  color: inherit;
  padding: 0;
}
</style>
