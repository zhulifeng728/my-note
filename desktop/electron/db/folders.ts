import { v4 as uuidv4 } from 'uuid'
import { getDb } from './database'

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

// ===== 查询 =====

export function getAllFolders(): Folder[] {
  return getDb()
    .prepare(`SELECT * FROM folders ORDER BY sort_order ASC, created_at ASC`)
    .all() as Folder[]
}

export function getFolderById(id: string): Folder | null {
  const row = getDb()
    .prepare(`SELECT * FROM folders WHERE id = ?`)
    .get(id)
  return (row as Folder) ?? null
}

/**
 * 构建文件夹树结构
 */
export function buildFolderTree(folders: Folder[]): FolderTree[] {
  const folderMap = new Map<string, FolderTree>()
  const rootFolders: FolderTree[] = []

  // 初始化所有文件夹
  folders.forEach(folder => {
    folderMap.set(folder.id, { ...folder, children: [] })
  })

  // 构建树结构
  folders.forEach(folder => {
    const node = folderMap.get(folder.id)!
    if (folder.parent_id === null) {
      rootFolders.push(node)
    } else {
      const parent = folderMap.get(folder.parent_id)
      if (parent) {
        parent.children.push(node)
      } else {
        // 父文件夹不存在，放到根目录
        rootFolders.push(node)
      }
    }
  })

  return rootFolders
}

/**
 * 获取文件夹树（包含子文件夹）
 */
export function getFolderTree(): FolderTree[] {
  const folders = getAllFolders()
  return buildFolderTree(folders)
}

// ===== 写入 =====

export function createFolder(name: string, parent_id: string | null = null): Folder {
  const now = Date.now()
  const folder: Folder = {
    id: uuidv4(),
    name,
    parent_id,
    icon: 'folder',
    created_at: now,
    updated_at: now,
    sort_order: 0,
  }

  getDb().prepare(`
    INSERT INTO folders (id, name, parent_id, icon, created_at, updated_at, sort_order)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(folder.id, folder.name, folder.parent_id, folder.icon, folder.created_at, folder.updated_at, folder.sort_order)

  return folder
}

export function updateFolder(id: string, changes: { name?: string; parent_id?: string | null }): Folder {
  const existing = getFolderById(id)
  if (!existing) throw new Error(`Folder not found: ${id}`)

  const updated: Folder = {
    ...existing,
    name: changes.name !== undefined ? changes.name : existing.name,
    parent_id: changes.parent_id !== undefined ? changes.parent_id : existing.parent_id,
    updated_at: Date.now(),
  }

  getDb().prepare(`
    UPDATE folders
    SET name = ?, parent_id = ?, updated_at = ?
    WHERE id = ?
  `).run(updated.name, updated.parent_id, updated.updated_at, updated.id)

  return updated
}

export function deleteFolder(id: string): void {
  getDb().prepare(`DELETE FROM folders WHERE id = ?`).run(id)
}

/**
 * 移动文件夹到新的父文件夹
 */
export function moveFolderToParent(id: string, new_parent_id: string | null): Folder {
  // 检查循环引用
  if (new_parent_id && isDescendant(new_parent_id, id)) {
    throw new Error('Cannot move folder to its own descendant')
  }

  return updateFolder(id, { parent_id: new_parent_id })
}

/**
 * 检查 targetId 是否是 folderId 的后代
 */
function isDescendant(targetId: string, folderId: string): boolean {
  let current = getFolderById(targetId)
  while (current) {
    if (current.id === folderId) return true
    if (!current.parent_id) break
    current = getFolderById(current.parent_id)
  }
  return false
}

/**
 * 获取文件夹的所有子文件夹ID（递归）
 */
export function getDescendantFolderIds(folderId: string): string[] {
  const result: string[] = []
  const folders = getAllFolders()

  function collect(parentId: string) {
    folders.forEach(folder => {
      if (folder.parent_id === parentId) {
        result.push(folder.id)
        collect(folder.id)
      }
    })
  }

  collect(folderId)
  return result
}

/**
 * 获取文件夹深度
 */
export function getFolderDepth(folderId: string): number {
  let depth = 0
  let current = getFolderById(folderId)

  while (current && current.parent_id) {
    depth++
    current = getFolderById(current.parent_id)
  }

  return depth
}

/**
 * 从 localStorage 迁移文件夹数据（仅在首次运行时）
 */
export function migrateFoldersFromLocalStorage(localStorageData: string): void {
  try {
    const folders = JSON.parse(localStorageData) as Array<{ id: string; name: string; icon: string }>

    for (const folder of folders) {
      // 跳过系统文件夹 'all'
      if (folder.id === 'all') continue

      // 检查是否已存在
      const existing = getFolderById(folder.id)
      if (existing) continue

      // 创建文件夹
      const now = Date.now()
      getDb().prepare(`
        INSERT INTO folders (id, name, parent_id, icon, created_at, updated_at, sort_order)
        VALUES (?, ?, NULL, ?, ?, ?, 0)
      `).run(folder.id, folder.name, folder.icon || 'folder', now, now)
    }

    console.log(`[Folders] Migrated ${folders.length} folders from localStorage`)
  } catch (error) {
    console.error('[Folders] Failed to migrate from localStorage:', error)
  }
}
