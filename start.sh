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
  x11vnc -display $DISPLAY -quiet -noxrecord -noxfixes -noxdamage -forever -passwd $VNC_PASSWORD -rfbport $VNC_PORT &
  echo "VNC server started on $DISPLAY (PORT: $VNC_PORT)."

  # Ensure VNC server has started before proceeding
  sleep 2
else
  echo "VNC server disabled."
fi

if [ "$START_NGINX" = true ]; then
  echo "Starting NGINX server..."
  if [ -d "/mnt/nginx" ]; then
    echo "Copying found nginx folder..."
    cp -rv /mnt/nginx/* /usr/local/openresty/nginx
  fi # Close the inner if statement

  openresty -g 'daemon off;' &
else
  echo "NGINX server disabled."
fi

if [ "$START_LAVINMQ" = true ]; then
  echo "Starting LavinMQ server..."
  lavinmq &
else
  echo "LavinMQ server disabled."
fi

# Execute main command
echo "Executing main command ${CMD}"
exec ${CMD}
