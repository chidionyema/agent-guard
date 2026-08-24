# Colima hard pin

Target: `colima start --kubernetes --cpus 4 --memory 8`.

Measured 2026-08-24 (`colima list`): profile `default` is already Running with 4 CPUs and
8 GiB. Nothing to apply. Do not `colima stop`/`start` to "apply" it: a bootout restarts every
container on the estate (see memory `colima-bootout-restarts-all-containers`).
