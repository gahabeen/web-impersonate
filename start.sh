#!/bin/bash
if [ -d "/mnt/env" ]; then
  echo "Copying found ENV folder..."
  cp -rv /mnt/env /usr/local/etc/env
fi

if [ -d "/usr/local/etc/env" ]; then
  if [ -f "/usr/local/etc/env/.default.env" ]; then
    set -a && . "/usr/local/etc/env/.default.env" && set +a
  fi

  for envfile in /usr/local/etc/env/.env*; do
    set -a && . "$envfile" && set +a
    rm -f "$envfile"
  done
fi

if [ "$START_XVBF" = true ]; then
  # Start X virtual framebuffer
  echo "Xvfb started on $DISPLAY (${SCREEN_RESOLUTION}x${SCREEN_DEPTH})."
  Xvfb $DISPLAY -ac -screen 0 ${SCREEN_RESOLUTION}x${SCREEN_DEPTH} -nolisten tcp &

  # Start Fluxbox window manager
  fluxbox >/dev/null 2>&1 &

  # Ensure that Xvfb and Fluxbox have started before proceeding
  sleep 2
else
  echo "Xvfb server disabled."
fi

if [ "$START_VNC" = true ]; then
  # Start VNC server
  x11vnc -display $DISPLAY -quiet -noxrecord -nodpms -noxfixes -noxdamage -forever -passwd $VNC_PASSWORD -rfbport $VNC_PORT &
  echo "VNC server started (on $DISPLAY, PORT: $VNC_PORT)."

  # Ensure VNC server has started before proce´eding
  sleep 2
else
  echo "VNC server disabled."
fi

if [ "$START_NGINX" = true ]; then
  echo "Starting NGINX server..."
  mkdir -p /var/log/openresty

  openresty -g 'daemon off;' &
  echo "NGINX server started."
else
  echo "NGINX server disabled."
fi

if [ "$START_RSYSLOG" = true ]; then
  echo "Starting rsyslog server..."
  # rm -rf /etc/rsyslog.d/*-haproxy.conf # Remove old config

  if [ -d "/mnt/rsyslog" ]; then
    echo "Copying found HAProxy folder..."
    cp -rv /mnt/rsyslog/* /etc/rsyslog.d
  fi

  rsyslogd -n &
  echo "rsyslog server started."
else
  echo "rsyslog server disabled."
fi

if [ "$START_HAPROXY" = true ]; then
  echo "Starting HAProxy server..."
  mkdir -p /usr/local/etc/haproxy

  if [ -d "/mnt/haproxy" ]; then
    echo "Copying found HAProxy folder..."
    cp -rv /mnt/haproxy/* /usr/local/etc/haproxy
  fi

  if [ -f "/usr/local/etc/haproxy/haproxy.cfg" ]; then
    echo "Applying ENV variables to haproxy.cfg..."
    cp /usr/local/etc/haproxy/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg.bak
    envsubst </usr/local/etc/haproxy/haproxy.cfg.bak >/usr/local/etc/haproxy/haproxy.cfg
  fi

  haproxy -f /usr/local/etc/haproxy/haproxy.cfg &
  echo "HAProxy server started."
else
  echo "HAProxy server disabled."
fi

if [ "$START_LAVINMQ" = true ]; then
  lavinmq &
  echo "LavinMQ started."
else
  echo "LavinMQ server disabled."
fi

# Execute main command
echo "Executing main command ${CMD}"
exec ${CMD}
