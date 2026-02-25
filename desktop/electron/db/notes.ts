import { v4 as uuidv4 } from 'uuid'
import { getDb } from './database'
import type { Note, CreateNotePayload, UpdateNotePayload } from '../types'
import { getDescendantFolderIds } from './folders'

// ===== 查询 =====

export function getAllNotes(): Note[] {
  return getDb()
    .prepare(`SELECT * FROM notes WHERE is_deleted = 0 ORDER BY updated_at DESC`)
    .all() as Note[]
}

export function getNoteById(id: string): Note | null {
  const row = getDb()
    .prepare(`SELECT * FROM notes WHERE id = ? AND is_deleted = 0`)
    .get(id)
  return (row as Note) ?? null
}

export function searchNotes(keyword: string): Note[] {
  if (!keyword.trim()) return getAllNotes()

  // 使用 FTS5 全文搜索，然后 JOIN 回原表拿完整数据
  return getDb().prepare(`
    SELECT n.*
    FROM notes n
    JOIN notes_fts f ON n.id = f.id
    WHERE notes_fts MATCH ?
      AND n.is_deleted = 0
    ORDER BY n.updated_at DESC
  `).all(`${keyword}*`) as Note[]
}

// ===== 写入 =====

export function createNote(payload: CreateNotePayload): Note {
  const now = Date.now()
  const note: Note = {
    id:         uuidv4(),
    title:      payload.title,
    content:    payload.content,
    folder_id:  payload.folder_id || 'all',
    created_at: now,
    updated_at: now,
    is_deleted: 0,
  }

  getDb().prepare(`
    INSERT INTO notes (id, title, content, folder_id, created_at, updated_at, is_deleted)
    VALUES (@id, @title, @content, @folder_id, @created_at, @updated_at, @is_deleted)
  `).run(note)

  return note
}

export function updateNote(payload: UpdateNotePayload): Note {
  console.log('[DB] updateNote called with payload:', payload)

  const existing = getNoteById(payload.id)
  if (!existing) throw new Error(`Note not found: ${payload.id}`)

  console.log('[DB] existing note:', existing)

  const updated: Note = {
    ...existing,
    title:      payload.title !== undefined ? payload.title : existing.title,
    content:    payload.content !== undefined ? payload.content : existing.content,
    updated_at: Date.now(),
  }

  console.log('[DB] Updating note:', {
    id: updated.id,
    title: updated.title,
    content: updated.content?.substring(0, 50),
    updated_at: updated.updated_at,
    types: {
      id: typeof updated.id,
      title: typeof updated.title,
      content: typeof updated.content,
      updated_at: typeof updated.updated_at,
    }
  })

  getDb().prepare(`
    UPDATE notes
    SET title = ?, content = ?, updated_at = ?
    WHERE id = ?
  `).run(updated.title, updated.content, updated.updated_at, updated.id)

  return updated
}

export function deleteNote(id: string): void {
  getDb().prepare(`
    UPDATE notes SET is_deleted = 1, updated_at = ? WHERE id = ?
  `).run(Date.now(), id)
}

// ===== 同步专用 =====

/** 获取所有笔记（含软删除），用于全量同步 */
export function getAllNotesForSync(): Note[] {
  return getDb()
    .prepare(`SELECT * FROM notes ORDER BY updated_at DESC`)
    .all() as Note[]
}

/** 获取指定时间戳之后变更的笔记，用于增量同步 */
export function getNotesSince(since: number): Note[] {
  return getDb()
    .prepare(`SELECT * FROM notes WHERE updated_at > ? ORDER BY updated_at ASC`)
    .all(since) as Note[]
}

/**
 * 同步端写入笔记（冲突策略：时间戳更新则覆盖，否则跳过）
 * 返回实际写入的笔记，或 null（跳过）
 */
export function upsertNoteFromSync(remote: Note): Note | null {
  const existing = getDb()
    .prepare(`SELECT * FROM notes WHERE id = ?`)
    .get(remote.id) as Note | undefined

  if (!existing) {
    // 新笔记，直接插入
    getDb().prepare(`
      INSERT INTO notes (id, title, content, folder_id, created_at, updated_at, is_deleted)
      VALUES (@id, @title, @content, @folder_id, @created_at, @updated_at, @is_deleted)
    `).run(remote)
    return remote
  }

  if (remote.updated_at > existing.updated_at) {
    // 远端更新，覆盖
    getDb().prepare(`
      UPDATE notes
      SET title = @title, content = @content, folder_id = @folder_id, updated_at = @updated_at, is_deleted = @is_deleted
      WHERE id = @id
    `).run(remote)
    return remote
  }

  // 本地更新，跳过
  return null
}

// ===== 文件夹相关操作 =====

/**
 * 移动笔记到指定文件夹
 */
export function moveNoteToFolder(note_id: string, folder_id: string): Note {
  const existing = getNoteById(note_id)
  if (!existing) throw new Error(`Note not found: ${note_id}`)

  const updated: Note = {
    ...existing,
    folder_id,
    updated_at: Date.now(),
  }

  getDb().prepare(`
    UPDATE notes
    SET folder_id = ?, updated_at = ?
    WHERE id = ?
  `).run(updated.folder_id, updated.updated_at, updated.id)

  return updated
}

/**
 * 获取指定文件夹下的笔记（不包括子文件夹）
 */
export function getNotesByFolder(folder_id: string): Note[] {
  if (folder_id === 'all') {
    return getAllNotes()
  }

  return getDb()
    .prepare(`SELECT * FROM notes WHERE folder_id = ? AND is_deleted = 0 ORDER BY updated_at DESC`)
    .all(folder_id) as Note[]
}

/**
 * 获取指定文件夹及其子文件夹下的笔记数量
 */
export function getNotesCountByFolder(folder_id: string): number {
  if (folder_id === 'all') {
    return getAllNotes().length
  }

  // 获取所有子文件夹ID
  const descendantIds = getDescendantFolderIds(folder_id)
  const allFolderIds = [folder_id, ...descendantIds]

  // 构建 IN 查询
  const placeholders = allFolderIds.map(() => '?').join(',')
  const count = getDb()
    .prepare(`SELECT COUNT(*) as count FROM notes WHERE folder_id IN (${placeholders}) AND is_deleted = 0`)
    .get(...allFolderIds) as { count: number }

  return count.count
}

/**
 * 批量移动笔记到指定文件夹
 */
export function batchMoveNotesToFolder(note_ids: string[], folder_id: string): void {
  const db = getDb()
  const now = Date.now()

  const transaction = db.transaction((ids: string[]) => {
    const stmt = db.prepare(`
      UPDATE notes
      SET folder_id = ?, updated_at = ?
      WHERE id = ?
    `)

    for (const id of ids) {
      stmt.run(folder_id, now, id)
    }
  })

  transaction(note_ids)
}

