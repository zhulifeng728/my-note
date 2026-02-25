import { v4 as uuidv4 } from 'uuid'
import { getDb } from './database'
import type { Note, CreateNotePayload, UpdateNotePayload } from '../../src/types'

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
    created_at: now,
    updated_at: now,
    is_deleted: 0,
  }

  getDb().prepare(`
    INSERT INTO notes (id, title, content, created_at, updated_at, is_deleted)
    VALUES (@id, @title, @content, @created_at, @updated_at, @is_deleted)
  `).run(note)

  return note
}

export function updateNote(payload: UpdateNotePayload): Note {
  const existing = getNoteById(payload.id)
  if (!existing) throw new Error(`Note not found: ${payload.id}`)

  const updated: Note = {
    ...existing,
    title:      payload.title      ?? existing.title,
    content:    payload.content    ?? existing.content,
    updated_at: Date.now(),
  }

  getDb().prepare(`
    UPDATE notes
    SET title = @title, content = @content, updated_at = @updated_at
    WHERE id = @id
  `).run(updated)

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
      INSERT INTO notes (id, title, content, created_at, updated_at, is_deleted)
      VALUES (@id, @title, @content, @created_at, @updated_at, @is_deleted)
    `).run(remote)
    return remote
  }

  if (remote.updated_at > existing.updated_at) {
    // 远端更新，覆盖
    getDb().prepare(`
      UPDATE notes
      SET title = @title, content = @content, updated_at = @updated_at, is_deleted = @is_deleted
      WHERE id = @id
    `).run(remote)
    return remote
  }

  // 本地更新，跳过
  return null
}
