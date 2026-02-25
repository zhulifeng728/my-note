# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A local-first, cross-device notes application built with Electron + Vue 3. Desktop app stores notes in SQLite and runs a local sync server for LAN-based synchronization with mobile devices. No cloud services - all data stays on user devices.

## Development Commands

```bash
# Development mode (hot reload)
npm run dev

# Build for production
npm run build

# Platform-specific builds
npm run build:mac
npm run build:win
```

## Architecture

### Process Model

**Electron Main Process** (`files/main.ts`):
- Window management and app lifecycle
- IPC handlers for all note operations
- Initializes database and sync server on startup
- Automatic database backup on launch

**Sync Server** (`files/server.ts`):
- Express HTTP API (port 45678) + WebSocket server
- mDNS broadcast for device discovery
- Device pairing via 6-digit codes (60s expiry)
- Conflict detection based on timestamp proximity (<5s) and content diff

**Vue Renderer Process** (`files/App.vue`):
- Pinia store for state management
- Tiptap rich text editor
- IPC communication via preload bridge

### Database Schema

SQLite with WAL mode, located in `userData/data/notes.db`:

- `notes`: Core note storage with soft delete (`is_deleted`)
- `notes_fts`: FTS5 full-text search index (auto-synced via triggers)
- `devices`: Trusted device registry with tokens
- `sync_log`: Sync history and conflict tracking

### Sync Protocol

1. **Pairing**: Mobile scans QR code → validates 6-digit code → receives device token
2. **Full sync**: GET `/api/notes` returns all notes (including deleted)
3. **Incremental sync**: GET `/api/notes/since/:timestamp` for changes
4. **Push updates**: POST `/api/notes/sync` with conflict detection
5. **Real-time**: WebSocket connection broadcasts changes to all connected devices

**Conflict Resolution**:
- Detected when both sides modified same note within 5 seconds
- User chooses: keep local, keep remote, or keep both (creates copy)
- Conflicts pushed to renderer via IPC event `sync:conflict`

### IPC Channels

All channel names defined in `src/types/index.ts` under `IPC` constant:

- `notes:getAll`, `notes:get`, `notes:create`, `notes:update`, `notes:delete`
- `notes:search` (uses FTS5 full-text search)
- `notes:export` (formats: md, txt, docx)
- `sync:status` (pushed from main to renderer)
- `sync:conflict` (pushed when conflict detected)
- `sync:resolve` (renderer sends conflict resolution choice)

## Key Implementation Details

- **Database initialization**: `database.ts` creates tables and FTS triggers, backs up to `userData/backups/` (keeps 5 most recent)
- **Note CRUD**: `notes.ts` handles all database operations, `upsertNoteFromSync()` implements timestamp-based merge
- **Export**: `export.ts` converts notes to MD/TXT/DOCX (uses `docx` library for Word format)
- **mDNS**: `mdns.ts` broadcasts service `_notes-sync._tcp` for device discovery

## File Organization

```
files/
├── main.ts           # Electron entry point
├── database.ts       # SQLite initialization
├── notes.ts          # Note CRUD operations
├── server.ts         # Sync server (HTTP + WebSocket)
├── App.vue           # Vue root component
├── NoteEditor.vue    # Tiptap editor component
└── package.json      # Dependencies and scripts
```

Note: This is a work-in-progress. Full project structure (with `electron/`, `src/components/`, `src/stores/`) is documented in `files/DEV_GUIDE.md` but not all files are implemented yet.
