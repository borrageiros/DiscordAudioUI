#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/appuser
export DISPLAY=:1
websockify --web=/usr/share/novnc/ 6080 localhost:5901

