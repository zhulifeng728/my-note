# My Notes

本地优先的跨设备笔记应用，支持桌面端和移动端同步。

## 项目结构

```
my-notes/
├── desktop/          # Electron + Vue 3 桌面端
│   ├── electron/     # Electron 主进程
│   ├── src/          # Vue 渲染进程
│   └── package.json
├── mobile/           # Flutter 移动端（待开发）
└── docs/             # 设计文档
```

## 桌面端

基于 Electron 28 + Vue 3 + TypeScript 构建。

### 功能特性

- 本地 SQLite 数据库存储
- 富文本编辑器（Tiptap）
- 全文搜索（FTS5）
- 局域网同步服务
- 导出为 Markdown/TXT/Word

### 开发

```bash
cd desktop
npm install
npm run dev
```

### 构建

```bash
npm run build        # 当前平台
npm run build:mac    # macOS
npm run build:win    # Windows
```

## 技术栈

**桌面端**:
- Electron 28
- Vue 3 + TypeScript
- Pinia (状态管理)
- Tiptap (富文本编辑)
- better-sqlite3 (数据库)
- Express + WebSocket (同步服务)
- Tailwind CSS

**移动端** (计划中):
- Flutter
- SQLite/Drift

## 同步机制

- 完全本地化，无云服务
- 局域网内通过 mDNS 发现设备
- WebSocket 实时同步
- 基于时间戳的冲突解决

## 许可

MIT
