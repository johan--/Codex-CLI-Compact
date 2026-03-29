# Release Checklist

Follow this checklist **exactly** when bumping a version. All three repos must stay in sync.

## Repos

| Repo | Local path | Remote |
|------|-----------|--------|
| **Dashboard** | `~/Documents/Open source/beads-main/dual-graph-dashboard` | `kunal12203/Codex-CLI-Compact` |
| **Core** | `~/Documents/Open source/Claude-CLI-Compact-core` | `kunal12203/Claude-CLI-Compact-core` |
| **Scoop** | `~/Documents/Open source/scoop-dual-graph` | `kunal12203/scoop-dual-graph` |

## Version locations (ALL must match)

| Repo | File | Field |
|------|------|-------|
| Dashboard | `bin/version.txt` | Entire file content |
| Dashboard | `README.md` | `Current version: **X.Y.Z**` |
| Core | `src/graperoot/__init__.py` | `__version__ = "X.Y.Z"` |
| Core | `pyproject.toml` | `version = "X.Y.Z"` |
| Scoop | `bucket/dual-graph.json` | `"version": "X.Y.Z"` |

## Step-by-step

### 1. Determine the next version

Find the highest version across all three repos and increment by 1:

```bash
# Check all current versions
cat ~/Documents/Open\ source/beads-main/dual-graph-dashboard/bin/version.txt
grep __version__ ~/Documents/Open\ source/Claude-CLI-Compact-core/src/graperoot/__init__.py
grep '"version"' ~/Documents/Open\ source/scoop-dual-graph/bucket/dual-graph.json
```

The new version = max(all versions) + 0.0.1

### 2. Update changelog.txt — ALWAYS DO THIS FIRST

**Before touching any version file**, add a new entry at the top of `bin/changelog.txt` (Dashboard) and `changelog.txt` (Core):

```
X.Y.Z
- Added/Fixed: <what changed>
- Added/Fixed: <what changed>

```

Then copy to Core: `cp bin/changelog.txt ../Claude-CLI-Compact-core/changelog.txt`

The changelog is shown to users on auto-update. **Never push a version without updating it.**

### 3. Update all version files

Update **all five files** listed in the table above to the new version. Do not skip any.

### 3. Commit Dashboard

```bash
cd ~/Documents/Open\ source/beads-main/dual-graph-dashboard
git add bin/version.txt README.md <any changed .ps1/.sh files>
git commit -m "X.Y.Z: <short description of changes>"
```

### 4. Pull and rebase Dashboard (if needed)

```bash
git stash  # if uncommitted changes exist
git pull --rebase
# resolve conflicts if any — always pick the new version
git stash pop  # if stashed
```

### 5. Get Dashboard commit hash and install.ps1 SHA256

After rebase, the commit hash changes. Recompute both:

```bash
git rev-parse HEAD                    # full commit hash
shasum -a 256 install.ps1             # SHA256 of install.ps1
```

### 6. Update Scoop manifest

In `scoop-dual-graph/bucket/dual-graph.json`, update:

- `"version"` → new version
- `"url"` → replace the commit hash in the URL with the Dashboard commit hash from step 5
- `"hash"` → the SHA256 from step 5

### 7. Commit Core and Scoop

```bash
# Core
cd ~/Documents/Open\ source/Claude-CLI-Compact-core
git add src/graperoot/__init__.py pyproject.toml
git commit -m "X.Y.Z: <description>"

# Scoop
cd ~/Documents/Open\ source/scoop-dual-graph
git add bucket/dual-graph.json
git commit -m "X.Y.Z: <description>"
```

### 8. Push — ORDER MATTERS: Dashboard → Scoop → Core

Push Dashboard **first** (scoop URL points to a Dashboard commit), then Scoop, then Core:

```bash
# 1. Dashboard (FIRST — scoop URL depends on this commit existing)
cd ~/Documents/Open\ source/beads-main/dual-graph-dashboard
git push

# 2. Scoop (SECOND — update manifest URL now that Dashboard commit exists)
cd ~/Documents/Open\ source/scoop-dual-graph
git push

# 3. Core (LAST)
cd ~/Documents/Open\ source/Claude-CLI-Compact-core
git push
```

### 9. Upload to Cloudflare R2 (MANDATORY — always do this)

R2 is the fallback CDN used when GitHub raw is slow or unavailable. Always upload on every release.

Configure AWS CLI for R2 (one-time):

```bash
aws configure set aws_access_key_id <key> --profile r2
aws configure set aws_secret_access_key <secret> --profile r2
aws configure set region auto --profile r2
```

R2 credentials are stored in `~/.aws/credentials` under the `r2` profile (never commit them).

**IMPORTANT: Upload launcher files directly from Dashboard `bin/`, NOT from Core.**
Uploading from Core risks pushing a stale copy if Core's dgc.ps1 wasn't synced yet.

```bash
cd ~/Documents/Open\ source/beads-main/dual-graph-dashboard

# Upload any changed launcher files directly from bin/ (check git diff for what changed):
aws s3 cp bin/dgc.ps1 s3://dual-graph-core/dgc.ps1 --endpoint-url "https://612010d26d6532d6f2eae623a776a42b.r2.cloudflarestorage.com" --profile r2
aws s3 cp bin/dg.ps1 s3://dual-graph-core/dg.ps1 --endpoint-url "https://612010d26d6532d6f2eae623a776a42b.r2.cloudflarestorage.com" --profile r2
aws s3 cp bin/dual_graph_launch.sh s3://dual-graph-core/dual_graph_launch.sh --endpoint-url "https://612010d26d6532d6f2eae623a776a42b.r2.cloudflarestorage.com" --profile r2
aws s3 cp bin/changelog.txt s3://dual-graph-core/changelog.txt --endpoint-url "https://612010d26d6532d6f2eae623a776a42b.r2.cloudflarestorage.com" --profile r2

# Python source files live in Core (upload from there if changed):
# aws s3 cp ../Claude-CLI-Compact-core/src/graperoot/mcp_graph_server.py s3://dual-graph-core/mcp_graph_server.py ...
# aws s3 cp ../Claude-CLI-Compact-core/src/graperoot/graph_builder.py s3://dual-graph-core/graph_builder.py ...

# Always update version.txt last:
printf "X.Y.Z" | aws s3 cp - s3://dual-graph-core/version.txt --endpoint-url "https://612010d26d6532d6f2eae623a776a42b.r2.cloudflarestorage.com" --profile r2
```

**Note:** Use `printf` not `echo` for version.txt (avoids trailing newline issues). Do NOT use shell variables for `--endpoint-url` — pass the URL directly or the shell may expand it to empty.

### 10. Publish to PyPI (if Core changed)

If `pyproject.toml` or any Core source files changed:

```bash
cd ~/Documents/Open\ source/Claude-CLI-Compact-core
# build and publish (project-specific build command)
```

Users get the new graperoot automatically — `dgc.ps1` runs `pip install graperoot --upgrade` on self-update.

## Backwards compatibility checklist

Before releasing any change to `dual_graph_launch.sh` or `dgc.ps1`, verify these existing usage patterns still work:

| Command | Expected outcome |
|---------|-----------------|
| `dgc` | Uses `pwd` as project, launches claude normally |
| `dgc /path/to/project` | Uses given path, launches claude normally |
| `dgc /path/to/project "do something"` | Passes prompt to claude |
| `dgc --resume SESSION_ID` | Uses `pwd`, resumes session |
| `dgc /path/to/project --resume SESSION_ID` | Uses given path, resumes session |

Also verify the resume hint at session end:
- Shows correct session ID for the current project (not another project's session)
- Silently skips if `~/.claude/history.jsonl` is missing (new install)
- Silently skips if `python3` is unavailable

## Common mistakes

- **Skipping R2** — R2 is not optional; always upload changed files + version.txt on every release
- **Shell variable in --endpoint-url** — pass the R2 endpoint URL as a literal string, not a variable (shell expansion can produce empty string causing cryptic AWS CLI error)
- **Forgetting `pyproject.toml`** — `__init__.py` and `pyproject.toml` versions must match in Core
- **Stale scoop hash** — if you rebase Dashboard after computing the hash, recompute both commit hash and SHA256
- **Pushing scoop before dashboard** — the scoop URL will 404 until the Dashboard commit exists on GitHub
- **Version not highest** — always check all three repos; they can drift independently

## Pip / dependency versions

- `pip` itself: not pinned — `install.ps1` runs `pip install --upgrade pip` (always latest)
- `mcp>=1.3.0`: minimum floor, not pinned
- `graperoot`: installed by Core's `dgc.ps1` and `install.ps1`, auto-upgraded on each run
- Dashboard's `install.ps1` and `dgc.ps1` install: `mcp>=1.3.0 uvicorn anyio starlette`
- Core's `install.ps1` and `dgc.ps1` install: `mcp>=1.3.0 uvicorn anyio starlette graperoot`

No pip version conflicts. Dependencies use minimum floors, not pins.
