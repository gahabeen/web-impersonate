#!/bin/bash
./backup_env.sh

export BASE_IMAGE_LABEL="web-impersonate"

load_env_files() {
  local dir="$1"
  local remove_files="${2:-true}"
  if [ -d "$dir" ]; then
    echo "[$BASE_IMAGE_LABEL] 🟢 [ENV] loading $dir"
    # Load default environment file if it exists
    [ -f "$dir/.default.env" ] && set -a && . "$dir/.default.env" && set +a

    # Load and remove other environment files
    if compgen -G "$dir/.env*" >/dev/null; then
      for envfile in "$dir"/.env*; do
        [ -f "$envfile" ] && set -a && . "$envfile" && set +a
        if [ "$remove_files" = true ]; then
          rm -f "$envfile"
        fi
      done
    fi
  else
    echo "[$BASE_IMAGE_LABEL] ⚪ [ENV] no $dir provided"
  fi
}

load_env_files "/usr/local/etc/env"
load_env_files "/mnt/env" false

source /tmp/backup_env.sh

if [ -n "$LOCALHOST_DOMAIN_NAME" ]; then
  echo "[$BASE_IMAGE_LABEL] 🟢 [LOCALHOST_DOMAIN_NAME] $LOCALHOST_DOMAIN_NAME"
  echo "127.0.0.1 $LOCALHOST_DOMAIN_NAME" >>"/etc/hosts"
else
  echo "[$BASE_IMAGE_LABEL] ⚪ [LOCALHOST_DOMAIN_NAME] none provided"
fi

if [ "$START_XVBF" = true ]; then
  # Start X virtual framebuffer
  echo "[$BASE_IMAGE_LABEL] 🟢 [XVFB] started ($DISPLAY ${SCREEN_RESOLUTION}x${SCREEN_DEPTH})."
  Xvfb $DISPLAY -ac -screen 0 ${SCREEN_RESOLUTION}x${SCREEN_DEPTH} -nolisten tcp &

  # Start Fluxbox window manager
  fluxbox >/dev/null 2>&1 &

  # Ensure that Xvfb and Fluxbox have started before proceeding
  sleep 2
else
  echo "[$BASE_IMAGE_LABEL] ⚪ [XVFB] disabled"
fi

if [ "$START_VNC" = true ]; then
  # Start VNC server
  x11vnc -display $DISPLAY -quiet -noxrecord -noxfixes -noxdamage -forever -passwd $VNC_PASSWORD -rfbport $VNC_PORT -o /dev/null &
  echo "[$BASE_IMAGE_LABEL] 🟢 [VNC] started (on $DISPLAY, PORT: $VNC_PORT)."

  # Ensure VNC server has started before proce´eding
  sleep 2
else
  echo "[$BASE_IMAGE_LABEL] ⚪ [VNC] disabled"
fi

if [ "$START_NGINX" = true ]; then
  mkdir -p /var/log/openresty

  openresty -g 'daemon off;' &
  echo "[$BASE_IMAGE_LABEL] 🟢 [NGINX] started"
else
  echo "[$BASE_IMAGE_LABEL] ⚪ [NGINX] disabled"
fi

if [ "$START_RSYSLOG" = true ]; then
  rm -rf /etc/rsyslog.d/*-haproxy.conf # Remove old config

  if [ -d "/mnt/rsyslog" ]; then
    echo "[$BASE_IMAGE_LABEL] 🟢 [RSYSLOG] copying found rsyslog /mnt/rsyslog"
    cp -r /mnt/rsyslog/* /etc/rsyslog.d
  else
    echo "[$BASE_IMAGE_LABEL] ⚪ [RSYSLOG] no /mnt/rsyslog provided"
  fi

  rsyslogd -n &
  echo "[$BASE_IMAGE_LABEL] 🟢 [RSYSLOG] started"
else
  echo "[$BASE_IMAGE_LABEL] ⚪ [RSYSLOG] disabled"
fi

if [ "$START_HAPROXY" = true ]; then
  mkdir -p /usr/local/etc/haproxy

  if [ -d "/mnt/haproxy" ]; then
    echo "[$BASE_IMAGE_LABEL] 🟢 [HAPROXY] copying found HAProxy /mnt/haproxy"
    cp -r /mnt/haproxy/* /usr/local/etc/haproxy
  else
    echo "[$BASE_IMAGE_LABEL] ⚪ [HAPROXY] no /mnt/haproxy provided"
  fi

  if [ -f "/usr/local/etc/haproxy/haproxy.cfg" ]; then
    echo "[$BASE_IMAGE_LABEL] 🟢 [HAPROXY] applying ENV variables to haproxy.cfg"
    cp /usr/local/etc/haproxy/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg.bak
    envsubst </usr/local/etc/haproxy/haproxy.cfg.bak >/usr/local/etc/haproxy/haproxy.cfg
  else
    echo "[$BASE_IMAGE_LABEL] ⚪ [HAPROXY] no haproxy.cfg provided"
  fi

  haproxy -f /usr/local/etc/haproxy/haproxy.cfg &
  echo "[$BASE_IMAGE_LABEL] 🟢 [HAPROXY] started"
else
  echo "[$BASE_IMAGE_LABEL] ⚪ [HAPROXY] disabled"
fi

if [ "$START_LAVINMQ" = true ]; then
  lavinmq &
  echo "[$BASE_IMAGE_LABEL] 🟢 [LAVINMQ] started"
else
  echo "[$BASE_IMAGE_LABEL] ⚪ [LAVINMQ] disabled"
fi

if [ "$START_TINYPROXY" = true ]; then
  mkdir -p /etc/tinyproxy

  if [ -d "/mnt/tinyproxy" ]; then
    echo "[$BASE_IMAGE_LABEL] 🟢 [TINYPROXY] copying found tinyproxy /mnt/tinyproxy"
    cp -r /mnt/tinyproxy/* /etc/tinyproxy
  else
    echo "[$BASE_IMAGE_LABEL] ⚪ [TINYPROXY] no /mnt/tinyproxy provided"
  fi

  tinyproxy -d &
  echo "[$BASE_IMAGE_LABEL] 🟢 [TINYPROXY] started"
else
  echo "[$BASE_IMAGE_LABEL] ⚪ [TINYPROXY] disabled"
fi

# Execute main command
if [ -n "$CMD" ]; then
  echo "[$BASE_IMAGE_LABEL] 🟢 [CMD] executing [${CMD}]"
  exec ${CMD}
else
  echo "[$BASE_IMAGE_LABEL] ⚪ [CMD] none provided"
fi
