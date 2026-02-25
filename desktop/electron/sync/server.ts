import express from 'express'
import cors from 'cors'
import http from 'http'
import { WebSocketServer, WebSocket } from 'ws'
import { v4 as uuidv4 } from 'uuid'
import { getDb } from '../db/database'
import {
  getAllNotesForSync, getNotesSince,
  upsertNoteFromSync, getNoteById
} from '../db/notes'
import { startMdnsBroadcast, stopMdnsBroadcast } from './mdns'
import type {
  SyncStatus, SyncConnectionStatus, ConflictInfo,
  ConflictResolvePayload, Note, Device
} from '../types'

const PORT = 45678

let server: http.Server | null = null
let wss: WebSocketServer | null = null
let onStatusChange: ((s: SyncStatus) => void) | null = null
let onConflict: ((c: ConflictInfo) => void) | null = null

// 当前配对码（60秒有效）
let currentPairingCode: { code: string; token: string; expiresAt: number } | null = null

// 当前连接的 WebSocket 客户端（每个设备一个连接）
const connectedClients = new Map<string, WebSocket>() // deviceId → ws

// 待处理冲突
const pendingConflicts = new Map<string, { local: Note; remote: Note }>()

// ===== 状态管理 =====

export function getSyncStatus(): SyncStatus {
  const pendingCount = getDb()
    .prepare(`SELECT COUNT(*) as c FROM sync_log WHERE status = 'pending'`)
    .get() as { c: number }

  const lastSync = getDb()
    .prepare(`SELECT MAX(synced_at) as t FROM sync_log WHERE status = 'success'`)
    .get() as { t: number | null }

  const connected = connectedClients.size > 0
  const firstDevice = connected
    ? (getDb().prepare(`SELECT device_name FROM devices WHERE is_trusted = 1 LIMIT 1`).get() as Device | undefined)?.device_name ?? null
    : null

  return {
    connection: connected ? 'connected' : 'waiting' as SyncConnectionStatus,
    pendingCount: pendingCount.c,
    lastSyncAt: lastSync.t,
    connectedDevice: firstDevice,
  }
}

function broadcastStatus() {
  onStatusChange?.(getSyncStatus())
}

// ===== 配对码生成 =====

export function generatePairingCode(): { code: string; expiresAt: number } {
  const code = Math.floor(100000 + Math.random() * 900000).toString()
  const token = uuidv4()
  const expiresAt = Date.now() + 60_000 // 60秒有效

  currentPairingCode = { code, token, expiresAt }

  // 60秒后自动清除
  setTimeout(() => {
    if (currentPairingCode?.code === code) {
      currentPairingCode = null
    }
  }, 60_000)

  return { code, expiresAt }
}

// ===== 冲突处理 =====

export function resolveConflict(payload: ConflictResolvePayload): void {
  const conflict = pendingConflicts.get(payload.note_id)
  if (!conflict) return

  const db = getDb()

  if (payload.keep === 'local') {
    // 保留本地，更新远端（通过 WS 推送）
    broadcastToAll({ type: 'note_update', note: conflict.local })
  } else if (payload.keep === 'remote') {
    upsertNoteFromSync({ ...conflict.remote, updated_at: Date.now() + 1 })
  } else if (payload.keep === 'both') {
    // 保留两个版本：远端笔记创建副本
    const copy: Note = {
      ...conflict.remote,
      id: uuidv4(),
      title: `${conflict.remote.title} (冲突副本)`,
      created_at: Date.now(),
      updated_at: Date.now(),
    }
    db.prepare(`
      INSERT INTO notes (id, title, content, created_at, updated_at, is_deleted)
      VALUES (@id, @title, @content, @created_at, @updated_at, @is_deleted)
    `).run({ ...copy, is_deleted: 0 })
  }

  pendingConflicts.delete(payload.note_id)
  broadcastStatus()
}

// ===== WebSocket 广播 =====

function broadcastToAll(msg: object) {
  const data = JSON.stringify(msg)
  connectedClients.forEach(ws => {
    if (ws.readyState === WebSocket.OPEN) ws.send(data)
  })
}

// ===== 服务启动 =====

export function startSyncServer(
  statusCb: (s: SyncStatus) => void,
  conflictCb: (c: ConflictInfo) => void,
) {
  onStatusChange = statusCb
  onConflict = conflictCb

  const app = express()
  app.use(cors())
  app.use(express.json({ limit: '10mb' }))

  // ----- 配对接口 -----
  // 移动端扫码后调用，验证配对码，返回设备 token
  app.post('/api/pair', (req, res) => {
    const { code, deviceName } = req.body as { code: string; deviceName: string }

    if (
      !currentPairingCode ||
      currentPairingCode.code !== code ||
      Date.now() > currentPairingCode.expiresAt
    ) {
      res.status(401).json({ error: '配对码无效或已过期' })
      return
    }

    const deviceId = uuidv4()
    const token = currentPairingCode.token
    const db = getDb()

    db.prepare(`
      INSERT INTO devices (id, device_name, token, last_seen_at, is_trusted)
      VALUES (?, ?, ?, ?, 1)
    `).run(deviceId, deviceName || '未知设备', token, Date.now())

    currentPairingCode = null // 配对码一次性使用
    broadcastStatus()

    res.json({ deviceId, token })
  })

  // ----- 获取配对码（桌面端 UI 调用） -----
  app.get('/api/pairing-code', (req, res) => {
    const result = generatePairingCode()
    res.json(result)
  })

  // ----- 全量同步接口 -----
  app.get('/api/notes', (req, res) => {
    const token = req.headers['x-device-token'] as string
    if (!verifyToken(token)) { res.status(401).json({ error: 'Unauthorized' }); return }
    res.json(getAllNotesForSync())
  })

  // ----- 增量同步接口 -----
  app.get('/api/notes/since/:ts', (req, res) => {
    const token = req.headers['x-device-token'] as string
    if (!verifyToken(token)) { res.status(401).json({ error: 'Unauthorized' }); return }
    const since = parseInt(req.params.ts, 10)
    res.json(getNotesSince(since))
  })

  // ----- 移动端推送单条笔记变更 -----
  app.post('/api/notes/sync', (req, res) => {
    const token = req.headers['x-device-token'] as string
    const device = verifyToken(token)
    if (!device) { res.status(401).json({ error: 'Unauthorized' }); return }

    const remote = req.body as Note
    const local = getNoteById(remote.id)

    // 冲突检测：两端都有改动且时间接近（5秒内）
    if (
      local &&
      local.updated_at !== remote.updated_at &&
      Math.abs(local.updated_at - remote.updated_at) < 5_000 &&
      local.content !== remote.content
    ) {
      const conflict: ConflictInfo = { note_id: remote.id, local, remote }
      pendingConflicts.set(remote.id, { local, remote })
      onConflict?.(conflict)

      // 记录冲突日志
      getDb().prepare(`
        INSERT INTO sync_log (id, note_id, device_id, synced_at, status, conflict_data)
        VALUES (?, ?, ?, ?, 'conflict', ?)
      `).run(uuidv4(), remote.id, device.id, Date.now(), JSON.stringify(remote))

      res.status(409).json({ error: 'conflict', note_id: remote.id })
      return
    }

    const written = upsertNoteFromSync(remote)

    // 记录同步日志
    getDb().prepare(`
      INSERT INTO sync_log (id, note_id, device_id, synced_at, status)
      VALUES (?, ?, ?, ?, 'success')
    `).run(uuidv4(), remote.id, device.id, Date.now())

    // 推送给其他已连接客户端
    if (written) {
      broadcastToAll({ type: 'note_update', note: written })
    }

    broadcastStatus()
    res.json({ ok: true })
  })

  // ----- WebSocket 实时连接 -----
  server = http.createServer(app)
  wss = new WebSocketServer({ server })

  wss.on('connection', (ws, req) => {
    const token = new URLSearchParams(req.url?.split('?')[1] ?? '').get('token') ?? ''
    const device = verifyToken(token)

    if (!device) {
      ws.close(1008, 'Unauthorized')
      return
    }

    const deviceId = device.id
    connectedClients.set(deviceId, ws)

    // 更新最后活跃时间
    getDb().prepare(`UPDATE devices SET last_seen_at = ? WHERE id = ?`).run(Date.now(), deviceId)
    broadcastStatus()
    console.log(`[Sync] Device connected: ${device.device_name}`)

    ws.on('message', (data) => {
      try {
        const msg = JSON.parse(data.toString())
        if (msg.type === 'ping') ws.send(JSON.stringify({ type: 'pong' }))
      } catch {}
    })

    ws.on('close', () => {
      connectedClients.delete(deviceId)
      broadcastStatus()
      console.log(`[Sync] Device disconnected: ${device.device_name}`)
    })

    ws.on('error', (err) => {
      console.error(`[Sync] WS error for ${device.device_name}:`, err)
      connectedClients.delete(deviceId)
    })
  })

  server.listen(PORT, '0.0.0.0', () => {
    console.log(`[Sync] Server listening on port ${PORT}`)
    startMdnsBroadcast(PORT)
    broadcastStatus()
  })
}

export function stopSyncServer() {
  stopMdnsBroadcast()
  wss?.close()
  server?.close()
  connectedClients.clear()
  console.log('[Sync] Server stopped')
}

// ===== 辅助函数 =====

function verifyToken(token: string): Device | null {
  if (!token) return null
  const device = getDb()
    .prepare(`SELECT * FROM devices WHERE token = ? AND is_trusted = 1`)
    .get(token) as Device | undefined
  return device ?? null
}
