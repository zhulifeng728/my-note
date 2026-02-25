import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Note, SyncStatus, ConflictInfo } from '../types'

export const useNotesStore = defineStore('notes', () => {
  const notes = ref<Note[]>([])
  const currentNoteId = ref<string | null>(null)
  const searchKeyword = ref('')
  const syncStatus = ref<SyncStatus>({
    connection: 'waiting',
    pendingCount: 0,
    lastSyncAt: null,
    connectedDevice: null,
  })
  const pendingConflict = ref<ConflictInfo | null>(null)

  const currentNote = computed(() =>
    notes.value.find(n => n.id === currentNoteId.value) ?? null
  )

  const filteredNotes = computed(() => {
    if (!searchKeyword.value.trim()) return notes.value
    return notes.value.filter(n =>
      n.title.includes(searchKeyword.value) ||
      n.content.includes(searchKeyword.value)
    )
  })

  async function loadNotes() {
    notes.value = await window.notesAPI.getAll()
  }

  async function createNote(title: string, content: string) {
    const note = await window.notesAPI.create({ title, content })
    notes.value.unshift(note)
    currentNoteId.value = note.id
  }

  async function updateNote(id: string, title?: string, content?: string) {
    const updated = await window.notesAPI.update({ id, title, content })
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

  return {
    notes,
    currentNoteId,
    currentNote,
    filteredNotes,
    searchKeyword,
    syncStatus,
    pendingConflict,
    loadNotes,
    createNote,
    updateNote,
    deleteNote,
    searchNotes,
    updateSyncStatus,
    setConflict,
    resolveConflict,
  }
})
