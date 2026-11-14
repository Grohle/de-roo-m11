#!/bin/bash
# Flash the patched vendor_boot to both slots and reboot.
# Usage: ./flash-vendor-boot.sh vendor_boot_magisk.img
set -e
IMG="${1:-vendor_boot_magisk.img}"

[ -f "$IMG" ] || { echo "No such file: $IMG"; exit 1; }

fastboot devices
fastboot flash vendor_boot_a "$IMG"
fastboot flash vendor_boot_b "$IMG"
fastboot reboot
