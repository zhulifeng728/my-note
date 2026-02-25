import { app, BrowserWindow, ipcMain, dialog, shell } from 'electron'
import path from 'path'
import fs from 'fs'
import { initDb, backupDb } from './db/database'
import {
  getAllNotes, getNoteById, createNote,
  updateNote, deleteNote, searchNotes, moveNoteToFolder,
  getNotesByFolder, getNotesCountByFolder
} from './db/notes'
import {
  getAllFolders, getFolderTree, createFolder,
  updateFolder, deleteFolder, moveFolderToParent,
  getDescendantFolderIds
} from './db/folders'
import { startSyncServer, stopSyncServer, getSyncStatus } from './sync/server'
import { exportNote } from './export'
import { compressImage, compressImageFromDataURL } from './utils/image'
import { IPC } from './types'
import type {
  CreateNotePayload, UpdateNotePayload,
  ExportNotePayload, ConflictResolvePayload
} from './types'

let mainWindow: BrowserWindow | null = null
const isDev = process.env.NODE_ENV === 'development'

// ===== 窗口创建 =====

function createWindow() {
  const preloadPath = isDev
    ? path.join(__dirname, 'preload.js')
    : path.join(__dirname, 'preload.js')

  console.log('[Main] Preload path:', preloadPath)
  console.log('[Main] Preload exists:', require('fs').existsSync(preloadPath))

  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    trafficLightPosition: process.platform === 'darwin' ? { x: 12, y: 12 } : undefined,
    webPreferences: {
      preload: preloadPath,
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false, // 禁用沙箱以确保 preload 脚本可以执行
    },
    show: false, // 等加载完成后再显示，避免白屏
  })

  // 监听页面加载完成
  mainWindow.webContents.on('did-finish-load', () => {
    console.log('[Main] Page loaded')
  })

  mainWindow.webContents.on('preload-error', (event, preloadPath, error) => {
    console.error('[Main] Preload error:', preloadPath, error)
  })

  if (isDev) {
    mainWindow.loadURL('http://localhost:5173')
    mainWindow.webContents.openDevTools()

    // 在开发模式下，等待页面加载后手动注入 API
    mainWindow.webContents.on('did-finish-load', () => {
      mainWindow?.webContents.executeJavaScript(`
        console.log('[Inject] Injecting APIs...');
        window.__ELECTRON__ = true;
      `)
    })
  } else {
    mainWindow.loadFile(path.join(__dirname, '../dist/index.html'))
  }

  mainWindow.once('ready-to-show', () => {
    mainWindow?.show()
  })

  mainWindow.on('closed', () => {
    mainWindow = null
  })
}

// ===== 应用生命周期 =====

app.whenReady().then(() => {
  backupDb()      // 启动时备份
  initDb()        // 初始化数据库
  startSyncServer((status) => {
    // 同步状态变化时推送到渲染进程
    mainWindow?.webContents.send(IPC.SYNC_STATUS, status)
  }, (conflict) => {
    // 冲突事件推送到渲染进程
    mainWindow?.webContents.send(IPC.SYNC_CONFLICT, conflict)
  })
  createWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})

app.on('window-all-closed', () => {
  stopSyncServer()
  if (process.platform !== 'darwin') app.quit()
})

// ===== IPC Handlers =====

ipcMain.handle(IPC.NOTES_GET_ALL, () => {
  return getAllNotes()
})

ipcMain.handle(IPC.NOTES_GET, (_, id: string) => {
  return getNoteById(id)
})

ipcMain.handle(IPC.NOTES_CREATE, (_, payload: CreateNotePayload) => {
  return createNote(payload)
})

ipcMain.handle(IPC.NOTES_UPDATE, (_, payload: UpdateNotePayload) => {
  return updateNote(payload)
})

ipcMain.handle(IPC.NOTES_DELETE, (_, id: string) => {
  return deleteNote(id)
})

ipcMain.handle(IPC.NOTES_SEARCH, (_, keyword: string) => {
  return searchNotes(keyword)
})

ipcMain.handle(IPC.NOTES_EXPORT, async (_, payload: ExportNotePayload) => {
  const note = getNoteById(payload.id)
  if (!note) return { success: false, error: '笔记不存在' }

  const extMap: Record<string, string> = { md: '.md', txt: '.txt', docx: '.docx' }
  const ext = extMap[payload.format]

  const { canceled, filePath } = await dialog.showSaveDialog(mainWindow!, {
    defaultPath: `${note.title || '未命名笔记'}${ext}`,
    filters: [{ name: payload.format.toUpperCase(), extensions: [payload.format] }],
  })

  if (canceled || !filePath) return { success: false }

  try {
    await exportNote(note, payload.format, filePath)
    shell.showItemInFolder(filePath)
    return { success: true, path: filePath }
  } catch (err: any) {
    return { success: false, error: err.message }
  }
})

ipcMain.handle(IPC.SYNC_STATUS, () => {
  return getSyncStatus()
})

ipcMain.handle(IPC.SYNC_RESOLVE, (_, payload: ConflictResolvePayload) => {
  // 交给 sync server 处理冲突决策
  const { resolveConflict } = require('./sync/server')
  return resolveConflict(payload)
})

// ===== Folders IPC Handlers =====

ipcMain.handle(IPC.FOLDERS_GET_ALL, () => {
  return getAllFolders()
})

ipcMain.handle(IPC.FOLDERS_GET_TREE, () => {
  return getFolderTree()
})

ipcMain.handle(IPC.FOLDERS_CREATE, (_, name: string, parent_id: string | null = null) => {
  return createFolder(name, parent_id)
})

ipcMain.handle(IPC.FOLDERS_UPDATE, (_, id: string, changes: { name?: string; parent_id?: string | null }) => {
  return updateFolder(id, changes)
})

ipcMain.handle(IPC.FOLDERS_DELETE, (_, id: string) => {
  // 获取文件夹下的笔记数量
  const noteCount = getNotesCountByFolder(id)
  // 获取子文件夹
  const descendantIds = getDescendantFolderIds(id)

  return {
    canDelete: true,
    noteCount,
    hasSubfolders: descendantIds.length > 0,
    subfoldersCount: descendantIds.length
  }
})

ipcMain.handle(IPC.FOLDERS_DELETE + ':confirm', (_, id: string, moveNotesTo: string | null) => {
  // 获取当前文件夹和所有子文件夹的ID
  const descendantIds = getDescendantFolderIds(id)
  const allFolderIds = [id, ...descendantIds]

  if (moveNotesTo) {
    // 移动所有文件夹（包括子文件夹）中的笔记
    allFolderIds.forEach(folderId => {
      const notes = getNotesByFolder(folderId)
      notes.forEach(note => {
        moveNoteToFolder(note.id, moveNotesTo)
      })
    })
  } else {
    // 删除所有文件夹（包括子文件夹）中的笔记
    allFolderIds.forEach(folderId => {
      const notes = getNotesByFolder(folderId)
      notes.forEach(note => {
        deleteNote(note.id)
      })
    })
  }

  // 删除所有子文件夹
  descendantIds.forEach(folderId => {
    deleteFolder(folderId)
  })

  // 删除当前文件夹
  deleteFolder(id)
  return { success: true }
})

ipcMain.handle(IPC.FOLDERS_MOVE, (_, id: string, new_parent_id: string | null) => {
  return moveFolderToParent(id, new_parent_id)
})

ipcMain.handle(IPC.FOLDERS_GET_NOTES_COUNT, (_, folder_id: string) => {
  return getNotesCountByFolder(folder_id)
})

ipcMain.handle(IPC.NOTES_MOVE_TO_FOLDER, (_, note_id: string, folder_id: string) => {
  return moveNoteToFolder(note_id, folder_id)
})

// ===== Image IPC Handlers =====

ipcMain.handle(IPC.IMAGE_COMPRESS, async (_, dataURL: string) => {
  try {
    return await compressImageFromDataURL(dataURL)
  } catch (error: any) {
    throw new Error(error.message || '图片压缩失败')
  }
})
