# 03 · Magisk in `vendor_boot`

## Why `vendor_boot` and not `boot`

On Android 15 (GKI) the generic ramdisk moved from `boot` to `vendor_boot`. On this model:

```
boot_a:         kernel 14538864 bytes, ramdisk 0        -> nothing to patch
vendor_boot_a:  3 fragments -> ramdisk (platform), recovery, init_boot
```

If you patch `boot` (what the app does when you tap "Install"), Magisk invents a ramdisk and you can end up in a bootloop. **The correct target is `vendor_boot`.**

> `init_boot_a/b` exist in the GPT but are **all zeroes** (8 MB empty): the bootloader does not use them on this device.

## Requirement: Magisk **31.1** (not 28.x)

Magisk **31.1** is the first version that **officially supports patching `vendor_boot`**: `magiskboot unpack` returns `3`, the script sets `VENDORBOOT=true` and picks `vendor_ramdisk/init_boot.cpio`.

With 28.1 you have to do it by hand (and the app keeps showing a "reinstall Magisk" warning because app and daemon versions differ).

Download the official APK: <https://github.com/topjohnwu/Magisk/releases>

## Patching (on device, via adb)

[`scripts/patch-vendor-boot.sh`](../scripts/patch-vendor-boot.sh) does everything:

```bash
adb push vendor_boot.img /data/local/tmp/magisk31/
adb push scripts/patch-vendor-boot.sh /data/local/tmp/
adb shell su -c "sh /data/local/tmp/patch-vendor-boot.sh"
adb pull /data/local/tmp/magisk31/new-boot.img vendor_boot_magisk.img
```

What it does internally:

1. Extracts from the Magisk 31.1 APK: `boot_patch.sh`, `util_functions.sh` and the `arm64-v8a` libs renamed to
   `libmagiskboot.so → magiskboot`, `libmagiskinit.so → magiskinit`, `libmagisk.so → magisk`,
   `libinit-ld.so → init-ld`, `libbusybox.so → busybox`.
2. Runs `KEEPVERITY=true sh boot_patch.sh vendor_boot.img`.
3. Produces `new-boot.img`.

Expected output:

```
- Vendor boot image detected
- Stock boot image detected
- Patching ramdisk
Repack to boot image: [new-boot.img]
```

## Flashing

```bash
fastboot flash vendor_boot_a vendor_boot_magisk.img
fastboot flash vendor_boot_b vendor_boot_magisk.img
fastboot reboot
```

`lk` is **not** touched (not needed once the bootloader is unlocked).

## Install the app

Install the **same** 31.1 APK you used for patching:

```bash
adb install -r Magisk-v31.1.apk
```

Open Magisk: it should show `Magisk 31.1 (31100)`, **Ramdisk: Yes**, Zygisk as you enable it, and **no warning** to reinstall.

> If the app version differs from the daemon (e.g. app 31.1 with daemon 28.1) you will see *"Your device needs to reinstall Magisk... recovery mode cannot get correct info"*. That is a version mismatch, not a root problem.

## Verify root

```bash
adb shell su -c id
# uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0
```

The first time, Magisk asks for authorization for `shell` on screen. You can also pre-authorize by uid:

```bash
adb shell su -c 'magisk --sqlite "INSERT OR REPLACE INTO policies (uid,policy,until,logging,notification) VALUES (2000,2,0,1,1)"'
```

(`policy=2` is *allow*; `2000` is the `shell` uid.)

## Reverting to stock

```bash
fastboot flash vendor_boot_a vendor_boot.img   # from the original firmware
fastboot flash vendor_boot_b vendor_boot.img
fastboot reboot
```
