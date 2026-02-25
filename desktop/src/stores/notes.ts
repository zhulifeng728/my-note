import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Note, SyncStatus, ConflictInfo } from '../types'

export const useNotesStore = defineStore('notes', () => {
  const notes = ref<Note[]>([])
  const currentNoteId = ref<string | null>(null)
  const currentFolderId = ref<string>('all') // 当前选中的文件夹
  const searchKeyword = ref('')
  const syncStatus = ref<SyncStatus>({
    connection: 'waiting',
    pendingCount: 0,
    lastSyncAt: null,
    connectedDevice: null,
  })
  const pendingConflict = ref<ConflictInfo | null>(null)

  // 文件夹列表（本地存储）
  const folders = ref<Array<{ id: string; name: string; icon: string }>>([
    { id: 'all', name: '所有笔记', icon: 'folder' },
  ])

  const currentNote = computed(() =>
    notes.value.find(n => n.id === currentNoteId.value) ?? null
  )

  const filteredNotes = computed(() => {
    let result = notes.value

    // 按文件夹筛选（暂时所有笔记都在"所有笔记"中）
    // 未来可以扩展：给 Note 添加 folderId 字段

    // 按搜索关键词筛选
    if (searchKeyword.value.trim()) {
      result = result.filter(n =>
        n.title.includes(searchKeyword.value) ||
        n.content.includes(searchKeyword.value)
      )
    }

    return result
  })

  async function loadNotes() {
    notes.value = await window.notesAPI.getAll()
  }

  async function createNote(title: string, content: string) {
    console.log('Creating note...', { title, content })
    console.log('window.notesAPI:', window.notesAPI)
    try {
      const note = await window.notesAPI.create({ title, content })
      console.log('Note created:', note)
      notes.value.unshift(note)
      currentNoteId.value = note.id
    } catch (error) {
      console.error('Failed to create note:', error)
    }
  }

  async function updateNote(id: string, changes: { title?: string; content?: string }) {
    const updated = await window.notesAPI.update({ id, ...changes })
    const index = notes.value.findIndex(n => n.id === id)
    if (index !== -1) {
      notes.value[index] = updated
    }
  }

  async function deleteNote(id: string) {
    await window.notesAPI.delete(id)
    notes.value = notes.value.filter(n => n.id !== id)
    if (currentNoteId.value === id) {
      currentNoteId.value = notes.value[0]?.id ?? null
    }
  }

  async function searchNotes(keyword: string) {
    searchKeyword.value = keyword
    if (keyword.trim()) {
      notes.value = await window.notesAPI.search(keyword)
    } else {
      await loadNotes()
    }
  }

  function updateSyncStatus(status: SyncStatus) {
    syncStatus.value = status
  }

  function setConflict(conflict: ConflictInfo) {
    pendingConflict.value = conflict
  }

  async function resolveConflict(keep: 'local' | 'remote' | 'both') {
    if (!pendingConflict.value) return
    await window.syncAPI.resolve({
      note_id: pendingConflict.value.note_id,
      keep,
    })
    pendingConflict.value = null
    await loadNotes()
  }

  // 文件夹管理
  function addFolder(name: string) {
    const id = `folder-${Date.now()}`
    folders.value.push({ id, name, icon: 'folder' })
    // 保存到 localStorage
    localStorage.setItem('folders', JSON.stringify(folders.value))
  }

  function deleteFolder(id: string) {
    if (id === 'all') return // 不能删除"所有笔记"
    folders.value = folders.value.filter(f => f.id !== id)
    if (currentFolderId.value === id) {
      currentFolderId.value = 'all'
    }
    localStorage.setItem('folders', JSON.stringify(folders.value))
  }

  function renameFolder(id: string, newName: string) {
    const folder = folders.value.find(f => f.id === id)
    if (folder && id !== 'all') {
      folder.name = newName
      localStorage.setItem('folders', JSON.stringify(folders.value))
    }
  }

  // 从 localStorage 加载文件夹
  function loadFolders() {
    const saved = localStorage.getItem('folders')
    if (saved) {
      try {
        const parsed = JSON.parse(saved)
        // 确保"所有笔记"始终存在
        if (!parsed.find((f: any) => f.id === 'all')) {
          parsed.unshift({ id: 'all', name: '所有笔记', icon: 'folder' })
        }
        folders.value = parsed
      } catch (e) {
        console.error('Failed to load folders:', e)
      }
    }
  }

  // 初始化时加载文件夹
  loadFolders()

  return {
    notes,
    currentNoteId,
    currentNote,
    filteredNotes,
    searchKeyword,
    syncStatus,
    pendingConflict,
    folders,
    currentFolderId,
    loadNotes,
    createNote,
    updateNote,
    deleteNote,
    searchNotes,
    updateSyncStatus,
    setConflict,
    resolveConflict,
    addFolder,
    deleteFolder,
    renameFolder,
  }
})
