# 笔记APP 桌面端开发指南

## 技术栈
- **框架**：Electron 28 + Vue 3 + TypeScript
- **UI**：Tailwind CSS + Headless UI
- **数据库**：better-sqlite3
- **富文本编辑器**：Tiptap（基于 ProseMirror，支持 Markdown 导出）
- **同步服务**：Express + ws（WebSocket）
- **局域网发现**：bonjour-service（mDNS）
- **导出**：docx（Word）、直接写文件（MD/TXT）

---

## 项目结构

```
desktop/
├── electron/                  # Electron 主进程
│   ├── main.ts                # 入口，窗口管理
│   ├── preload.ts             # 预加载脚本（IPC 桥接）
│   ├── db/
│   │   ├── database.ts        # SQLite 初始化
│   │   └── notes.ts           # 笔记 CRUD
│   └── sync/
│       ├── server.ts          # WebSocket + HTTP 同步服务
│       └── mdns.ts            # mDNS 局域网广播
├── src/                       # Vue 3 渲染进程
│   ├── main.ts
│   ├── App.vue
│   ├── components/
│   │   ├── NoteList.vue       # 左侧笔记列表
│   │   ├── NoteEditor.vue     # 右侧编辑器
│   │   ├── Toolbar.vue        # 顶部工具栏
│   │   └── StatusBar.vue      # 底部状态栏
│   ├── stores/
│   │   └── notes.ts           # Pinia 状态管理
│   └── types/
│       └── index.ts           # 类型定义
├── package.json
├── vite.config.ts
├── tsconfig.json
└── electron-builder.config.js
```

---

## 开发步骤

### ✅ Step 1 — 初始化项目（package.json + 配置文件）
- package.json：依赖声明
- vite.config.ts：Vite 构建配置（渲染进程）
- tsconfig.json：TypeScript 配置
- electron-builder.config.js：打包配置

### ✅ Step 2 — 类型定义（src/types/index.ts）
- Note、Device、SyncLog 接口定义
- IPC 通道名称常量

### ✅ Step 3 — 数据库层（electron/db/）
- database.ts：初始化 SQLite，建表（notes / devices / sync_log）
- notes.ts：增删改查、软删除、全文搜索

### ✅ Step 4 — Electron 主进程（electron/main.ts + preload.ts）
- main.ts：创建窗口、注册 IPC Handler
- preload.ts：暴露安全的 API 给渲染进程

### ✅ Step 5 — Vue 状态管理（src/stores/notes.ts）
- Pinia store：笔记列表、当前笔记、搜索关键词、同步状态

### ✅ Step 6 — UI 组件
- App.vue：整体布局（左右分栏）
- NoteList.vue：列表 + 搜索 + 排序
- NoteEditor.vue：Tiptap 富文本编辑器（加粗/斜体/下划线/颜色/Checkbox）
- Toolbar.vue：新建、导出按钮
- StatusBar.vue：连接状态、同步状态

### ✅ Step 7 — 同步服务（electron/sync/）
- server.ts：Express HTTP API + WebSocket 服务
- mdns.ts：mDNS 广播，让移动端能发现桌面端

### ✅ Step 8 — 导出功能（electron/export.ts）
- 导出 Markdown / TXT / Word

---

## 本地运行步骤

```bash
cd desktop
npm install
npm run dev        # 开发模式（热重载）
npm run build      # 打包为可执行文件
```

---

## IPC 通道列表

| 通道名 | 方向 | 说明 |
|--------|------|------|
| `notes:getAll` | Renderer → Main | 获取所有笔记 |
| `notes:get` | Renderer → Main | 获取单条笔记 |
| `notes:create` | Renderer → Main | 新建笔记 |
| `notes:update` | Renderer → Main | 更新笔记 |
| `notes:delete` | Renderer → Main | 删除笔记（软删除） |
| `notes:search` | Renderer → Main | 搜索笔记 |
| `notes:export` | Renderer → Main | 导出笔记 |
| `sync:status` | Main → Renderer | 推送同步状态变化 |
| `sync:conflict` | Main → Renderer | 推送冲突需用户处理 |

---

## 数据库 Schema

```sql
CREATE TABLE notes (
  id         TEXT PRIMARY KEY,
  title      TEXT NOT NULL DEFAULT '',
  content    TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE devices (
  id           TEXT PRIMARY KEY,
  device_name  TEXT NOT NULL,
  token        TEXT NOT NULL,
  last_seen_at INTEGER,
  is_trusted   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE sync_log (
  id            TEXT PRIMARY KEY,
  note_id       TEXT NOT NULL,
  device_id     TEXT NOT NULL,
  synced_at     INTEGER NOT NULL,
  status        TEXT NOT NULL,
  conflict_data TEXT
);
```
