---
name: CONDUCTOR Python runtime setup
description: How Python is installed and how the api-server workflow starts
---

## Python path
Installed via `installProgrammingLanguage({ language: "python-3.11" })`.
Binaries land at `/home/runner/workspace/.pythonlibs/bin/`.
`start.sh` must export `PATH="/home/runner/workspace/.pythonlibs/bin:$PATH"` first.

## Workflow command
Must be an **absolute path**: `bash /home/runner/workspace/artifacts/api-server/start.sh`
Relative paths (e.g. `bash artifacts/api-server/start.sh`) fail with "No such file" because the workflow CWD is not the workspace root.

**Why:** Discovered after two failed restart attempts — relative path worked in shell but not in workflow runner.

## Package installs
Use `installLanguagePackages({ language: "python", packages: [...] })` — do NOT use pip directly, it won't be in PATH during the install step.

## Test run
`cd artifacts/api-server && python3 -m pytest tests/ -v` — 58 tests, all pass.
