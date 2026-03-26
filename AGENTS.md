# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-26
**Commit:** 7d1aa26
**Branch:** main

## OVERVIEW

Bash-based environment setup repo. Replicates a full dev environment (opencode, omo, ghostty, docker) on fresh Ubuntu 24.04 via idempotent install scripts.

## STRUCTURE

```
env_setup/
├── install.sh          # Master orchestrator (--skip-*, --dry-run, --force)
├── scripts/
│   ├── _common.sh      # Shared logging/utils — sourced, not executed
│   ├── install-*.sh    # One per tool, each independently runnable
│   └── setup-shell.sh  # PATH injection into ~/.bashrc
├── configs/            # Static JSON templates, copied verbatim (no templating)
└── tests/
    ├── _helpers.sh     # Custom assertion framework — sourced, not executed
    ├── test-all.sh     # Suite runner (globs test-*.sh, aggregates)
    └── test-*.sh       # 1:1 mapping to scripts/install-*.sh
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add new tool | `scripts/install-<tool>.sh` + `tests/test-<tool>.sh` + update `install.sh` | Follow exact template below |
| Add new config | `configs/<tool>.json` | Deploy logic goes in install script |
| Change PATH/env | `scripts/setup-shell.sh` | Edit within managed block markers |
| Add test assertion | `tests/_helpers.sh` | Must use `_inc`, not `(( ))` |
| Add skip flag | `install.sh` | Add `SKIP_*` var + `parse_args` case + `run_step` block |

## CONVENTIONS

**Script template (every .sh file, no exceptions):**
```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"  # or _helpers.sh for tests

main() {
    log_header "Section Name"
    # ... idempotent steps ...
    log_success "Section complete"
}
main "$@"
```

**Naming:**
- `install-<tool>.sh` / `setup-<domain>.sh` — executable scripts
- `_<lib>.sh` — underscore prefix = sourced library, never run directly
- `test-<tool>.sh` — mirrors install script name
- `<tool>.json` / `<plugin>-<variant>.json` / `<plugin>.<profile>.json` — configs

**Logging:** Always use `log_info`/`log_success`/`log_warn`/`log_error` from `_common.sh`. `log_error` goes to stderr; others to stdout.

**Idempotency:** Every install function checks if already installed (`command -v`, `dpkg -s`, file exists) before acting. Safe to re-run.

**Subprocess isolation:** `install.sh` runs each script via `bash "$script"` (not source). Failures in one script don't corrupt parent state.

**Managed block markers in ~/.bashrc:**
```
# >>> env_setup managed >>>
# DO NOT EDIT between markers — managed by env_setup scripts
...
# <<< env_setup managed <<<
```

**`require_cmd` fallback paths:** Checks `~/.bun/bin/`, `~/.opencode/bin/`, `/snap/bin/` before failing. Tools may not be in PATH yet since `setup-shell.sh` runs last.

**Docs language:** README and summaries in Korean. Code comments in English. Summary `.md` at repo root after completing tasks.

## ANTI-PATTERNS

| Pattern | Why | Use instead |
|---------|-----|-------------|
| `((var++))` | Returns exit 1 when var=0 under `set -e`, kills script | `var=$((var + 1))` or `_inc var` |
| `#!/bin/bash` | Not portable | `#!/usr/bin/env bash` |
| Raw `echo` for status | Inconsistent output format | `log_info`/`log_success`/`log_warn`/`log_error` |
| Missing `set -euo pipefail` | Silent failures | Always include as line 2-3 |
| Committing auth files | `auth.json`, `antigravity-*.json` are secrets | Already in `.gitignore` |
| Editing managed block manually | Will be overwritten by `setup-shell.sh` | Edit the script instead |
| Assuming PATH is set | Scripts may run before `setup-shell.sh` | Use `require_cmd` with fallback paths |
| Skipping idempotency check | Re-runs would break | Always check-before-act |
| Unguarded `grep -q` / `diff` | Exit code 1 under `set -e` | Append `2>/dev/null` or `\|\| true` |

## TEST FRAMEWORK

**`tests/_helpers.sh` API:**

| Function | Checks | Args |
|----------|--------|------|
| `assert_cmd_exists` | `command -v` | `cmd [desc]` |
| `assert_file_exists` | `-f` | `file [desc]` |
| `assert_dir_exists` | `-d` | `dir [desc]` |
| `assert_file_executable` | `-x` | `file [desc]` |
| `assert_file_contains` | `grep -q` | `file pattern [desc]` |
| `assert_json_valid` | `jq empty` | `file [desc]` |
| `assert_json_has_key` | `jq -e` | `file jq_path [desc]` |

**Custom inline assertions** — when built-in `assert_*` functions don't fit, manually call `_inc TESTS_TOTAL` + `_inc TESTS_PASSED` or `_inc TESTS_FAILED` with your own if/else + echo PASS/FAIL.

**`print_test_summary`** — must be the last line in every test script. Returns `$TESTS_FAILED` as exit code.

## COMMANDS

```bash
./install.sh                    # Full install (all tools)
./install.sh --dry-run          # Preview without executing
./install.sh --skip-docker      # Skip specific tools
./tests/test-all.sh             # Run all test suites
./tests/test-<tool>.sh          # Run single suite
./scripts/install-<tool>.sh     # Run single installer
```

## NOTES

- **Docker group changes** require logout/login to take effect.
- **`--force` flag** only applies to OMO config deployment (overwrites existing). Docker config always updates if different (with `.bak` backup).
- **`install-opencode.sh`** uses `mktemp` + `trap '...' EXIT` for temp file cleanup — only script that needs it.
- **No CI/CD** — tests are manual. No GitHub Actions.
- **Config deployment is static copy** — no envsubst, no sed, no templating. JSON files copied verbatim.
