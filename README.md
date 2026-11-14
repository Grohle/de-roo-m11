# Rooting the Lenovo Tab M11 (TB330FU) — a reproducible guide

Step-by-step write-up of how I rooted my **Lenovo Tab M11 (TB330FU)**: what worked, what **did not** work, and why. Everything here was tested on the device below. The dead ends are documented so you don't waste hours on them.

> **Warning**: unlocking the bootloader and flashing partitions can brick your device and **wipes all data**. Back up first. Use at your own risk.

---

## Starting device

| Item | Value |
|---|---|
| Model | Lenovo Tab M11 **TB330FU** (EEA variant) |
| SoC | MediaTek **MT8786 / MT6768** (Helio G88), 8 cores |
| Android | **15** (ZUI 17) |
| Build | `TB330FU_ROW_OPEN_USER_V5_V_ZUI_17.0.502_ST_261010` |
| Active slot | `_b` (A/B) |
| Bootloader | locked from factory (`ro.boot.flash.locked=1`) |
| Root | none |

Check yours:

```bash
adb shell getprop ro.product.device        # TB330FU
adb shell getprop ro.build.display.id      # exact build
adb shell getprop ro.boot.slot_suffix      # _a or _b
```

**The build matters**: the images you patch must come from the **same version** installed on the device.

---

## The 6 steps

1. **Get the exact firmware** (Lenovo Rescue & Smart Assistant / Software Fix).
2. **Back up** critical partitions over BROM with `mtkclient`.
3. **Unlock the bootloader** with `mtkclient` (`fastboot flashing unlock` does not exist on this bootloader).
4. **Patch `vendor_boot.img`** with Magisk **31.1** (on Android 15 the generic ramdisk lives there, not in `boot`).
5. **Flash** the patched `vendor_boot` to `_a` and `_b` with fastboot.
6. **Install the Magisk 31.1 app** (same version as the daemon) and verify `su`.

Full details in [`docs/`](docs/):

- [01 · Preparation and backup](docs/01-preparation.md)
- [02 · Bootloader unlock](docs/02-unlock.md)
- [03 · Magisk in vendor_boot](docs/03-magisk.md)
- [04 · Problems and fixes](docs/04-troubleshooting.md)
- [05 · Post-install (Zygisk, debloat, stylus)](docs/05-post-install.md)

Helper scripts in [`scripts/`](scripts/).

---

## TL;DR

```bash
# 3) unlock (tablet in BROM)
python3 mtkclient/mtk.py da seccfg unlock

# 4) patch vendor_boot with Magisk 31.1 (on device, via adb)
#    see scripts/patch-vendor-boot.sh
KEEPVERITY=true sh boot_patch.sh vendor_boot.img     # -> new-boot.img

# 5) flash
fastboot flash vendor_boot_a new-boot.img
fastboot flash vendor_boot_b new-boot.img
fastboot reboot

# 6) verify
adb shell su -c id      # uid=0(root) ... context=u:r:magisk:s0
```

---

## What you do NOT need (and why)

- **Patching `lk`** (`lkpatcher`): with a **locked** bootloader the preloader rejects the signature and the tablet **will not power on** (black screen, recoverable via BROM). Once unlocked, it is **not needed**.
- **Touching `boot`**: on Android 15 the kernel is GKI and `boot` has **no ramdisk** (`ramdisk_size = 0`). Patching it does not give root and may create a second `magiskinit`.
- **TWRP**: the existing TB330FU device tree targets **Android 14**; on A15 it bootloops. Not required for root.
- **SP Flash Tool** to write modified images: its signed DA rejects them (`STATUS_SEC_IMG_HASH_VFY_FAIL`).

---

## Credits / references

- [`bkerler/mtkclient`](https://github.com/bkerler/mtkclient) — BROM, read/write and `seccfg unlock`.
- [`topjohnwu/Magisk`](https://github.com/topjohnwu/Magisk) — Magisk 31.1 (supports patching `vendor_boot`).
- [`threadexio/tb330fu`](https://github.com/threadexio/tb330fu) — original reference guide for this model.
- XDA thread on rooting TB330FU on Android 15 (Magisk + vendor_boot).

## License

MIT. Use at your own risk.
