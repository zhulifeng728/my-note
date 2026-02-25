<template>
  <div class="h-8 bg-gray-100 border-t border-gray-200 flex items-center justify-between px-4 text-xs text-gray-600">
    <div class="flex items-center gap-4">
      <span>
        连接状态:
        <span :class="statusColor">{{ statusText }}</span>
      </span>
      <span v-if="store.syncStatus.connectedDevice">
        设备: {{ store.syncStatus.connectedDevice }}
      </span>
    </div>
    <div v-if="store.syncStatus.lastSyncAt">
      最后同步: {{ new Date(store.syncStatus.lastSyncAt).toLocaleString() }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useNotesStore } from '../stores/notes'

const store = useNotesStore()

const statusText = computed(() => {
  switch (store.syncStatus.connection) {
    case 'connected': return '已连接'
    case 'waiting': return '等待连接'
    case 'error': return '连接错误'
    default: return '未知'
  }
})

const statusColor = computed(() => {
  switch (store.syncStatus.connection) {
    case 'connected': return 'text-green-600'
    case 'waiting': return 'text-yellow-600'
    case 'error': return 'text-red-600'
    default: return 'text-gray-600'
  }
})
</script>
