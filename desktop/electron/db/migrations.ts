import type Database from 'better-sqlite3'

export interface Migration {
  version: number
  name: string
  up: (db: Database.Database) => void
}

export const migrations: Migration[] = [
  {
    version: 1,
    name: 'add_folders_support',
    up: (db) => {
      console.log('[Migration] Running migration: add_folders_support')

      // 创建 folders 表
      db.exec(`
        CREATE TABLE IF NOT EXISTS folders (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          parent_id TEXT,
          icon TEXT DEFAULT 'folder',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          sort_order INTEGER DEFAULT 0,
          FOREIGN KEY (parent_id) REFERENCES folders(id) ON DELETE CASCADE
        );

        CREATE INDEX IF NOT EXISTS idx_folders_parent ON folders(parent_id);
      `)

      // 给 notes 表添加 folder_id 字段
      const columns = db.pragma('table_info(notes)')
      const hasFolderId = columns.some((col: any) => col.name === 'folder_id')

      if (!hasFolderId) {
        db.exec(`
          ALTER TABLE notes ADD COLUMN folder_id TEXT DEFAULT 'all';
          CREATE INDEX IF NOT EXISTS idx_notes_folder ON notes(folder_id);
        `)
      }

      console.log('[Migration] Migration completed: add_folders_support')
    }
  }
]

export function getCurrentVersion(db: Database.Database): number {
  const result = db.pragma('user_version', { simple: true }) as number
  return result
}

export function setVersion(db: Database.Database, version: number): void {
  db.pragma(`user_version = ${version}`)
}

export function runMigrations(db: Database.Database): void {
  const currentVersion = getCurrentVersion(db)
  console.log(`[Migration] Current database version: ${currentVersion}`)

  const pendingMigrations = migrations.filter(m => m.version > currentVersion)

  if (pendingMigrations.length === 0) {
    console.log('[Migration] Database is up to date')
    return
  }

  console.log(`[Migration] Running ${pendingMigrations.length} migration(s)`)

  for (const migration of pendingMigrations) {
    console.log(`[Migration] Applying migration ${migration.version}: ${migration.name}`)

    try {
      migration.up(db)
      setVersion(db, migration.version)
      console.log(`[Migration] Successfully applied migration ${migration.version}`)
    } catch (error) {
      console.error(`[Migration] Failed to apply migration ${migration.version}:`, error)
      throw error
    }
  }

  console.log('[Migration] All migrations completed')
}
