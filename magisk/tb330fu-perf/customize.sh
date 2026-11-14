#!/system/bin/sh
# Magisk runs this at install time: restore exec bits and default config.
chmod 755 "$MODPATH"/*.sh

D=/data/adb/tb330fu-perf
mkdir -p "$D"
[ -f "$D/profile" ] || echo fluid > "$D/profile"
