import { contextBridge, ipcRenderer } from 'electron'
import { IPC } from '../src/types'
import type {
  Note, CreateNotePayload, UpdateNotePayload,
  ExportNotePayload, SyncStatus, ConflictInfo
} from '../src/types'

// 暴露安全的 API 给渲染进程
contextBridge.exposeInMainWorld('notesAPI', {
  getAll: () => ipcRenderer.invoke(IPC.NOTES_GET_ALL) as Promise<Note[]>,
  get: (id: string) => ipcRenderer.invoke(IPC.NOTES_GET, id) as Promise<Note | null>,
  create: (payload: CreateNotePayload) => ipcRenderer.invoke(IPC.NOTES_CREATE, payload) as Promise<Note>,
  update: (payload: UpdateNotePayload) => ipcRenderer.invoke(IPC.NOTES_UPDATE, payload) as Promise<Note>,
  delete: (id: string) => ipcRenderer.invoke(IPC.NOTES_DELETE, id) as Promise<void>,
  search: (keyword: string) => ipcRenderer.invoke(IPC.NOTES_SEARCH, keyword) as Promise<Note[]>,
  export: (payload: ExportNotePayload) => ipcRenderer.invoke(IPC.NOTES_EXPORT, payload) as Promise<{ success: boolean; path?: string; error?: string }>,
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
