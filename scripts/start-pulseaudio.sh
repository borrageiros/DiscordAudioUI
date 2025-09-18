#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/appuser
export XDG_RUNTIME_DIR=/tmp/runtime-appuser
export PULSE_RUNTIME_PATH=$XDG_RUNTIME_DIR/pulse
mkdir -p "$PULSE_RUNTIME_PATH"
mkdir -p "$XDG_RUNTIME_DIR"
pulseaudio -n --daemonize=no --disallow-exit --exit-idle-time=-1 --log-level=info --log-target=stderr -F /app/pulse/default.pa &
sleep 1
while true; do sleep 3600; done

