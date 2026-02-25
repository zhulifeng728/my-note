// 从 electron 目录导出共享类型
export type {
  Note,
  CreateNotePayload,
  UpdateNotePayload,
  ExportNotePayload,
  Device,
  SyncLog,
  SyncConnectionStatus,
  SyncStatus,
  ConflictInfo,
  ConflictResolvePayload,
} from '../../electron/types'

export { IPC } from '../../electron/types'

// ===== Window API 类型声明 =====

import type {
  Note,
  CreateNotePayload,
  UpdateNotePayload,
  ExportNotePayload,
  SyncStatus,
  ConflictInfo,
  ConflictResolvePayload,
} from '../../electron/types'

export interface Folder {
  id: string
  name: string
  parent_id: string | null
  icon: string
  created_at: number
  updated_at: number
  sort_order: number
}

export interface FolderTree extends Folder {
  children: FolderTree[]
  noteCount?: number
}

declare global {
  interface Window {
    notesAPI: {
      getAll: () => Promise<Note[]>
      get: (id: string) => Promise<Note | null>
      create: (payload: CreateNotePayload) => Promise<Note>
      update: (payload: UpdateNotePayload) => Promise<Note>
      delete: (id: string) => Promise<void>
      search: (keyword: string) => Promise<Note[]>
      export: (payload: ExportNotePayload) => Promise<{ success: boolean; path?: string; error?: string }>
      moveToFolder: (note_id: string, folder_id: string) => Promise<Note>
    }
    foldersAPI: {
      getAll: () => Promise<Folder[]>
      getTree: () => Promise<FolderTree[]>
      create: (name: string, parent_id?: string | null) => Promise<Folder>
      update: (id: string, changes: { name?: string; parent_id?: string | null }) => Promise<Folder>
      delete: (id: string) => Promise<{ canDelete: boolean; noteCount: number; hasSubfolders: boolean; subfoldersCount: number }>
      deleteConfirm: (id: string, moveNotesTo: string | null) => Promise<{ success: boolean }>
      move: (id: string, new_parent_id: string | null) => Promise<Folder>
      getNotesCount: (folder_id: string) => Promise<number>
    }
    imageAPI: {
      compress: (dataURL: string) => Promise<string>
    }
    syncAPI: {
      getStatus: () => Promise<SyncStatus>
      resolve: (payload: ConflictResolvePayload) => Promise<void>
      onStatusChange: (callback: (status: SyncStatus) => void) => () => void
      onConflict: (callback: (conflict: ConflictInfo) => void) => () => void
    }
  }
}
