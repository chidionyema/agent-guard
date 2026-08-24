#!/bin/bash
# Linux only: run an agent inside a transient cgroup scope. No container overhead.
exec systemd-run --scope --user --unit=agent-execution-scope \
  -p MemoryMax=6G -p CPUQuota=400% -p TasksMax=100 "${@:-claude-code}"
