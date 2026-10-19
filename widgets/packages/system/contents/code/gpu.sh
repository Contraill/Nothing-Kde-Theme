#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# One line per GPU: PCI vendor, boot_vga (1 = integrated/primary), runtime PM
# state, usage % and temperature °C (-1 when not read). sysfs never wakes a
# sleeping card, so a suspended discrete GPU is only reported as asleep; an
# awake one is asked once, and nothing stays open that would keep it awake.
for card in /sys/class/drm/card[0-9]*; do
  case "${card##*/}" in *-*) continue ;; esac
  dev="$card/device"
  [ -r "$dev/vendor" ] || continue
  vendor=$(cat "$dev/vendor")
  boot=$(cat "$dev/boot_vga" 2>/dev/null || echo 0)
  state=$(cat "$dev/power/runtime_status" 2>/dev/null || echo unsupported)
  usage=-1
  temp=-1
  if [ "$boot" = 0 ] && [ "$state" != suspended ] && [ "$state" != suspending ]; then
    case "$vendor" in
      0x10de)
        line=$(nvidia-smi --id="$(basename "$(readlink -f "$dev")")" --query-gpu=utilization.gpu,temperature.gpu \
          --format=csv,noheader,nounits 2>/dev/null) && { usage=${line%%,*}; temp=${line##* }; } ;;
      0x1002)
        usage=$(cat "$dev/gpu_busy_percent" 2>/dev/null || echo -1)
        for t in "$dev"/hwmon/hwmon*/temp1_input; do [ -r "$t" ] && temp=$(( $(cat "$t") / 1000 )); break; done ;;
    esac
  fi
  echo "$vendor $boot $state $usage $temp"
done
