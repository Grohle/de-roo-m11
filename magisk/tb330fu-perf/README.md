# tb330fu-perf — Magisk module

Memory / IO / VM + MediaTek boost profiles for the **Lenovo Tab M11 (TB330FU)**.
No governor changes: the stock `sugov_ext` (EAS) is left alone on purpose.

## Install

```bash
adb push tb330fu-perf.zip /data/local/tmp/
adb shell su -c "magisk --install-module /data/local/tmp/tb330fu-perf.zip"
adb reboot
```

Or zip this folder (files at the ZIP root) and flash it from the Magisk app.

Default profile: **fluid**.

## Profiles

| Profile | `sys.lmk.minfree_levels` | `max_cached_processes` | `ro.lmk.thrashing_limit` |
|---|---|---|---|
| balanced | stock (`18432…80640`) | 32 | 30 |
| **fluid** (default) | `24576…98304` | 28 | 25 |
| aggressive | `32768…131072` | 20 | 15 |

**Switch from the app**: Magisk → Modules → *TB330FU Performance Profiles* → **ACTION** button.
It cycles `balanced → fluid → aggressive`.

Or by hand:

```bash
su -c 'echo aggressive > /data/adb/tb330fu-perf/profile'
su -c 'sh /data/adb/modules/tb330fu-perf/perf-apply.sh late'
```

## What it changes

**Early (post-fs-data, always applies):**

- `ro.lmk.thrashing_limit`, `psi_complete_stall_ms=70`, `swap_free_low_percentage=20`, `kill_heaviest_task`
- `read_ahead_kb = 256` (faster cold starts)
- `min_free_kbytes = 16384`, `dirty_ratio = 10`, `dirty_background_ratio = 5`
- `page-cluster = 0` (zram page-by-page, lower latency)
- MediaTek **SYS_BOOST** (`echo "9 1" > /proc/ppm/policy_status`)

**Late (after boot, `settings`):**

- `sys.lmk.minfree_levels` + `lmkd.reinit`
- `activity_manager_constants max_cached_processes`
- `cached_apps_freezer = enabled`
- animation scales `0.5`

**Every boot:** re-disables Lenovo/ZUI packages that restore themselves
(`keep-disabled.sh`). **`com.lenovo.penservice` (stylus) is never touched.**

## Notes

- `settings put` does not work from the magiskd context on this device
  (`Failed transaction`). The scripts retry with `su -t 0 0 -c ...`
  (uid 0 + global mount namespace), which does work.
- Bootloop guard: 3 consecutive failed boots revert the profile to `fluid`.
- `uninstall.sh` restores animation scales, `max_cached_processes=32` and stock LMK levels.
- Do **not** set a governor here. `performance` locks max clocks and makes sustained
  performance worse (thermal throttling) on this SoC.
