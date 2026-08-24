# agent-guard

Containment for autonomous agent subprocesses on this estate. Three layers, one repo.

Reviewed 2026-08-24 against a real incident: load 227 on 12 cores nine minutes after a
reboot. Measured cause: `CPU_Speed_Limit = 23` (thermal throttle) plus two estate Python
transcript miners at normal priority, plus 24 periodic launchd jobs firing together at boot.
No headless Chrome, no Playwright, no Node was involved. The review below grades the
proposed spec against that measurement.

## Review of the proposed spec (R3 strict bar)

| Tier | Item | Grade | Why |
|---|---|---|---|
| 1 | Reap orphaned headless Chrome / Playwright / Node | KEEP, reworked | Correct target set. Reworked to report first and kill only with `--kill`, and to never touch a Chrome that has a window (pid whose parent is launchd and has no `--headless`). |
| 2 | `find` interceptor on PATH via `/etc/zshenv` | NOT-RAISING-THE-BAR | Rewrites every `find` on the machine. `find /path` becomes `find . -maxdepth 3 /path`, which errors. Machine-wide shell injection to fix one slow command is stitching. |
| 2 | Watchdog that `kill -9`s any python/node over 80% CPU | NOT-RAISING-THE-BAR | It would have missed the incident (reflect.py was at 55%) and would kill pytest, maestro and the gateway on a throttled CPU. Replaced by `launchd-lint` (the measured class) and `load-probe` (report only, throttle check first). |
| 3 | DevContainer with cgroup limits, cap-drop, read-only | KEEP | The mature layer. Shipped unchanged in `sandbox/`. |
| 3 | `systemd-run --scope` on Linux | KEEP | Shipped in `sandbox/`. |
| 3 | Colima hard pin `--cpus 4 --memory 8` | KEEP, already true | `colima list` on 2026-08-24: `default Running 4 8GiB`. Do not restart colima to apply it; a bootout restarts every container. |

## What is here

- `bin/agent-reap` — Tier 1. Lists orphaned headless Chrome, chromedriver, Playwright and
  Node children. Kills only with `--kill`. Never matches a Chrome with a window.
- `bin/launchd-lint` — Tier 2. Every periodic user launchd job must carry `Nice >= 10`, and
  a job with `StartInterval >= 3600` must not also `RunAtLoad`. Exit 1 lists the offenders.
- `bin/load-probe` — Tier 2. Prints `CPU_Speed_Limit`, load per core, and the hottest
  processes from a second `top` frame. Exit 1 above threshold. Reports, never kills.
- `sandbox/` — Tier 3. `devcontainer.json`, `systemd-run.sh`, `colima.md`.
- `make test` — selftests for every bin, each proving one must-fail and one must-pass case.

## Residual

`launchd-lint` reads plist files, not the loaded definition; a job edited on disk but not
reloaded still runs the old definition. `load-probe` cannot see inside colima's VM.

## Installed on this machine (2026-08-24)

- 30 of 49 periodic plists in `~/Library/LaunchAgents` edited: `Nice=10` where lower, `RunAtLoad=false`
  where `StartInterval >= 3600`. Originals were not in git anywhere (LAW 24 residual).
- `~/.claude/scripts/directive-capture.py` spawns `directives.py --backfill` at `os.nice(19)`.
- `launchd/ai.estate.agent-guard-lint.plist` runs `launchd-lint --broadcast-on-red` every 6 h.
  Install: `cp launchd/ai.estate.agent-guard-lint.plist ~/Library/LaunchAgents/ && launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.estate.agent-guard-lint.plist`
