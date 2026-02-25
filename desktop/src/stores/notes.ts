import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Note, SyncStatus, ConflictInfo, FolderTree } from '../types'

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

  // 文件夹列表（从数据库加载）
  const folders = ref<FolderTree[]>([])
  const expandedFolders = ref<Set<string>>(new Set(['all'])) // 展开的文件夹ID

  const currentNote = computed(() =>
    notes.value.find(n => n.id === currentNoteId.value) ?? null
  )

  const filteredNotes = computed(() => {
    let result = notes.value

    // 按文件夹筛选
    if (currentFolderId.value !== 'all') {
      result = result.filter(n => n.folder_id === currentFolderId.value)
    }

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
      const note = await window.notesAPI.create({
        title,
        content,
        folder_id: currentFolderId.value
      })
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
  async function loadFolders() {
    try {
      const tree = await window.foldersAPI.getTree()
      // 添加"所有笔记"虚拟文件夹
      folders.value = [
        {
          id: 'all',
          name: '所有笔记',
          parent_id: null,
          icon: 'folder',
          created_at: 0,
          updated_at: 0,
          sort_order: 0,
          children: [],
          noteCount: notes.value.length
        },
        ...tree
      ]

      // 加载展开状态
      const saved = localStorage.getItem('expandedFolders')
      if (saved) {
        expandedFolders.value = new Set(JSON.parse(saved))
      }
    } catch (error) {
      console.error('Failed to load folders:', error)
    }
  }

  async function addFolder(name: string, parent_id: string | null = null) {
    try {
      await window.foldersAPI.create(name, parent_id)
      await loadFolders()
    } catch (error) {
      console.error('Failed to create folder:', error)
    }
  }

  async function deleteFolder(id: string) {
    if (id === 'all') return // 不能删除"所有笔记"

    try {
      // 检查文件夹状态
      const info = await window.foldersAPI.delete(id)

      if (info.noteCount > 0 || info.hasSubfolders) {
        // 显示确认对话框
        const message = info.hasSubfolders
          ? `文件夹"${id}"包含 ${info.subfoldersCount} 个子文件夹和 ${info.noteCount} 条笔记。\n\n删除选项：\n1. 将笔记移到"所有笔记"\n2. 删除文件夹及所有笔记`
          : `文件夹包含 ${info.noteCount} 条笔记。\n\n删除选项：\n1. 将笔记移到"所有笔记"\n2. 删除文件夹及所有笔记`

        const choice = confirm(message + '\n\n点击"确定"移动笔记，点击"取消"放弃删除')

        if (choice) {
          // 移动笔记到"所有笔记"
          await window.foldersAPI.deleteConfirm(id, 'all')
        } else {
          return
        }
      } else {
        // 直接删除空文件夹
        await window.foldersAPI.deleteConfirm(id, null)
      }

      if (currentFolderId.value === id) {
        currentFolderId.value = 'all'
      }

      await loadFolders()
      await loadNotes()
    } catch (error) {
      console.error('Failed to delete folder:', error)
    }
  }

  async function renameFolder(id: string, newName: string) {
    if (id === 'all') return // 不能重命名"所有笔记"

    try {
      await window.foldersAPI.update(id, { name: newName })
      await loadFolders()
    } catch (error) {
      console.error('Failed to rename folder:', error)
    }
  }

  async function moveNoteToFolder(noteId: string, folderId: string) {
    try {
      await window.notesAPI.moveToFolder(noteId, folderId)
      await loadNotes()
    } catch (error) {
      console.error('Failed to move note:', error)
    }
  }

  function toggleFolder(folderId: string) {
    if (expandedFolders.value.has(folderId)) {
      expandedFolders.value.delete(folderId)
    } else {
      expandedFolders.value.add(folderId)
    }
    // 保存展开状态
    localStorage.setItem('expandedFolders', JSON.stringify([...expandedFolders.value]))
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
    expandedFolders,
    loadNotes,
    createNote,
    updateNote,
    deleteNote,
    searchNotes,
    updateSyncStatus,
    setConflict,
    resolveConflict,
    loadFolders,
    addFolder,
    deleteFolder,
    renameFolder,
    moveNoteToFolder,
    toggleFolder,
  }
})
