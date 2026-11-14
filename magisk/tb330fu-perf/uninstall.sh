#!/system/bin/sh
# Restore sane defaults when the module is removed.
settings put global activity_manager_constants "max_cached_processes=32" 2>/dev/null
settings put global window_animation_scale 1.0 2>/dev/null
settings put global transition_animation_scale 1.0 2>/dev/null
settings put global animator_duration_scale 1.0 2>/dev/null
setprop sys.lmk.minfree_levels "18432:0,23040:100,27648:200,32256:250,55296:900,80640:950" 2>/dev/null
setprop lmkd.reinit 1 2>/dev/null
rm -rf /data/adb/tb330fu-perf
