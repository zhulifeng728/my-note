<template>
  <Teleport to="body">
    <div v-if="modelValue" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" @click="handleBackdropClick">
      <div class="bg-white rounded-2xl shadow-2xl w-[400px] overflow-hidden" @click.stop>
        <!-- Header -->
        <div class="px-6 pt-6 pb-4">
          <div class="flex items-center gap-3">
            <div v-if="type !== 'info'" class="flex-shrink-0 w-12 h-12 rounded-full flex items-center justify-center" :class="iconBgClass">
              <svg class="w-6 h-6" :class="iconColorClass" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path v-if="type === 'confirm'" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                <path v-else-if="type === 'success'" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                <path v-else stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
              </svg>
            </div>
            <div class="flex-1">
              <h3 class="text-xl font-semibold text-gray-900">{{ title }}</h3>
            </div>
          </div>
        </div>

        <!-- Content -->
        <div class="px-6 pb-6">
          <p class="text-sm text-gray-600 leading-relaxed mb-6">{{ message }}</p>

          <!-- Actions -->
          <div class="space-y-3">
            <button
              v-if="type === 'confirm'"
              @click="handleConfirm"
              class="w-full px-4 py-3 bg-blue-500 text-white rounded-xl hover:bg-blue-600 active:bg-blue-700 transition-all text-sm font-medium shadow-sm hover:shadow"
            >
              {{ confirmText }}
            </button>
            <button
              @click="handleCancel"
              :class="type === 'confirm'
                ? 'w-full px-4 py-3 bg-white border-2 border-gray-200 text-gray-700 rounded-xl hover:bg-gray-50 active:bg-gray-100 transition-all text-sm font-medium'
                : 'w-full px-4 py-3 bg-blue-500 text-white rounded-xl hover:bg-blue-600 active:bg-blue-700 transition-all text-sm font-medium shadow-sm hover:shadow'"
            >
              {{ cancelText }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  modelValue: boolean
  type?: 'info' | 'success' | 'warning' | 'confirm'
  title: string
  message: string
  confirmText?: string
  cancelText?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: 'info',
  confirmText: '确定',
  cancelText: '取消'
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  'confirm': []
  'cancel': []
}>()

const iconBgClass = computed(() => {
  switch (props.type) {
    case 'success': return 'bg-green-50'
    case 'warning': return 'bg-yellow-50'
    case 'confirm': return 'bg-blue-50'
    default: return 'bg-gray-50'
  }
})

const iconColorClass = computed(() => {
  switch (props.type) {
    case 'success': return 'text-green-500'
    case 'warning': return 'text-yellow-500'
    case 'confirm': return 'text-blue-500'
    default: return 'text-gray-500'
  }
})

function handleConfirm() {
  emit('confirm')
  emit('update:modelValue', false)
}

function handleCancel() {
  emit('cancel')
  emit('update:modelValue', false)
}

function handleBackdropClick() {
  if (props.type !== 'confirm') {
    handleCancel()
  }
}
</script>
