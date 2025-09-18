#!/usr/bin/env bash
set -euo pipefail
export USER=appuser
export HOME=/home/appuser
mkdir -p "$HOME/.vnc"
password=${VNC_PASSWORD:-vncpassword}
echo "$password" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"
install -m 755 /app/scripts/xstartup "$HOME/.vnc/xstartup"
sed -i 's/\r$//' "$HOME/.vnc/xstartup"
tightvncserver -kill :1 >/dev/null 2>&1 || true
geometry=${VNC_GEOMETRY:-1600x780}
# Clean orphan locks
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 || true
tightvncserver :1 -geometry "$geometry" -depth 24
export DISPLAY=:1
sleep 1
if ! pgrep -u "$USER" -f "xfce4-session|startxfce4|xfwm4|xfce4-panel" >/dev/null 2>&1; then
  export XAUTHORITY="$HOME/.Xauthority"
  if command -v startxfce4 >/dev/null 2>&1; then
    setsid dbus-launch --exit-with-session startxfce4 >/home/appuser/.vnc/startxfce4.log 2>&1 &
  else
    setsid dbus-launch --exit-with-session xfce4-session >/home/appuser/.vnc/xfce4-session.log 2>&1 &
  fi
fi
logfile=$(ls -1t $HOME/.vnc/*.log | head -n1 || true)
if [ -n "$logfile" ]; then
  tail -F "$logfile" || true
else
  while true; do sleep 3600; done
fi

