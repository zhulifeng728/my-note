// ===== Note 相关类型 =====

export interface Note {
  id: string
  title: string
  content: string
  created_at: number
  updated_at: number
  is_deleted: number
}

export interface CreateNotePayload {
  title: string
  content: string
}

export interface UpdateNotePayload {
  id: string
  title?: string
  content?: string
}

export interface ExportNotePayload {
  id: string
  format: 'md' | 'txt' | 'docx'
}

// ===== 同步相关类型 =====

export interface Device {
  id: string
  device_name: string
  token: string
  last_seen_at: number | null
  is_trusted: number
}

export interface SyncLog {
  id: string
  note_id: string
  device_id: string
  synced_at: number
  status: 'pending' | 'success' | 'conflict'
  conflict_data: string | null
}

export type SyncConnectionStatus = 'waiting' | 'connected' | 'error'

export interface SyncStatus {
  connection: SyncConnectionStatus
  pendingCount: number
  lastSyncAt: number | null
  connectedDevice: string | null
}

export interface ConflictInfo {
  note_id: string
  local: Note
  remote: Note
}

export interface ConflictResolvePayload {
  note_id: string
  keep: 'local' | 'remote' | 'both'
}

// ===== IPC 通道名称 =====

export const IPC = {
  NOTES_GET_ALL: 'notes:getAll',
  NOTES_GET: 'notes:get',
  NOTES_CREATE: 'notes:create',
  NOTES_UPDATE: 'notes:update',
  NOTES_DELETE: 'notes:delete',
  NOTES_SEARCH: 'notes:search',
  NOTES_EXPORT: 'notes:export',
  SYNC_STATUS: 'sync:status',
  SYNC_CONFLICT: 'sync:conflict',
  SYNC_RESOLVE: 'sync:resolve',
} as const

// ===== Window API 类型声明 =====

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
    }
    syncAPI: {
      getStatus: () => Promise<SyncStatus>
      resolve: (payload: ConflictResolvePayload) => Promise<void>
      onStatusChange: (callback: (status: SyncStatus) => void) => () => void
      onConflict: (callback: (conflict: ConflictInfo) => void) => () => void
    }
  }
}
