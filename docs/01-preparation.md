# 01 · Preparation and backup

## Tools

### Linux (recommended)

`mtkclient` needs no special drivers on Linux. This is the path I used for unlocking.

```bash
sudo apt install python3 python3-pip git libusb-1.0-0
git clone --depth 1 https://github.com/bkerler/mtkclient
cd mtkclient
pip3 install -r requirements.txt
sudo cp Setup/Linux/52-mtk.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```

### Windows (fastboot/adb only)

Flashing over fastboot needs nothing special: `adb`/`fastboot` from platform-tools.

**BROM/mtkclient on Windows is a real problem**: the BROM only waits ~2 s without a handshake, and without a libusb driver there is no handshake. See [04 · Troubleshooting](04-troubleshooting.md#windows-and-brom). Recommendation: use Linux (or a Linux VM with USB passthrough) for the BROM step.

## Exact firmware

You need images from **your exact build**. The reliable way on this model:

1. Install **Lenovo Rescue & Smart Assistant (RSA)** / *Software Fix*.
2. Connect the tablet and let it download the firmware.
3. It ends up in:

```
C:\ProgramData\RSA\Download\RomFiles\<BUILD>\<BUILD>\image\
```

Useful files:

| File | Why |
|---|---|
| `vendor_boot.img` | **the one to patch** (A15) |
| `boot.img` | reference (do not touch) |
| `lk.img` | restore to stock if something goes wrong |
| `vbmeta.img` | reference |
| `MT6768_Android_scatter.txt` | reference (encrypted in the RSA bundle) |

> Verify that the firmware `boot.img` hash matches your device before doing anything. If it does not match, it is **not your build**.

## BROM backup (strongly recommended)

With the tablet **powered off**, hold **Vol+ and Vol−** and plug the USB cable: it enters **BROM** (`lsusb` shows `0e8d:0003`). On Linux:

```bash
cd mtkclient
python3 mtk.py multi "\
r seccfg dump/seccfg.bin;\
r proinfo dump/proinfo.bin;\
r nvdata dump/nvdata.bin;\
r nvram dump/nvram.bin;\
r persist dump/persist.bin;\
r lk_a dump/lk_a.bin;\
r lk_b dump/lk_b.bin;\
r vbmeta_a dump/vbmeta_a.bin;\
r vbmeta_b dump/vbmeta_b.bin;\
r boot_a dump/boot_a.bin;\
r boot_b dump/boot_b.bin;\
r vendor_boot_a dump/vendor_boot_a.bin;\
r vendor_boot_b dump/vendor_boot_b.bin"
```

> **Careful with `multi`**: commands are separated by `;` **without spaces**, otherwise `mtkclient` receives an empty command and aborts.

Treat `seccfg`, `proinfo`, `nvdata`, `nvram` and `persist` as gold: they are specific to your unit.

Script: [`scripts/dump-backup.sh`](../scripts/dump-backup.sh).

## Pre-flight checks

```bash
adb shell getprop ro.build.display.id     # must match the firmware
adb shell getprop ro.boot.slot_suffix     # _b on my unit
fastboot getvar unlocked                  # no
fastboot flashing get_unlock_ability      # 16777216 on this bootloader
```
