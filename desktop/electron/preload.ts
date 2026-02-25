import { contextBridge, ipcRenderer } from 'electron'
import { IPC } from './types'
import type {
  Note, CreateNotePayload, UpdateNotePayload,
  ExportNotePayload, SyncStatus, ConflictInfo
} from './types'

console.log('[Preload] Script loaded')
console.log('[Preload] IPC constants:', IPC)

// 暴露安全的 API 给渲染进程
contextBridge.exposeInMainWorld('notesAPI', {
  getAll: () => ipcRenderer.invoke(IPC.NOTES_GET_ALL) as Promise<Note[]>,
  get: (id: string) => ipcRenderer.invoke(IPC.NOTES_GET, id) as Promise<Note | null>,
  create: (payload: CreateNotePayload) => ipcRenderer.invoke(IPC.NOTES_CREATE, payload) as Promise<Note>,
  update: (payload: UpdateNotePayload) => ipcRenderer.invoke(IPC.NOTES_UPDATE, payload) as Promise<Note>,
  delete: (id: string) => ipcRenderer.invoke(IPC.NOTES_DELETE, id) as Promise<void>,
  search: (keyword: string) => ipcRenderer.invoke(IPC.NOTES_SEARCH, keyword) as Promise<Note[]>,
  export: (payload: ExportNotePayload) => ipcRenderer.invoke(IPC.NOTES_EXPORT, payload) as Promise<{ success: boolean; path?: string; error?: string }>,
  moveToFolder: (note_id: string, folder_id: string) => ipcRenderer.invoke(IPC.NOTES_MOVE_TO_FOLDER, note_id, folder_id) as Promise<Note>,
})

console.log('[Preload] notesAPI exposed')

contextBridge.exposeInMainWorld('foldersAPI', {
  getAll: () => ipcRenderer.invoke(IPC.FOLDERS_GET_ALL),
  getTree: () => ipcRenderer.invoke(IPC.FOLDERS_GET_TREE),
  create: (name: string, parent_id: string | null = null) => ipcRenderer.invoke(IPC.FOLDERS_CREATE, name, parent_id),
  update: (id: string, changes: { name?: string; parent_id?: string | null }) => ipcRenderer.invoke(IPC.FOLDERS_UPDATE, id, changes),
  delete: (id: string) => ipcRenderer.invoke(IPC.FOLDERS_DELETE, id),
  deleteConfirm: (id: string, moveNotesTo: string | null) => ipcRenderer.invoke(IPC.FOLDERS_DELETE + ':confirm', id, moveNotesTo),
  move: (id: string, new_parent_id: string | null) => ipcRenderer.invoke(IPC.FOLDERS_MOVE, id, new_parent_id),
  getNotesCount: (folder_id: string) => ipcRenderer.invoke(IPC.FOLDERS_GET_NOTES_COUNT, folder_id),
})

contextBridge.exposeInMainWorld('imageAPI', {
  compress: (dataURL: string) => ipcRenderer.invoke(IPC.IMAGE_COMPRESS, dataURL) as Promise<string>,
})

contextBridge.exposeInMainWorld('syncAPI', {
  getStatus: () => ipcRenderer.invoke(IPC.SYNC_STATUS) as Promise<SyncStatus>,
  resolve: (payload: any) => ipcRenderer.invoke(IPC.SYNC_RESOLVE, payload) as Promise<void>,
  onStatusChange: (callback: (status: SyncStatus) => void) => {
    const listener = (_: any, status: SyncStatus) => callback(status)
    ipcRenderer.on(IPC.SYNC_STATUS, listener)
    return () => ipcRenderer.removeListener(IPC.SYNC_STATUS, listener)
  },
  onConflict: (callback: (conflict: ConflictInfo) => void) => {
    const listener = (_: any, conflict: ConflictInfo) => callback(conflict)
    ipcRenderer.on(IPC.SYNC_CONFLICT, listener)
    return () => ipcRenderer.removeListener(IPC.SYNC_CONFLICT, listener)
  },
})

console.log('[Preload] syncAPI exposed')
console.log('[Preload] Script complete')
