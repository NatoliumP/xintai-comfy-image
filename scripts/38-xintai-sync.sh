#!/bin/bash

# Sourced by /opt/instance-tools/bin/boot_default.sh BEFORE 65-supervisor-launch.sh.
# Run helper in a subshell/subprocess so set -e or non-zero exits never abort PID 1.
if [[ -x /opt/xintai/boot_sync.sh ]]; then
    /opt/xintai/boot_sync.sh || echo "[38-xintai-sync] warning: boot_sync exited with $?" >&2
fi
