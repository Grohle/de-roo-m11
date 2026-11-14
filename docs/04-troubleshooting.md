# 04 · Problems and fixes

Everything that went wrong along the way: exact symptom, cause and fix. Sorted by how likely you are to hit it.

---

## Windows and BROM

**Symptom**

```
Port - [LIB]: USB enumeration error: Operation not supported or unimplemented on this platform
Preloader - Status: Handshake failed, retrying...
```

**Cause**: on Windows the MTK port enumerates with the MediaTek serial driver (`wdm_usb`), and `pyusb`/`libusb` cannot open it. On top of that the BROM only waits **~2 s** without a handshake and powers off, so there is no realistic window to install a driver on the fly with Zadig.

**What NOT to do**: install **UsbDk**. On Windows 11 24H2 it has been reported to break the whole USB stack ([daynix/UsbDk#134](https://github.com/daynix/UsbDk/issues/134)).

**Fix**: do the BROM step on **Linux** (native) or in a Linux VM with USB passthrough. That is what I did and it works first time.

---

## SP Flash Tool: reads fine, refuses modified images

**Symptom**

```
send: download partition: lk_a
[result]: STATUS_SEC_IMG_HASH_VFY_FAIL
[error] download failed[index:0, name: lk_a]
```

**Cause**: Lenovo's signed DA verifies the hash/signature of "secure" partition images. No SPFT flag bypasses it.

**Useful details**

- In **preloader** mode (tablet off, plug without buttons) SPFT connects and **reads** perfectly.
- In **BROM** mode (`0e8d:0003`) it demands authentication and fails: `BROM said that Need AUTH file` / `key file is not exist` (`MT6768.key` is not shipped in the RSA bundle).
- The RSA bundle's `scatter`/XML files are **encrypted**, so you cannot craft your own flash config.

**Fix**: use `mtkclient`, whose DA is patched and skips signature checks. I only used SPFT to *read* (backup).

---

## Patching `lk` with a locked bootloader = black screen

**Symptom**: after writing `lk_patched.img` to `lk_a/lk_b` over BROM, the tablet **does not power on** (no recovery, no fastboot). It still enters BROM.

**Cause**: the device has *Secure Boot* enabled; the preloader verifies the `lk` signature and refuses to run it.

**Fix**

1. Recover over BROM by writing the original `lk` back:
   ```bash
   python3 mtk.py multi "w lk_a dump/lk_a.bin;w lk_b dump/lk_b.bin"
   ```
2. **Do not patch `lk`**: it is not needed once the bootloader is unlocked.

---

## `fastbootd` cannot flash

**Symptom**

```
Fetching super (offset=0, size=100000) FAILED (fetch:super:... 0 bytes available)
```

**Cause**: `fastbootd` (userspace fastboot) tries to read `super` for the snapshot before writing and fails on this device.

**Fix**: flash from the **primary bootloader** or over BROM. In my case `vendor_boot` flashed fine from normal fastboot.

---

## "Reinstall Magisk / recovery mode cannot get correct info"

**Symptom**: the Magisk app shows that dialog and "direct install" fails with `Unsupported/unknown image format`.

**Cause**: **version mismatch** between app and daemon (e.g. app 31.1, daemon 28.1). The app self-updates while the daemon stays behind. The "unsupported image format" comes from trying to patch a `boot` with **no ramdisk**.

**Fix**: patch `vendor_boot` with the binaries of **the same version** you will install as the app (31.1) and do not update the app separately. See [03](03-magisk.md).

---

## The bind-mount debloat module does not work

**Symptom**: the module installs, but apps are still there; the log says:

```
losetup: .../.empty-file: Permission denied
mount: losetup failed
```

**Cause**: toybox `mount` tries a *loop mount* instead of a bind mount, and `mknod` of the empty device is not viable in that context.

**Fix**: debloat with `pm uninstall --user 0` (per package) and `pm disable-user --user 0` for protected ones. See [05](05-post-install.md).

---

## `pm uninstall --user 0` returns an error but works

**Symptom**: the command exits non-zero and yet the package disappears.

**Fix**: do not trust the exit code; check with `pm list packages | grep <pkg>`. If it is gone, it was uninstalled.

---

## `monkey` is broken on this build

**Symptom**: `monkey -p <any-app> 1` answers `No activities found to run`, **even for working user apps**.

**Cause**: ZUI's `monkey` does not resolve third-party activities.

**Fix**: do not use it to test launches; use `am start -n package/.Activity`.

---

## "Activity class does not exist" while the user is locked

**Symptom**: `am start` says the class does not exist, and `dumpsys user` shows `State: RUNNING_LOCKED`.

**Cause**: with the user locked (CE unavailable) third-party apps cannot start. Additionally, `settings put` fails from boot contexts:

```
cmd: Failure calling service settings: Failed transaction (2147483646)
```

**Fix**: unlock the screen before testing. If you automate anything at boot, wait for `RUNNING_UNLOCKED`:

```bash
until dumpsys user | grep -q "State: RUNNING_UNLOCKED"; do sleep 5; done
```

---

## Integrating something into Settings (ZUI)

**Symptom**: an app with `com.android.settings.action.EXTRA_SETTINGS` registers (shows up in `cmd package query-activities`) but is **not displayed** in Settings.

**Cause**: ZUI only renders entries from privileged apps there (Google Settings, Lenovo Privacy).

**Fix**: use an app icon / Magisk *Action* button / launcher shortcut. Putting it inside Settings requires an Xposed (LSPosed) module.
