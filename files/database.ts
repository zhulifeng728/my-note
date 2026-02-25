import Database from 'better-sqlite3'
import path from 'path'
import fs from 'fs'
import { app } from 'electron'

let db: Database.Database

export function getDb(): Database.Database {
  if (!db) {
    throw new Error('Database not initialized. Call initDb() first.')
  }
  return db
}

export function initDb(): Database.Database {
  const userDataPath = app.getPath('userData')
  const dbDir = path.join(userDataPath, 'data')

  if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true })
  }

  const dbPath = path.join(dbDir, 'notes.db')
  db = new Database(dbPath)

  // 开启 WAL 模式（写性能更好，支持并发读）
  db.pragma('journal_mode = WAL')
  db.pragma('foreign_keys = ON')

  createTables(db)
  console.log(`[DB] Initialized at: ${dbPath}`)
  return db
}

function createTables(db: Database.Database) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS notes (
      id         TEXT PRIMARY KEY,
      title      TEXT NOT NULL DEFAULT '',
      content    TEXT NOT NULL DEFAULT '',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS devices (
      id           TEXT PRIMARY KEY,
      device_name  TEXT NOT NULL,
      token        TEXT NOT NULL,
      last_seen_at INTEGER,
      is_trusted   INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS sync_log (
      id            TEXT PRIMARY KEY,
      note_id       TEXT NOT NULL,
      device_id     TEXT NOT NULL,
      synced_at     INTEGER NOT NULL,
      status        TEXT NOT NULL DEFAULT 'pending',
      conflict_data TEXT,
      FOREIGN KEY (note_id) REFERENCES notes(id)
    );

    -- 全文搜索索引
    CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
      id UNINDEXED,
      title,
      content,
      content=notes,
      content_rowid=rowid
    );

    -- 触发器：同步 FTS 索引
    CREATE TRIGGER IF NOT EXISTS notes_fts_insert AFTER INSERT ON notes BEGIN
      INSERT INTO notes_fts(rowid, id, title, content)
        VALUES (new.rowid, new.id, new.title, new.content);
    END;

    CREATE TRIGGER IF NOT EXISTS notes_fts_update AFTER UPDATE ON notes BEGIN
      INSERT INTO notes_fts(notes_fts, rowid, id, title, content)
        VALUES ('delete', old.rowid, old.id, old.title, old.content);
      INSERT INTO notes_fts(rowid, id, title, content)
        VALUES (new.rowid, new.id, new.title, new.content);
    END;

    CREATE TRIGGER IF NOT EXISTS notes_fts_delete AFTER DELETE ON notes BEGIN
      INSERT INTO notes_fts(notes_fts, rowid, id, title, content)
        VALUES ('delete', old.rowid, old.id, old.title, old.content);
    END;
  `)
}

/**
 * 备份数据库（启动时自动调用）
 */
export function backupDb(): void {
  try {
    const userDataPath = app.getPath('userData')
    const src = path.join(userDataPath, 'data', 'notes.db')
    const backupDir = path.join(userDataPath, 'backups')

    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true })
    }

    if (!fs.existsSync(src)) return

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
    const dest = path.join(backupDir, `notes-${timestamp}.db`)

    // 保留最近 5 个备份
    const backups = fs.readdirSync(backupDir)
      .filter(f => f.startsWith('notes-') && f.endsWith('.db'))
      .sort()

    if (backups.length >= 5) {
      fs.unlinkSync(path.join(backupDir, backups[0]))
    }

    fs.copyFileSync(src, dest)
    console.log(`[DB] Backed up to: ${dest}`)
  } catch (err) {
    console.error('[DB] Backup failed:', err)
  }
}
