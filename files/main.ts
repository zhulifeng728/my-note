import { app, BrowserWindow, ipcMain, dialog, shell } from 'electron'
import path from 'path'
import fs from 'fs'
import { initDb, backupDb } from './db/database'
import {
  getAllNotes, getNoteById, createNote,
  updateNote, deleteNote, searchNotes
} from './db/notes'
import { startSyncServer, stopSyncServer, getSyncStatus } from './sync/server'
import { exportNote } from './export'
import { IPC } from '../src/types'
import type {
  CreateNotePayload, UpdateNotePayload,
  ExportNotePayload, ConflictResolvePayload
} from '../src/types'

let mainWindow: BrowserWindow | null = null
const isDev = process.env.NODE_ENV === 'development'

// ===== 窗口创建 =====

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
    show: false, // 等加载完成后再显示，避免白屏
  })

  if (isDev) {
    mainWindow.loadURL('http://localhost:5173')
    mainWindow.webContents.openDevTools()
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

  const extMap = { md: '.md', txt: '.txt', docx: '.docx' }
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
