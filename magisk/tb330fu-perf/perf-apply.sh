#!/system/bin/sh
# Apply the current profile.
#   perf-apply.sh early   -> props / sysfs (works from post-fs-data)
#   perf-apply.sh late    -> settings (needs uid 0 + global mount namespace)
M=/data/adb/modules/tb330fu-perf
D=/data/adb/tb330fu-perf
mkdir -p "$D"

PROFILE=$(cat "$D/profile" 2>/dev/null | tr -d ' \r\n')
[ -z "$PROFILE" ] && PROFILE=fluid

case "$PROFILE" in
  balanced)
    LMK="18432:0,23040:100,27648:200,32256:250,55296:900,80640:950"
    THRASH=30
    MAXCACHED=32
    ;;
  aggressive)
    LMK="32768:0,40960:100,49152:200,57344:250,98304:900,131072:950"
    THRASH=15
    MAXCACHED=20
    ;;
  *)
    PROFILE=fluid
    LMK="24576:0,30720:100,36864:200,43008:250,73728:900,98304:950"
    THRASH=25
    MAXCACHED=28
    ;;
esac

phase="$1"

if [ "$phase" = "early" ]; then
  # lmkd tuning (PSI-based on Android 15)
  resetprop -n ro.lmk.thrashing_limit "$THRASH" 2>/dev/null
  resetprop -n ro.lmk.psi_complete_stall_ms 70 2>/dev/null
  resetprop -n ro.lmk.swap_free_low_percentage 20 2>/dev/null
  resetprop -n ro.lmk.kill_heaviest_task true 2>/dev/null

  # IO: faster sequential reads (app cold starts)
  [ -w /sys/block/mmcblk0/queue/read_ahead_kb ] && echo 256 > /sys/block/mmcblk0/queue/read_ahead_kb

  # VM: fewer writeback stalls and less fragmentation
  [ -w /proc/sys/vm/min_free_kbytes ] && echo 16384 > /proc/sys/vm/min_free_kbytes
  [ -w /proc/sys/vm/dirty_ratio ] && echo 10 > /proc/sys/vm/dirty_ratio
  [ -w /proc/sys/vm/dirty_background_ratio ] && echo 5 > /proc/sys/vm/dirty_background_ratio

  # zram: swap page by page (lower latency when returning to an app)
  [ -w /proc/sys/vm/page-cluster ] && echo 0 > /proc/sys/vm/page-cluster

  # MediaTek system boost: faster frequency ramp on input / app launch
  [ -w /proc/ppm/policy_status ] && echo "9 1" > /proc/ppm/policy_status
fi

if [ "$phase" = "late" ]; then
  # LMK levels + reload
  setprop sys.lmk.minfree_levels "$LMK"
  setprop lmkd.reinit 1

  # Fewer cached processes -> more RAM for the app in focus
  n=0
  while [ $n -lt 15 ]; do
    ok=1
    settings put global activity_manager_constants "max_cached_processes=$MAXCACHED" 2>/dev/null || ok=0
    settings put global cached_apps_freezer enabled 2>/dev/null || ok=0
    settings put global window_animation_scale 0.5 2>/dev/null || ok=0
    settings put global transition_animation_scale 0.5 2>/dev/null || ok=0
    settings put global animator_duration_scale 0.5 2>/dev/null || ok=0
    [ $ok -eq 1 ] && break
    n=$((n+1)); sleep 2
  done
fi

echo "profile=$PROFILE phase=$phase lmk=$LMK max_cached=$MAXCACHED thrash=$THRASH attempts=$n"

# late phase reports failure so callers can retry with a different context
if [ "$phase" = "late" ] && [ "${n:-0}" -ge 15 ]; then
  exit 1
fi
exit 0
