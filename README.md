# Dual-Graph — Compounding Context for Claude Code & Codex CLI

A local MCP server that gives Claude and Codex a persistent memory of your codebase.  
Instead of re-reading files on every turn, it routes Claude directly to the files it already knows matter.

## How it works

```
Turn 1  → cold start, Claude reads freely
Turn 2+ → memory_first: routed directly to touched files, no re-reads
```

Token savings compound across a session. The graph remembers what was read, edited, and decided — so each turn is cheaper than the last.

## Install

```bash
curl -sSL https://raw.githubusercontent.com/kunal12203/Codex-CLI-Compact/main/install.sh | bash
source ~/.zshrc
```

## Usage

**Claude Code:**
```bash
dgc /path/to/your/project
# or from inside the project:
dgc .
```

**Codex CLI:**
```bash
dg /path/to/your/project
```

## Track token savings

```bash
# Start the live dashboard
cd dashboard && python3 server.py
# Open http://localhost:5000

# Save a session benchmark
dgc-bench --save "with-graph" /path/to/project

# Compare two sessions
dgc-bench --compare with-graph without-graph
```

## Repository structure

```
├── install.sh          ← one-line installer
├── bin/                ← CLI tools (dgc, dg, dgc-bench, dg-bench)
├── core/               ← MCP engine (mcp_graph_server.py, graph_builder.py)
├── dashboard/          ← Live token monitor web UI
├── examples/           ← Sample MCP and hooks config
└── docs/               ← Setup guide
```

## MCP tools available inside Claude / Codex

| Tool | What it does |
|---|---|
| `graph_continue` | Routes to relevant files using action memory |
| `graph_read` | Reads files and records them in the action graph |
| `graph_retrieve` | Scores and ranks files by query relevance |
| `graph_register_edit` | Records edits so future turns route correctly |
| `graph_invalidate` | Hard-kills wrong assumptions from memory |
| `graph_confirm_decision` | Locks architecture/design decisions across sessions |
| `graph_close_task` | Resets context when switching tasks |

## All data stays local

Project files, action graphs, and bench logs never leave your machine.  
The repo contains only the tooling, not your code.
