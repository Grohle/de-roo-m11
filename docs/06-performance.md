# 06 · Real-world performance work (what actually helped)

Measured on the device described in the README: **3.8 GB RAM**, 2.86 GB zram (lz4),
284 system packages, ~1400 tasks at idle, memory PSI `some avg10` between 5 and 10.

Everything below is included in the [`magisk/tb330fu-perf`](../magisk/tb330fu-perf) module,
which is the only thing you need to reproduce it.

---

## 1. Debloat (the biggest single win)

- **67 packages** removed for user 0 (`pm uninstall --user 0`).
- **15 services** disabled (`pm disable-user`) because they restore themselves.
- Result: system packages 284 → ~207, tasks ~1400 → ~1165, and far less background churn.

See [05 · Post-install](05-post-install.md) for the list. **Never remove `com.lenovo.penservice`**
(stylus) or the launcher/camera/GMS/Play Store/keyboard.

## 2. LMK tuning (protect the app in focus)

`lmkd` on Android 15 is PSI-based, but `sys.lmk.minfree_levels` is still honoured after
`setprop lmkd.reinit 1`:

| Profile | minfree levels |
|---|---|
| balanced | `18432:0,23040:100,27648:200,32256:250,55296:900,80640:950` (stock) |
| **fluid** | `24576:0,30720:100,36864:200,43008:250,73728:900,98304:950` |
| aggressive | `32768:0,40960:100,49152:200,57344:250,98304:900,131072:950` |

Plus `ro.lmk.thrashing_limit` (30/25/15), `psi_complete_stall_ms=70`,
`swap_free_low_percentage=20` and `kill_heaviest_task=true`.

Effect: background processes are reclaimed earlier, so the foreground app keeps its pages.

## 3. Fewer cached processes + freezer

```bash
settings put global activity_manager_constants "max_cached_processes=28"   # 32/28/20
settings put global cached_apps_freezer enabled
```

Less RAM parked in cached apps, and what remains is frozen (no CPU wakeups).

## 4. IO and VM

```bash
echo 256 > /sys/block/mmcblk0/queue/read_ahead_kb      # 128 -> 256, faster cold starts
echo 16384 > /proc/sys/vm/min_free_kbytes              # 8192 -> 16384
echo 10 > /proc/sys/vm/dirty_ratio                     # 20 -> 10
echo 5  > /proc/sys/vm/dirty_background_ratio          # 10 -> 5
echo 0  > /proc/sys/vm/page-cluster                    # swap page by page (lower latency)
```

## 5. MediaTek SYS_BOOST

```bash
echo "9 1" > /proc/ppm/policy_status     # PPM_POLICY_SYS_BOOST: enabled
```

Vendor boost that ramps CPU on input / app launch. It is **not** a governor change and it is
what makes the UI feel snappier without frying the SoC.

## 6. Animations

`window/transition/animator` scales at `0.5`.

---

## Things that did NOT help

### Removing zram (swap)

Tempting, but measured on this device:

| | With zram | After `swapoff` |
|---|---|---|
| `MemAvailable` | **1,118 MB** | **604 MB** |
| PSI `some avg10` | 0.00 | 0.37 |

`swapoff` forces the kernel to decompress ~768 MB back into physical RAM: available memory
**halves**. More LMK kills, more cold app reloads → **more stutter**. Also note
`/sys/block/zram0/backing_dev = none`: this zram never touches storage, so there is no disk
I/O to blame.

Keep zram. If you want to test it, do it live and reversible:

```bash
su -c 'swapoff /dev/block/zram0'   # test
su -c 'swapon  /dev/block/zram0'   # restore
```

### Changing the CPU governor

The stock governor is `sugov_ext` (MediaTek EAS). Available: `conservative`, `powersave`,
`performance`, `schedutil`.

- `performance` pins 2.0/1.8 GHz → 70 °C, thermal throttling, **worse sustained** performance.
- `powersave` pins minimum clocks → constant jank.
- `conservative` is a legacy DVFS governor, reacts late under EAS.
- plain `schedutil` loses MediaTek's PPM hints.

On an EAS SoC the governor is not the lever: ramp speed (`SYS_BOOST`), free RAM (debloat + LMK)
and thermals are.

### `init_boot`

`init_boot_a/b` are 8 MB of zeroes on this device; the bootloader does not use them.
Root has to live in `vendor_boot` (see [03](03-magisk.md)).

---

## Result

| Metric | Before | After |
|---|---|---|
| System packages | 284 | ~207 |
| Tasks / processes | ~1400 | ~1165 |
| Memory PSI `some avg10` (idle) | 5–10 | ~0.4–4 |
| Animations | 1.0 | 0.5 |
| CPU ramp | stock | SYS_BOOST enabled |
| Foreground protection | stock LMK | `fluid` LMK + fewer cached procs |

All of it is reversible: disable the module in Magisk, or run its `uninstall.sh`.
