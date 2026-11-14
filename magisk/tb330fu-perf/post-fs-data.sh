#!/system/bin/sh
# Early phase + bootloop guard.
M=/data/adb/modules/tb330fu-perf
D=/data/adb/tb330fu-perf
MARK="$D/boot_marker"
CNT="$D/boot_count"
exec >"$M/post-fs-data.log" 2>&1
mkdir -p "$D"

# --- bootloop guard: 3 failed boots in a row -> back to fluid + stock-ish ---
if [ -f "$MARK" ]; then
  n=$(cat "$CNT" 2>/dev/null || echo 0)
  n=$((n+1))
  echo "$n" > "$CNT"
  if [ "$n" -ge 3 ]; then
    echo fluid > "$D/profile"
    rm -f "$CNT" "$MARK"
    echo "guard: reverted to fluid after $n failed boots"
    sh "$M/perf-apply.sh" early
    exit 0
  fi
else
  echo 0 > "$CNT"
fi
echo "$(date +%s)" > "$MARK"

sh "$M/perf-apply.sh" early
