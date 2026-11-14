# 02 · Bootloader unlock

## What does NOT work on this bootloader

```
fastboot flashing unlock
FAILED (remote: 'unknow command')
```

Lenovo removed the fastboot unlock commands on this model. `fastboot oem device-info` does not exist either.

**Unlocking is done with `mtkclient` over BROM**, which writes `seccfg` directly.

## Entering BROM

1. Unplug the cable.
2. Power the tablet off (hold Power ~15 s).
3. Hold **Vol+ and Vol−**.
4. Plug the USB cable **into the PC** (Linux).
5. Release after ~3 s.

Check:

```bash
lsusb | grep 0e8d        # 0e8d:0003  MediaTek ... (BROM)
```

If you see `0e8d:2000` that is **preloader** (lives ~2 s) and is not usable here: repeat the combo.

## Unlock

```bash
cd mtkclient
python3 mtk.py da seccfg unlock
```

Expected output (abridged):

```
SecCfgV4 - hwtype found: V4
DaHandler - Successfully wrote seccfg.
```

Then:

```bash
python3 mtk.py reset      # powers the tablet off
```

Power it on. You will see the **orange state** warning (bootloader unlocked) and **all data will be wiped**.

Verify:

```bash
adb shell getprop ro.boot.flash.locked    # 0
fastboot getvar unlocked                  # yes
```

## If the command fails

- `BROM said that Need AUTH file` → you are connecting in **preloader**, not BROM. Repeat the combo.
- `Handshake failed` → the device powered off too early. Keep the buttons held while plugging in.
- If the first attempt right after a cold boot fails, **re-run the command without unplugging**: in my case the second attempt connected fine.
