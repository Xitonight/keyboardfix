#!/bin/bash

set -e

DEVICE_NUMBER="$1"

for dev in /sys/bus/usb/devices/*; do
  if [[ ! "$dev" =~ ":" ]]; then
    if grep -q "$DEVICE_NUMBER" "$dev"/devnum; then
      DEVICE_PATH=$dev
    else
      "Error: There's no device with number $DEVICE_NUMBER"
      exit 1
    fi
  fi
done

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

# Now you can use the $service_content variable
echo "$SERVICE_CONTENT" | sudo tee /etc/systemd/system/reset-usb.service

sudo systemctl daemon-reload
sudo systemctl enable reset-usb.service

echo "Successfully installed USB reset service for device $DEVICE_NAME"
echo "Service will activate on next suspend/resume cycle"
