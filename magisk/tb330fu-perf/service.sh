#!/system/bin/sh
# Late phase (settings). Runs after boot_completed.
# On some devices the magiskd context cannot write Settings; fall back to
# `su -t 0 0` (uid 0 + global mount namespace), which can.
M=/data/adb/modules/tb330fu-perf
D=/data/adb/tb330fu-perf
exec >"$M/service.log" 2>&1

for i in $(seq 1 60); do
  [ "$(getprop sys.boot_completed)" = "1" ] && break
  sleep 2
done
sleep 3

# boot reached: clear the bootloop marker
rm -f "$D/boot_marker"

if ! sh "$M/perf-apply.sh" late; then
  echo "direct settings failed, retrying via su -t 0 0"
  su -t 0 0 -c "sh $M/perf-apply.sh late"
fi

sh "$M/keep-disabled.sh"
