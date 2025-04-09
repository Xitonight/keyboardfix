#!/bin/bash

set -e

if [ -z "$1" ]; then
  lsusb | sed -E 's/Bus [0-9]+ |ID [a-f0-9:]+ //g'

  read -r -p "Enter the number of the device you want to fix: " DEVICE_NUMBER
fi

DEVICE_NUMBER=$((10#$DEVICE_NUMBER))

if [[ ! $DEVICE_NUMBER =~ ^[0-9]+$ ]]; then
  echo "Error: Please enter a valid number"
  exit 1
fi

for dev in /sys/bus/usb/devices/*; do
  if [[ ! "$dev" =~ ":" ]]; then
    if grep -q "$DEVICE_NUMBER" "$dev"/devnum; then
      DEVICE_PATH=$dev
    fi
  fi
done

if [ -z "$DEVICE_PATH" ]; then
  echo "Error: There's no device with number $DEVICE_NUMBER"
  exit 1
fi

DEVICE_NAME="$(cat "$DEVICE_PATH"/product)"

SERVICE_CONTENT=$(
  cat <<EOF
[Unit]
Description=Reset USB on resume
After=suspend.target

[Service]
ExecStart=/usr/bin/bash -c "echo 0 > $DEVICE_PATH/authorized ; echo 1 > $DEVICE_PATH/authorized"
Type=oneshot

[Install]
WantedBy=suspend.target
EOF
)

echo "$SERVICE_CONTENT" | sudo tee /etc/systemd/system/reset-usb.service >/dev/null

sudo systemctl daemon-reload
sudo systemctl enable reset-usb.service

echo "Successfully installed USB reset service for device $DEVICE_NAME"
echo "Service will activate on next suspend/resume cycle"
