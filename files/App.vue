<template>
  <div class="flex flex-col h-screen bg-gray-50 select-none">
    <!-- 顶部工具栏 -->
    <Toolbar />

    <!-- 主内容区：左侧列表 + 右侧编辑器 -->
    <div class="flex flex-1 overflow-hidden">
      <NoteList class="w-72 flex-shrink-0" />
      <NoteEditor class="flex-1" />
    </div>

    <!-- 底部状态栏 -->
    <StatusBar />

    <!-- 冲突处理弹窗 -->
    <ConflictDialog v-if="store.pendingConflict" />
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'
import { useNotesStore } from './stores/notes'
import Toolbar from './components/Toolbar.vue'
import NoteList from './components/NoteList.vue'
import NoteEditor from './components/NoteEditor.vue'
import StatusBar from './components/StatusBar.vue'
import ConflictDialog from './components/ConflictDialog.vue'

const store = useNotesStore()

let unsubStatus: (() => void) | null = null
let unsubConflict: (() => void) | null = null

onMounted(async () => {
  await store.loadNotes()

  // 加载初始同步状态
  const status = await window.syncAPI.getStatus()
  store.updateSyncStatus(status)

  // 订阅状态变化
  unsubStatus = window.syncAPI.onStatusChange((s) => {
    store.updateSyncStatus(s)
  })

  // 订阅冲突事件
  unsubConflict = window.syncAPI.onConflict((c) => {
    store.setConflict(c)
  })
})

onUnmounted(() => {
  unsubStatus?.()
  unsubConflict?.()
})
</script>
