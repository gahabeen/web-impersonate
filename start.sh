#!/bin/bash
if [ "$START_XVBF" = true ]; then
  # Start X virtual framebuffer
  echo "Xvfb started on $DISPLAY ($XVFB_WHD)."
  Xvfb $DISPLAY -ac -screen 0 $XVFB_WHD -nolisten tcp &

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

  if [ -d "/mnt/nginx" ]; then
    echo "Copying found nginx folder..."
    cp -rv /mnt/nginx/* /usr/local/openresty/nginx
  fi

  openresty -g 'daemon off;' &
  echo "NGINX server started."
else
  echo "NGINX server disabled."
fi

if [ "$START_HAPROXY" = true ]; then
  echo "Starting HAProxy server..."
  mkdir -p /var/log/openresty

  if [ -d "/mnt/haproxy" ]; then
    echo "Copying found haproxy folder..."
    cp -rv /mnt/haproxy/* /usr/local/etc/haproxy
  fi

  if [ -d "/usr/local/etc/haproxy/haproxy.cfg" ]; then
    echo "Applying ENV variables to haproxy.cfg..."
    cp /usr/local/etc/haproxy/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg.bak
    envsubst </usr/local/etc/haproxy/haproxy.cfg >/usr/local/etc/haproxy/haproxy.cfg
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
